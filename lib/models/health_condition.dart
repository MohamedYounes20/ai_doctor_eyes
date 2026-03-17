/// Health Condition Model
///
/// This enum represents the different health conditions that users can select.
/// Each condition has associated harmful ingredients that will be checked
/// when scanning food products.
enum HealthCondition {
  /// Diabetes - checks for sugar-related ingredients
  diabetes,

  /// Gluten Allergy - checks for gluten-containing ingredients
  glutenAllergy,

  /// Nut Allergy - checks for nut-containing ingredients
  nutAllergy,

  /// Hypertension - checks for salt and sodium-related ingredients
  hypertension,

  /// Lactose Intolerance - checks for dairy-related ingredients
  lactoseIntolerance,

  /// Vegan - checks for animal-derived ingredients
  vegan,

  /// Keto - checks for high-carb ingredients
  keto,

  /// Low FODMAP - checks for fermentable carbohydrate ingredients
  lowFodmap,

  /// Shellfish Allergy - checks for shellfish-containing ingredients
  shellfishAllergy,

  /// Soy Allergy - checks for soy-containing ingredients
  soyAllergy;

  /// Get the display name for the health condition
  String get displayName {
    switch (this) {
      case HealthCondition.diabetes:
        return 'Diabetes';
      case HealthCondition.glutenAllergy:
        return 'Gluten Allergy';
      case HealthCondition.nutAllergy:
        return 'Nut Allergy';
      case HealthCondition.hypertension:
        return 'Hypertension';
      case HealthCondition.lactoseIntolerance:
        return 'Lactose Intolerance';
      case HealthCondition.vegan:
        return 'Vegan';
      case HealthCondition.keto:
        return 'Keto Diet';
      case HealthCondition.lowFodmap:
        return 'Low FODMAP';
      case HealthCondition.shellfishAllergy:
        return 'Shellfish Allergy';
      case HealthCondition.soyAllergy:
        return 'Soy Allergy';
    }
  }

  /// Get a description of the health condition
  String get description {
    switch (this) {
      case HealthCondition.diabetes:
        return 'Monitor sugar and sweetener intake';
      case HealthCondition.glutenAllergy:
        return 'Avoid gluten-containing ingredients';
      case HealthCondition.nutAllergy:
        return 'Avoid nut-containing ingredients';
      case HealthCondition.hypertension:
        return 'Monitor salt and sodium intake';
      case HealthCondition.lactoseIntolerance:
        return 'Avoid dairy and lactose ingredients';
      case HealthCondition.vegan:
        return 'Avoid all animal-derived products';
      case HealthCondition.keto:
        return 'Avoid high-carb ingredients';
      case HealthCondition.lowFodmap:
        return 'Avoid fermentable carbohydrates';
      case HealthCondition.shellfishAllergy:
        return 'Avoid shellfish-containing ingredients';
      case HealthCondition.soyAllergy:
        return 'Avoid soy-containing ingredients';
    }
  }

  /// Convert enum to string for storage
  String toJson() => name;

  /// Create enum from string (for loading from storage)
  static HealthCondition? fromJson(String? value) {
    if (value == null) return null;
    try {
      return HealthCondition.values.firstWhere(
        (condition) => condition.name == value,
      );
    } catch (e) {
      return null;
    }
  }
}
