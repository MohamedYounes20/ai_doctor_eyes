import '../../models/health_condition.dart';
import '../../models/analysis_models.dart';
import '../../models/medical_profile.dart';
import '../../core/constants/ingredient_constants.dart';

class LocalAnalysisResult {
  final IngredientStatus status;
  final List<IngredientAnalysis> details;

  LocalAnalysisResult(this.status, this.details);
}

/// Pure, synchronous health analyser.
///
/// Implements **dual-tier** ingredient matching:
///
/// **Tier 1 — Critical Medical Alert** (red)
///   Matches against [MedicalProfile.forbiddenKeywords] extracted from the
///   user's own lab report via Gemini Vision.
///   → Returns [IngredientStatus.danger] with a "Critical:" prefix reason.
///
/// **Tier 2 — Standard Warning** (standard danger colour)
///   Matches against the built-in [harmfulKeywords] dictionary keyed by the
///   user's selected [HealthCondition]s.
///   → Returns [IngredientStatus.danger] with the normal local-database reason.
///
/// All matching is case-insensitive and fully offline.
class HealthAnalyzer {
  /// Analyse [canonicalNames] against both tiers.
  ///
  /// [conditions] — user's selected [HealthCondition]s (Tier 2 source).
  /// [medicalProfile] — optional; when non-null, Tier 1 matching is applied
  ///   first. Fetched by [IngredientCheckerService] before this call so the
  ///   analyser remains synchronous (Option A architecture).
  LocalAnalysisResult analyzeLocal(
    List<String> canonicalNames,
    List<HealthCondition> conditions, {
    MedicalProfile? medicalProfile,
  }) {
    final details = <IngredientAnalysis>[];
    bool hasDanger = false;

    // ── Pre-build Tier 1 keyword set (lowercase) ─────────────────────────────
    final criticalKeywords = <String>[];
    if (medicalProfile != null && medicalProfile.forbiddenKeywords.isNotEmpty) {
      criticalKeywords.addAll(
        medicalProfile.forbiddenKeywords.map((k) => k.toLowerCase()),
      );
    }

    // ── Pre-build Tier 2 keyword map ─────────────────────────────────────────
    final standardKeywords =
        <String, ({HealthCondition cond, String original})>{};
    for (final c in conditions) {
      for (final kw in (harmfulKeywords[c] ?? [])) {
        standardKeywords[kw.toLowerCase()] = (cond: c, original: kw);
      }
    }

    // ── Evaluate each ingredient ──────────────────────────────────────────────
    for (final name in canonicalNames) {
      final lowerName = name.toLowerCase();
      bool matched = false;

      // Tier 1 — Critical (user's personal lab report keywords)
      if (criticalKeywords.isNotEmpty) {
        for (final kw in criticalKeywords) {
          if (lowerName.contains(kw)) {
            details.add(IngredientAnalysis(
              ingredientName: name,
              status: IngredientStatus.danger,
              reason:
                  'Critical: Dangerous for your condition '
                  '(${medicalProfile!.condition}). '
                  'Flagged by your personal medical record.',
              severity: medicalProfile.severity,
            ));
            hasDanger = true;
            matched = true;
            break;
          }
        }
      }

      // Tier 2 — Standard harmful-keyword dictionary
      if (!matched) {
        for (final entry in standardKeywords.entries) {
          if (lowerName.contains(entry.key)) {
            details.add(IngredientAnalysis(
              ingredientName: name,
              status: IngredientStatus.danger,
              reason:
                  'Identified as harmful for ${entry.value.cond.displayName} '
                  '(local database).',
              severity: 'High',
            ));
            hasDanger = true;
            matched = true;
            break;
          }
        }
      }

      // Safe
      if (!matched) {
        details.add(IngredientAnalysis(
          ingredientName: name,
          status: IngredientStatus.safe,
          reason: 'Not found in local harmful-ingredients database.',
        ));
      }
    }

    return LocalAnalysisResult(
      hasDanger ? IngredientStatus.danger : IngredientStatus.safe,
      details,
    );
  }
}
