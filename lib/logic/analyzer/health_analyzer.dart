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
    for (int i = 0; i < canonicalNames.length; i++) {
      final name = canonicalNames[i];
      final lowerName = name.toLowerCase();
      bool matched = false;
      
      final double positionRatio = i / canonicalNames.length;

      // Tier 1 — Critical (user's personal lab report keywords)
      if (criticalKeywords.isNotEmpty) {
        for (final kw in criticalKeywords) {
          if (lowerName.contains(kw)) {
            String severityStr;
            String reasonStr;
            if (positionRatio <= 0.50) {
              severityStr = 'CRITICAL 🚨';
              reasonStr = 'High percentage of this ingredient. Extremely dangerous for your condition.';
            } else {
              severityStr = 'WARNING 🩺';
              reasonStr = 'Contains trace amounts, but still unsafe for your medical condition.';
            }

            details.add(IngredientAnalysis(
              ingredientName: name,
              status: IngredientStatus.danger,
              reason: reasonStr,
              severity: severityStr,
              isMedicalProfileHit: true,
              positionRatio: positionRatio,
            ));
            matched = true;
            break;
          }
        }
      }

      // Tier 2 — Standard harmful-keyword dictionary
      if (!matched) {
        for (final entry in standardKeywords.entries) {
          if (lowerName.contains(entry.key)) {
            IngredientStatus tier2Status;
            String tier2Severity;
            
            if (positionRatio <= 0.33) {
              tier2Status = IngredientStatus.danger;
              tier2Severity = 'High Concentration';
            } else if (positionRatio <= 0.66) {
              tier2Status = IngredientStatus.warning;
              tier2Severity = 'Medium Amount';
            } else {
              tier2Status = IngredientStatus.trace;
              tier2Severity = 'Trace Amount';
            }

            details.add(IngredientAnalysis(
              ingredientName: name,
              status: tier2Status,
              reason: 'Identified as harmful for ${entry.value.cond.displayName} (local database).',
              severity: tier2Severity,
              isMedicalProfileHit: false,
              positionRatio: positionRatio,
            ));
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
          isMedicalProfileHit: false,
          positionRatio: positionRatio,
        ));
      }
    }

    IngredientStatus highestStatus = IngredientStatus.safe;
    bool hasMedicalHit = false;
    bool hasLocalHit = false;

    for (final d in details) {
      if (d.isMedicalProfileHit) {
        hasMedicalHit = true;
      } else if (d.status == IngredientStatus.danger || 
                 d.status == IngredientStatus.warning || 
                 d.status == IngredientStatus.trace) {
        hasLocalHit = true;
      }
    }

    if (hasMedicalHit) {
      highestStatus = IngredientStatus.danger;
    } else if (hasLocalHit) {
      highestStatus = IngredientStatus.warning;
    }

    return LocalAnalysisResult(highestStatus, details);
  }
}
