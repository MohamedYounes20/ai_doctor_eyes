import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_condition.dart';

/// Preferences Service
/// 
/// This service handles all local storage operations using SharedPreferences.
/// It stores and retrieves the user's selected health condition.
class PreferencesService {
  // Key for storing the selected health condition
  static const String _healthConditionKey = 'selected_health_condition';

  /// Get the SharedPreferences instance
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Save the selected health condition to local storage
  /// 
  /// [condition] - The health condition to save
  /// Returns true if saved successfully, false otherwise
  Future<bool> saveHealthCondition(HealthCondition condition) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_healthConditionKey, condition.toJson());
    } catch (e) {
      return false;
    }
  }

  /// Get the saved health condition from local storage
  /// 
  /// Returns the saved HealthCondition, or null if none is saved
  Future<HealthCondition?> getHealthCondition() async {
    try {
      final prefs = await _prefs;
      final conditionString = prefs.getString(_healthConditionKey);
      return HealthCondition.fromJson(conditionString);
    } catch (e) {
      return null;
    }
  }

  /// Check if a health condition has been selected
  /// 
  /// Returns true if a condition is saved, false otherwise
  Future<bool> hasHealthCondition() async {
    final condition = await getHealthCondition();
    return condition != null;
  }

  /// Clear the saved health condition
  /// 
  /// Returns true if cleared successfully, false otherwise
  Future<bool> clearHealthCondition() async {
    try {
      final prefs = await _prefs;
      return await prefs.remove(_healthConditionKey);
    } catch (e) {
      return false;
    }
  }
}
