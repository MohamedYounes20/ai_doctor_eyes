import '../../models/health_condition.dart';
import '../../core/constants/ingredient_constants.dart';

class TransformResult {
  final List<String> uniqueCanonicalNames;
  final String mergedRawText;

  TransformResult({
    required this.uniqueCanonicalNames,
    required this.mergedRawText,
  });
}

class IngredientTransformer {
  /// Session memory for multi-side scan merging (30 s window).
  String _lastTransformedText = '';
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sessionMergeWindow = Duration(seconds: 30);

  List<String> _tokenize(String cleanedText) {
    if (cleanedText.isEmpty) return [];
    String s = cleanedText
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'[.؛;-]'), ',')
        .replaceAll('&', ',');
    return s.split(',').map((t) => t.trim()).where((t) => t.length > 1).toList();
  }

  String? _applyOcrCorrection(String token) {
    final lower = token.toLowerCase();
    for (final entry in ocrCorrections.entries) {
      if (lower.contains(entry.key)) {
        return entry.value; // '' means discard
      }
    }
    return null;
  }

  bool _isBlacklisted(String token) {
    final lower = token.toLowerCase();
    for (final phrase in nonIngredientBlacklist) {
      if (lower.contains(phrase.toLowerCase())) return true;
    }
    return false;
  }

  String sanitizeIngredientName(String raw) {
    String s = raw.trim();
    s = s.replaceAll(
        RegExp(r'^(ingredients?|contains?)\s*[:：,]?\s*',
            caseSensitive: false),
        '');
    s = s.replaceAll(RegExp(r'\s+\d+\s*$'), '');
    s = s.replaceAll(RegExp(r'\s+[a-z]{1,3}\s*$', caseSensitive: false), '');
    s = s.trim();
    if (s.isEmpty) return '';
    if (_isBlacklisted(s)) return '';

    final correction = _applyOcrCorrection(s);
    if (correction != null) return correction; // '' means discard

    return s[0].toUpperCase() + s.substring(1);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  TransformResult transform(String cleanedText, List<HealthCondition> conditions) {
    final now = DateTime.now();
    String textForAnalysis = cleanedText;
    if (now.difference(_lastScanTime) < _sessionMergeWindow &&
        _lastTransformedText.isNotEmpty) {
      textForAnalysis = '$_lastTransformedText, $cleanedText';
    }
    _lastTransformedText = cleanedText;
    _lastScanTime = now;

    final rawTokens = _tokenize(textForAnalysis);

    final seenCanonical = <String>{};
    final uniqueNames = <String>[];

    for (final token in rawTokens) {
      final correction = _applyOcrCorrection(token);
      if (correction != null && correction.isEmpty) continue; // noise

      final effectiveToken = correction ?? token;
      String finalName = '';
      bool matched = false;

      final lowerToken = effectiveToken.toLowerCase();

      for (final c in conditions) {
        for (final kw in (harmfulKeywords[c] ?? [])) {
          if (lowerToken.contains(kw.toLowerCase())) {
            finalName = canonicalDisplayName[kw] ?? _capitalize(kw);
            matched = true;
            break;
          }
        }
        if (matched) break;
      }

      if (!matched) {
        finalName = correction ?? sanitizeIngredientName(token);
      }

      if (finalName.isNotEmpty) {
        if (seenCanonical.add(finalName.toLowerCase())) {
          uniqueNames.add(finalName);
        }
      }
    }

    return TransformResult(
      uniqueCanonicalNames: uniqueNames,
      mergedRawText: textForAnalysis,
    );
  }
}
