import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

/// A reusable two-tone ExtraBold header widget matching the Figma design.
///
/// Renders [firstWord] using the theme's [ColorScheme.onSurface] so it adapts
/// correctly to both light and dark mode. [secondWord] always uses
/// [AppTheme.textAccent] with a neon glowing drop-shadow. When [hasLineBreak]
/// is `true` the two words are placed on separate lines; otherwise they appear
/// on the same line separated by a space.
///
/// Example:
/// ```dart
/// ModernHeader(
///   firstWord: 'Smart',
///   secondWord: 'Alternatives',
///   hasLineBreak: true,
/// )
/// ```
class ModernHeader extends StatelessWidget {
  const ModernHeader({
    super.key,
    required this.firstWord,
    required this.secondWord,
    required this.hasLineBreak,
  });

  final String firstWord;
  final String secondWord;
  final bool hasLineBreak;

  static const double _fontSize = 36.0;
  static const double _letterSpacing = -1.2;
  static const double _lineHeight = 1.1;

  @override
  Widget build(BuildContext context) {
    // Adapt the first-word colour to the active theme so it stays readable
    // in both light (dark text) and dark (white text) modes.
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    // Base Poppins ExtraBold style shared by both spans.
    final TextStyle baseStyle = GoogleFonts.poppins(
      fontSize: _fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: _letterSpacing,
      height: _lineHeight,
    );

    final TextStyle foregroundStyle = baseStyle.copyWith(
      color: onSurface,
    );

    final TextStyle accentStyle = baseStyle.copyWith(
      color: AppTheme.textAccent,
      shadows: const [
        Shadow(
          color: AppTheme.accentShadow,
          blurRadius: 8.0,
          offset: Offset(0, 0),
        ),
      ],
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: firstWord, style: foregroundStyle),
          if (hasLineBreak)
            TextSpan(text: '\n', style: baseStyle)
          else
            TextSpan(text: ' ', style: baseStyle),
          TextSpan(text: secondWord, style: accentStyle),
        ],
      ),
    );
  }
}
