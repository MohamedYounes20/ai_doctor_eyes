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
  };

  /// Check if the scanned text contains harmful ingredients
  /// 
  /// [scannedText] - The text extracted from the camera using ML Kit
  /// [condition] - The user's selected health condition
  /// 
  /// Returns a list of found harmful ingredients, empty if none found
  List<String> checkForHarmfulIngredients(
    String scannedText,
    HealthCondition condition,
  ) {
    // Get the list of harmful keywords for this condition
    final harmfulKeywords = _harmfulIngredients[condition] ?? [];

    // Convert scanned text to lowercase for case-insensitive matching
    final lowerText = scannedText.toLowerCase();

    // Find all matching harmful ingredients
    final foundIngredients = <String>[];
    for (final keyword in harmfulKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        foundIngredients.add(keyword);
      }
    }

    return foundIngredients;
  }

  /// Check if the scanned text is safe (no harmful ingredients found)
  /// 
  /// [scannedText] - The text extracted from the camera using ML Kit
  /// [condition] - The user's selected health condition
  /// 
  /// Returns true if safe, false if harmful ingredients are found
  bool isSafe(String scannedText, HealthCondition condition) {
    final harmfulIngredients = checkForHarmfulIngredients(scannedText, condition);
    return harmfulIngredients.isEmpty;
  }
}
