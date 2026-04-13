import '../../models/health_condition.dart';
import '../../core/constants/ingredient_constants.dart';

class TransformResult {
  final List<String> uniqueCanonicalNames;
  final bool usedArabicGuess;
  final bool isHeavyArabic;
  final String mergedRawText;
  
  TransformResult({
    required this.uniqueCanonicalNames,
    required this.usedArabicGuess,
    required this.isHeavyArabic,
    required this.mergedRawText,
  });
}

class IngredientTransformer {
  /// Session memory for multi-side scan merging (30 s window).
  String _lastTransformedText = '';
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sessionMergeWindow = Duration(seconds: 30);

  // ── Arabic text normalisation ───────────────────────────────────────────────

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
  static final RegExp _alefVariantsRegex = RegExp(r'[\u0622\u0623\u0624\u0625\u0627]');

  static String normalizeArabic(String s) {
    String result = s.replaceAll(_tashkeelRegex, '');
    result = result.replaceAll(_alefVariantsRegex, '\u0627');
    result = result.replaceAll('\u0629', '\u0647');
    return result;
  }

  static bool isArabic(String s) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  static double _arabicFraction(String s) {
    final nonSpace = s.replaceAll(RegExp(r'\s'), '');
    if (nonSpace.isEmpty) return 0;
    final arabicCount = RegExp(r'[\u0600-\u06FF]').allMatches(nonSpace).length;
    return arabicCount / nonSpace.length;
  }

  static String _stripToArabicLetters(String s) =>
      normalizeArabic(s).replaceAll(RegExp(r'[^\u0627-\u064A]'), '');

  List<String> _tokenize(String cleanedText) {
    if (cleanedText.isEmpty) return [];
    String s = cleanedText
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bو\b'), ',')
        .replaceAll(RegExp(r'[.؛;-]'), ',') // Splitting on dashes as well as commas/dots
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
        RegExp(r'^(ingredients?|contains?|المكونات|مكونات)\s*[:：،,]?\s*',
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

  ({String canonical, String keyword, HealthCondition condition})?
      _guessGarbledArabic(String token, List<HealthCondition> conditions) {
    if (!isArabic(token)) return null;

    final stripped = _stripToArabicLetters(token);
    if (stripped.length < 2) return null;

    final setA = stripped.runes.toSet();

    for (final c in conditions) {
      for (final kw in (harmfulKeywords[c] ?? [])) {
        if (!isArabic(kw)) continue;
        final kwStripped = _stripToArabicLetters(kw);
        if (kwStripped.length < 2) continue;

        final setB = kwStripped.runes.toSet();
        final intersection = setA.intersection(setB).length;
        final union = setA.union(setB).length;
        final similarity = union > 0 ? intersection / union : 0.0;

        if (similarity > 0.6) {
          final canonical = canonicalDisplayName[kw] ?? kw;
          return (canonical: canonical, keyword: kw, condition: c);
        }
      }
    }
    return null;
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
    final isHeavyArabic = _arabicFraction(textForAnalysis) >= 0.8;

    final seenCanonical = <String>{};
    final uniqueNames = <String>[];
    bool usedArabicGuess = false;

    // Use a pre-processing loop that transforms every token to its canonical form
    for (final token in rawTokens) {
      final correction = _applyOcrCorrection(token);
      if (correction != null && correction.isEmpty) continue; // noise

      final effectiveToken = correction ?? token;
      String finalName = '';
      bool matched = false;

      final lowerToken = effectiveToken.toLowerCase();
      final arabicToken = normalizeArabic(effectiveToken);

      for (final c in conditions) {
        for (final kw in (harmfulKeywords[c] ?? [])) {
          final tokenForm = isArabic(kw) ? arabicToken : lowerToken;
          final normalised = isArabic(kw) ? normalizeArabic(kw) : kw.toLowerCase();
          
          if (tokenForm.contains(normalised)) {
            finalName = canonicalDisplayName[kw] ?? _capitalize(kw);
            matched = true;
            break;
          }
        }
        if (matched) break;
      }

      if (!matched && isArabic(effectiveToken)) {
         final guess = _guessGarbledArabic(effectiveToken, conditions);
         if (guess != null) {
            finalName = guess.canonical;
            matched = true;
            usedArabicGuess = true;
         }
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
      usedArabicGuess: usedArabicGuess,
      isHeavyArabic: isHeavyArabic,
      mergedRawText: textForAnalysis,
    );
  }
}
