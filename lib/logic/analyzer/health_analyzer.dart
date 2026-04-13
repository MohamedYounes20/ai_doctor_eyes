import '../../models/health_condition.dart';
import '../../models/analysis_models.dart';
import '../../core/constants/ingredient_constants.dart';

class LocalAnalysisResult {
  final IngredientStatus status;
  final List<IngredientAnalysis> details;

  LocalAnalysisResult(this.status, this.details);
}

class HealthAnalyzer {
  LocalAnalysisResult analyzeLocal(List<String> canonicalNames, List<HealthCondition> conditions) {
    final details = <IngredientAnalysis>[];
    bool hasDanger = false;

    // Build a flat map of lowercase keyword → condition info
    final allKeywords = <String, ({HealthCondition cond, String original})>{};
    for (final c in conditions) {
      for (final kw in (harmfulKeywords[c] ?? [])) {
        allKeywords[kw.toLowerCase()] = (cond: c, original: kw);
      }
    }

    for (final name in canonicalNames) {
      final lowerName = name.toLowerCase();
      bool matched = false;

      for (final entry in allKeywords.entries) {
        if (lowerName.contains(entry.key)) {
          details.add(IngredientAnalysis(
            ingredientName: name,
            status: IngredientStatus.danger,
            reason: 'Identified as harmful for ${entry.value.cond.displayName} (local database).',
            severity: 'High',
          ));
          hasDanger = true;
          matched = true;
          break;
        }
      }

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
