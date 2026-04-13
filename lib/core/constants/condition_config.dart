import 'package:flutter/material.dart';
import '../../models/health_condition.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Condition Visual Config
//
// Single source of truth for the emoji and accent color of each health
// condition. Used by SelectionScreen, ProfileScreen, and any future UI
// that needs to display condition chips/cards.
// ═══════════════════════════════════════════════════════════════════════════════

/// Visual configuration for each health condition.
class ConditionVisual {
  final HealthCondition condition;
  final String emoji;
  final Color color;

  const ConditionVisual(this.condition, this.emoji, this.color);
}

/// Ordered list of all condition visuals.
const List<ConditionVisual> conditionVisuals = [
  ConditionVisual(HealthCondition.diabetes, '🩸', Color(0xFF9C27B0)),
  ConditionVisual(HealthCondition.glutenAllergy, '🌾', Color(0xFFB8860B)),
  ConditionVisual(HealthCondition.nutAllergy, '🥜', Color(0xFF8B4513)),
  ConditionVisual(HealthCondition.hypertension, '❤️', Color(0xFFE53935)),
  ConditionVisual(HealthCondition.lactoseIntolerance, '🥛', Color(0xFF039BE5)),
  ConditionVisual(HealthCondition.vegan, '🥦', Color(0xFF43A047)),
  ConditionVisual(HealthCondition.keto, '🥑', Color(0xFF00897B)),
  ConditionVisual(HealthCondition.lowFodmap, '🫐', Color(0xFF5E35B1)),
  ConditionVisual(HealthCondition.shellfishAllergy, '🦐', Color(0xFFEF6C00)),
  ConditionVisual(HealthCondition.soyAllergy, '🌱', Color(0xFF6D4C41)),
];

/// Quick lookup: condition display name → emoji.
String emojiForCondition(String displayName) {
  for (final v in conditionVisuals) {
    if (v.condition.displayName == displayName) return v.emoji;
  }
  return '💊';
}
