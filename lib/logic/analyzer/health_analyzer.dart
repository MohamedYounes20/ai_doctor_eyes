import '../../models/health_condition.dart';
import '../../models/analysis_models.dart';
import '../../core/constants/ingredient_constants.dart';
import '../transformer/ingredient_transformer.dart';

class LocalAnalysisResult {
  final IngredientStatus status;
  final List<IngredientAnalysis> details;
  
  LocalAnalysisResult(this.status, this.details);
}

class HealthAnalyzer {
  LocalAnalysisResult analyzeLocal(List<String> canonicalNames, List<HealthCondition> conditions) {
    final details = <IngredientAnalysis>[];
    bool hasDanger = false;

    final allKeywords = <String, ({HealthCondition cond, String original})>{};
    for (final c in conditions) {
      for (final kw in (harmfulKeywords[c] ?? [])) {
        final normalised = IngredientTransformer.isArabic(kw) 
            ? IngredientTransformer.normalizeArabic(kw) 
            : kw.toLowerCase();
        allKeywords[normalised] = (cond: c, original: kw);
      }
    }

    for (final name in canonicalNames) {
      final lowerName = name.toLowerCase();
      final arabicName = IngredientTransformer.normalizeArabic(name);
      bool matched = false;

      // Because the canonicalName might be "Sugar" and keyword is "sugar"
      // we check if canonicalName contains the keyword.
      for (final entry in allKeywords.entries) {
        final kw = entry.key; // This is the normalized original keyword
        final nameForm = IngredientTransformer.isArabic(kw) ? arabicName : lowerName;
        
        if (nameForm.contains(kw)) {
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
