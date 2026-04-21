import 'dart:convert';

class LabRecord {
  final int? id;
  final DateTime dateTime;
  final String conditionTitle;
  final List<String> forbiddenIngredients;

  const LabRecord({
    this.id,
    required this.dateTime,
    required this.conditionTitle,
    required this.forbiddenIngredients,
  });

  factory LabRecord.fromMap(Map<String, dynamic> map) {
    return LabRecord(
      id: map['id'] as int?,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      conditionTitle: map['condition_title'] as String,
      forbiddenIngredients: _decodeKeywords(map['forbidden_ingredients'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date_time': dateTime.millisecondsSinceEpoch,
      'condition_title': conditionTitle,
      'forbidden_ingredients': jsonEncode(forbiddenIngredients),
    };
  }

  static List<String> _decodeKeywords(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }
}
