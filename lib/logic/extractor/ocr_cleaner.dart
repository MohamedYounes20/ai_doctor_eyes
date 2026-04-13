import '../../core/constants/ingredient_constants.dart';

class OcrCleaner {
  String cleanOcrText(String raw) {
    final lines = raw.split(RegExp(r'[\r\n]+'));
    final kept = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      bool isNoisy = false;
      for (final pattern in nutritionLinePatterns) {
        if (pattern.hasMatch(trimmed)) {
          isNoisy = true;
          break;
        }
      }
      if (isNoisy) continue;

      final nonSpace = trimmed.replaceAll(' ', '');
      if (nonSpace.isNotEmpty) {
        final numericCount =
            nonSpace.replaceAll(RegExp(r'[^0-9%.,:/()-]'), '').length;
        if (numericCount / nonSpace.length > 0.6) continue;
      }

      kept.add(trimmed);
    }

    String result = kept.join(', ');
    result = result.replaceAll(
        RegExp(r'^(ingredients?|contains?)\s*[:：,]?\s*',
            caseSensitive: false),
        '');
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return result;
  }
}
