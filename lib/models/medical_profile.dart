import 'dart:convert';

/// Represents a user's medical profile extracted from a lab report image
/// via Gemini Vision. Persisted in the local SQLite `medical_profile` table.
///
/// Only one row is ever stored — upsert semantics are used in [DatabaseHelper].
class MedicalProfile {
  final String condition;
  final List<String> forbiddenKeywords;
  final String severity; // 'High' | 'Medium' | 'Low'
  final DateTime lastUpdated;

  const MedicalProfile({
    required this.condition,
    required this.forbiddenKeywords,
    required this.severity,
    required this.lastUpdated,
  });

  // ── SQLite serialisation ──────────────────────────────────────────────────

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    return MedicalProfile(
      condition: map['condition'] as String? ?? '',
      forbiddenKeywords: _decodeKeywords(map['forbidden_keywords'] as String?),
      severity: map['severity'] as String? ?? 'High',
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          (map['last_updated'] as int?) ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
        'condition': condition,
        'forbidden_keywords': jsonEncode(forbiddenKeywords),
        'severity': severity,
        'last_updated': lastUpdated.millisecondsSinceEpoch,
      };

  // ── Backup / Restore JSON serialisation ──────────────────────────────────

  factory MedicalProfile.fromJson(Map<String, dynamic> json) =>
      MedicalProfile.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _decodeKeywords(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {
      // Fallback: comma-separated plain string (legacy safety)
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  @override
  String toString() =>
      'MedicalProfile(condition: $condition, keywords: $forbiddenKeywords, severity: $severity)';
}
