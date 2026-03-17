import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_condition.dart';

class PreferencesService {
  static const String _healthConditionKey = 'selected_health_condition';
  static const String _fullNameKey = 'full_name';
  static const String _yearOfBirthKey = 'year_of_birth';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _voiceFeedbackEnabledKey = 'voice_feedback_enabled';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // --- User profile ---
  Future<bool> saveUserProfile(
      {required String fullName, required int yearOfBirth}) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_fullNameKey, fullName);
      await prefs.setInt(_yearOfBirthKey, yearOfBirth);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getFullName() async {
    final prefs = await _prefs;
    return prefs.getString(_fullNameKey);
  }

  Future<int?> getYearOfBirth() async {
    final prefs = await _prefs;
    return prefs.getInt(_yearOfBirthKey);
  }

  int? getAgeFromYearOfBirth(int year) {
    final now = DateTime.now().year;
    return now - year;
  }

  // --- Onboarding ---
  Future<bool> setOnboardingCompleted(bool value) async {
    try {
      final prefs = await _prefs;
      return await prefs.setBool(_hasCompletedOnboardingKey, value);
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  // --- Vibration ---
  Future<bool> setVibrationEnabled(bool value) async {
    try {
      final prefs = await _prefs;
      return await prefs.setBool(_vibrationEnabledKey, value);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  // --- Voice feedback ---
  Future<bool> setVoiceFeedbackEnabled(bool value) async {
    try {
      final prefs = await _prefs;
      return await prefs.setBool(_voiceFeedbackEnabledKey, value);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isVoiceFeedbackEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_voiceFeedbackEnabledKey) ?? false;
  }

  Future<bool> saveHealthConditions(List<HealthCondition> conditions) async {
    try {
      final prefs = await _prefs;
      final jsonList = conditions.map((c) => c.toJson()).toList();
      return await prefs.setStringList(_healthConditionKey, jsonList);
    } catch (e) {
      return false;
    }
  }

  Future<List<HealthCondition>> getHealthConditions() async {
    try {
      final prefs = await _prefs;
      var list = prefs.getStringList(_healthConditionKey);
      // Migration: old format stored single condition as string
      if (list == null) {
        final single = prefs.getString(_healthConditionKey);
        if (single != null) list = [single];
      }
      if (list == null || list.isEmpty) return [];
      return list
          .map((s) => HealthCondition.fromJson(s))
          .whereType<HealthCondition>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Legacy: returns first condition for backward compatibility
  Future<HealthCondition?> getHealthCondition() async {
    final conditions = await getHealthConditions();
    return conditions.isNotEmpty ? conditions.first : null;
  }

  Future<bool> hasHealthCondition() async {
    final conditions = await getHealthConditions();
    return conditions.isNotEmpty;
  }

  Future<bool> clearHealthConditions() async {
    try {
      final prefs = await _prefs;
      return await prefs.remove(_healthConditionKey);
    } catch (e) {
      return false;
    }
  }

  /// Legacy alias
  Future<bool> clearHealthCondition() async => clearHealthConditions();
}
