import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doctor_eyes/logic/analyzer/health_analyzer.dart';
import 'package:ai_doctor_eyes/logic/extractor/ocr_cleaner.dart';
import 'package:ai_doctor_eyes/models/health_condition.dart';
import 'package:ai_doctor_eyes/models/medical_profile.dart';
import 'package:ai_doctor_eyes/models/analysis_models.dart';

void main() {
  group('Group 1: Text Isolation (Regex) Tests (OcrCleaner)', () {
    late OcrCleaner cleaner;

    setUp(() {
      cleaner = OcrCleaner();
    });

    test('Case 1: OCR text contains random garbage followed by Ingredients', () {
      final rawText = '''
Nutrition Facts
Calories 200
Total Fat 5g
Ingredients: Water, Sugar, Salt
      ''';
      
      final cleaned = cleaner.cleanOcrText(rawText);
      expect(cleaned, 'Water, Sugar, Salt');
    });

    test('Case 2: OCR text contains Arabic keyword (المكونات)', () {
      final rawText = 'معلومات غذائية عشوائية\nالمكونات: سكر، زيت';
      final cleaned = cleaner.cleanOcrText(rawText);
      expect(cleaned, 'سكر، زيت');
    });

    test('Case 3: Fallback (NO keyword) returns the entire text safely', () {
      final rawText = 'Just some random text\nWater, Sugar, Salt';
      final cleaned = cleaner.cleanOcrText(rawText);
      expect(cleaned, 'Just some random text, Water, Sugar, Salt');
    });
  });

  group('Group 2: Proportional Indexing (Math Logic)', () {
    late HealthAnalyzer analyzer;

    setUp(() {
      analyzer = HealthAnalyzer();
    });

    test('Case 1: Short list of 2 items', () {
      final canonicalNames = ['Salt', 'Sugar'];
      final conditions = [HealthCondition.hypertension, HealthCondition.diabetes];

      final result = analyzer.analyzeLocal(canonicalNames, conditions);
      
      final saltAnalysis = result.details.firstWhere((e) => e.ingredientName == 'Salt');
      expect(saltAnalysis.positionRatio, 0.0);
      expect(saltAnalysis.status, IngredientStatus.danger);
      expect(saltAnalysis.severity, 'High Concentration');

      final sugarAnalysis = result.details.firstWhere((e) => e.ingredientName == 'Sugar');
      expect(sugarAnalysis.positionRatio, 0.5);
      expect(sugarAnalysis.status, IngredientStatus.warning);
      expect(sugarAnalysis.severity, 'Medium Amount');
    });

    test('Case 2: Long list of 10 items (Trace Amount test)', () {
      final canonicalNames = ['Water', 'Flour', 'Yeast', 'Butter', 'Milk', 'Egg', 'Vanilla', 'Baking Powder', 'Salt', 'Sugar'];
      final conditions = [HealthCondition.hypertension, HealthCondition.diabetes];

      final result = analyzer.analyzeLocal(canonicalNames, conditions);

      // Sugar is at index 9. Ratio = 9 / 10 = 0.9. (> 0.66)
      final sugarAnalysis = result.details.firstWhere((e) => e.ingredientName == 'Sugar');
      expect(sugarAnalysis.positionRatio, 0.9);
      expect(sugarAnalysis.status, IngredientStatus.trace);
      expect(sugarAnalysis.severity, 'Trace Amount');
    });
  });

  group('Group 3: Medical Profile Override (Tier 1 vs Tier 2)', () {
    late HealthAnalyzer analyzer;

    setUp(() {
      analyzer = HealthAnalyzer();
    });

    test('Case 1: Medical hit overrides local DB and sets danger even at end of list', () {
      // 10 items. Sodium is at index 9. Ratio = 0.9.
      final canonicalNames = ['Water', 'Flour', 'Yeast', 'Butter', 'Milk', 'Egg', 'Vanilla', 'Baking Powder', 'Sugar', 'Sodium'];
      final conditions = [HealthCondition.diabetes]; // No hypertension in local DB, so only the medical profile catches Sodium
      
      final medicalProfile = MedicalProfile(
        condition: 'Severe Hypertension',
        forbiddenKeywords: ['sodium'],
        severity: 'High',
        lastUpdated: DateTime.now(),
      );

      final result = analyzer.analyzeLocal(
        canonicalNames, 
        conditions,
        medicalProfile: medicalProfile,
      );

      final sodiumAnalysis = result.details.firstWhere((e) => e.ingredientName == 'Sodium');
      expect(sodiumAnalysis.positionRatio, 0.9);
      expect(sodiumAnalysis.isMedicalProfileHit, true);
      expect(sodiumAnalysis.status, IngredientStatus.danger);
      expect(sodiumAnalysis.severity, 'WARNING 🩺'); // ratio > 0.50 gets the WARNING 🩺 severity but danger status
      
      // The overall result should be danger because of the medical hit
      expect(result.status, IngredientStatus.danger);
    });
  });
}
