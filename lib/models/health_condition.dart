/// Health Condition Model
/// 
/// This enum represents the different health conditions that users can select.
/// Each condition has associated harmful ingredients that will be checked
/// when scanning food products.
enum HealthCondition {
  /// Diabetes - checks for sugar-related ingredients
  diabetes,
  
  /// Hypertension - checks for salt and sodium-related ingredients
  hypertension,
  
  /// Gluten Allergy - checks for gluten-containing ingredients
  glutenAllergy;

  /// Get the display name for the health condition
  String get displayName {
    switch (this) {
      case HealthCondition.diabetes:
        return 'Diabetes';
      case HealthCondition.hypertension:
        return 'Hypertension';
      case HealthCondition.glutenAllergy:
        return 'Gluten Allergy';
    }
  }

  /// Get a description of the health condition
  String get description {
    switch (this) {
      case HealthCondition.diabetes:
        return 'Monitor sugar and sweetener intake';
      case HealthCondition.hypertension:
        return 'Monitor salt and sodium intake';
      case HealthCondition.glutenAllergy:
        return 'Avoid gluten-containing ingredients';
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
