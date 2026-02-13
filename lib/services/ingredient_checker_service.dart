import '../models/health_condition.dart';

/// Ingredient Checker Service
/// 
/// This service contains the logic to check if scanned text contains
/// harmful ingredients based on the selected health condition.
class IngredientCheckerService {
  /// Dictionary of harmful keywords for each health condition
  /// 
  /// Each condition maps to a list of keywords that should trigger a warning
  /// when found in scanned ingredient lists.
  static final Map<HealthCondition, List<String>> _harmfulIngredients = {
    HealthCondition.diabetes: [
      'sugar',
      'glucose',
      'fructose',
      'syrup',
      'maltodextrin',
      'sucrose',
      'dextrose',
      'corn syrup',
      'high fructose',
    ],
    HealthCondition.glutenAllergy: [
      'wheat',
      'barley',
      'rye',
      'gluten',
      'malt',
      'triticale',
      'semolina',
      'durum',
    ],
    HealthCondition.nutAllergy: [
      'peanut',
      'almond',
      'cashew',
      'walnut',
      'hazelnut',
      'pecan',
      'pistachio',
      'macadamia',
      'tree nut',
      'nuts',
    ],
    HealthCondition.hypertension: [
      'salt',
      'sodium',
      'nacl',
      'msg',
      'monosodium glutamate',
      'sodium chloride',
      'sea salt',
      'table salt',
    ],
  };

  /// Check if the scanned text contains harmful ingredients for multiple conditions
  ///
  /// [scannedText] - The text extracted from the camera using ML Kit
  /// [conditions] - The user's selected health conditions
  ///
  /// Returns a list of found harmful ingredients, empty if none found
  List<String> checkForHarmfulIngredients(
    String scannedText,
    List<HealthCondition> conditions,
  ) {
    final foundIngredients = <String>{};
    final lowerText = scannedText.toLowerCase();

    for (final condition in conditions) {
      final harmfulKeywords = _harmfulIngredients[condition] ?? [];
      for (final keyword in harmfulKeywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          foundIngredients.add(keyword);
        }
      }
    }

    return foundIngredients.toList();
  }

  /// Single-condition overload for backward compatibility
  List<String> checkForHarmfulIngredientsSingle(
    String scannedText,
    HealthCondition condition,
  ) =>
      checkForHarmfulIngredients(scannedText, [condition]);

  /// Check if the scanned text is safe (no harmful ingredients found)
  ///
  /// [scannedText] - The text extracted from the camera using ML Kit
  /// [conditions] - The user's selected health conditions
  ///
  /// Returns true if safe, false if harmful ingredients are found
  bool isSafe(String scannedText, List<HealthCondition> conditions) {
    final harmfulIngredients = checkForHarmfulIngredients(scannedText, conditions);
    return harmfulIngredients.isEmpty;
  }
}
