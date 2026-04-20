import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/analysis_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Scanner Result Sheet
//
// Bottom-sheet UI extracted from scanner_screen.dart for Single Responsibility.
// Shows the analysis result (status banner, AI summary, ingredient issues).
//
// NO business logic — purely presentational.
// ═══════════════════════════════════════════════════════════════════════════════

class ScannerResultSheet extends StatelessWidget {
  final IngredientStatus status;
  final AnalysisSource analysisSource;
  final List<IngredientAnalysis> ingredientDetails;
  final String reasonAr;
  final String analysisEn;
  final bool partialArabicWarning;

  const ScannerResultSheet({
    super.key,
    required this.status,
    required this.analysisSource,
    required this.ingredientDetails,
    this.reasonAr = '',
    this.analysisEn = '',
    this.partialArabicWarning = false,
  });

  /// Show this sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required IngredientStatus status,
    required AnalysisSource analysisSource,
    required List<IngredientAnalysis> ingredientDetails,
    String reasonAr = '',
    String analysisEn = '',
    bool partialArabicWarning = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppTheme.navyCard : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (context, scrollController) => ScannerResultSheet(
          status: status,
          analysisSource: analysisSource,
          ingredientDetails: ingredientDetails,
          reasonAr: reasonAr,
          analysisEn: analysisEn,
          partialArabicWarning: partialArabicWarning,
        )._buildContent(context, scrollController),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color = AppTheme.safeColor;
    IconData icon = Icons.check_circle;
    String statusText = 'SAFE';

    if (status == IngredientStatus.danger) {
      color = AppTheme.dangerColor;
      icon = Icons.warning_rounded;
      statusText = 'DANGER';
    } else if (status == IngredientStatus.warning) {
      color = AppTheme.warningColor;
      icon = Icons.error_outline;
      statusText = 'WARNING';
    }

    final issues = ingredientDetails
        .where((d) => d.status != IngredientStatus.safe)
        .where((d) => _isValidIngredientName(d.ingredientName))
        .toList();

    final sheetBg = isDark ? AppTheme.navyCard : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.navyColor;
    final subColor = isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600;

    return Container(
      color: sheetBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Analysis Result',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Source badge
            Center(child: _buildSourceBadge()),
            const SizedBox(height: 16),

            // Status banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.titleFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Partial Arabic warning
            if (partialArabicWarning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.translate, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Analysis based on partial Arabic text. '
                        'Scan English ingredients if available for 100% accuracy.',
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bilingual AI summary (only when available)
            if (analysisEn.isNotEmpty || reasonAr.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.neonMint.withOpacity(0.08)
                      : AppTheme.mintColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? AppTheme.neonMint.withOpacity(0.25)
                          : AppTheme.mintColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology,
                            color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                            size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'AI Analysis',
                          style: TextStyle(
                            color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (analysisEn.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        analysisEn,
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                    ],
                    if (reasonAr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reasonAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ingredient issues
            Text(
              'Ingredient Issues',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 10),

            if (issues.isEmpty)
              Text(
                'No harmful ingredients found.',
                style: TextStyle(
                    fontSize: AppTheme.bodyFontSize, color: subColor),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: issues.map((ing) => _buildIngredientPill(ing)).toList(),
              ),

            const SizedBox(height: 16),

            // Detailed list below pills
            if (issues.isNotEmpty)
              ...issues.map((ing) => _buildIssueRow(context, ing)),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  foregroundColor: isDark ? AppTheme.spaceBlack : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _buildSourceBadge() {
    switch (analysisSource) {
      case AnalysisSource.aiAnalysis:
        return _badge('🤖 Deep AI Analysis', Colors.indigo);
      case AnalysisSource.aiCached:
        return _badge('🤖 AI (Cached)', Colors.teal);
      case AnalysisSource.fallback:
        return _badge('⚡ Local Scan (AI failed)', Colors.deepOrange);
      case AnalysisSource.localScan:
        return _badge('⚡ Local Fast Scan', Colors.blueGrey);
    }
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildIngredientPill(IngredientAnalysis ing) {
    final isDanger = ing.status == IngredientStatus.danger;
    final isTrace = ing.status == IngredientStatus.trace;
    final isMedical = ing.isMedicalProfileHit;
    
    Color bg;
    Color border;
    Color textColor;
    IconData iconData;

    if (isMedical || isDanger) {
      bg = AppTheme.dangerColor.withOpacity(0.12);
      border = AppTheme.dangerColor.withOpacity(0.4);
      textColor = AppTheme.dangerColor;
      iconData = isMedical ? Icons.medical_services_outlined : Icons.warning_rounded;
    } else if (isTrace) {
      bg = Colors.grey.withOpacity(0.12);
      border = Colors.grey.withOpacity(0.4);
      textColor = Colors.grey.shade600;
      iconData = Icons.check;
    } else { // Warning
      bg = AppTheme.warningColor.withOpacity(0.12);
      border = AppTheme.warningColor.withOpacity(0.4);
      textColor = AppTheme.warningColor;
      iconData = Icons.error_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            ing.ingredientName,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueRow(BuildContext context, IngredientAnalysis ing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDanger = ing.status == IngredientStatus.danger;
    final isTrace = ing.status == IngredientStatus.trace;
    final isMedical = ing.isMedicalProfileHit;

    Color iconColor;
    IconData iconData;

    if (isMedical || isDanger) {
      iconColor = AppTheme.dangerColor;
      iconData = isMedical ? Icons.medical_services_outlined : Icons.warning_rounded;
    } else if (isTrace) {
      iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      iconData = Icons.check;
    } else {
      iconColor = AppTheme.warningColor;
      iconData = Icons.error_outline;
    }
    
    final textColor = isDark ? Colors.white : AppTheme.navyColor;
    final subColor = isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ing.ingredientName,
                        style: TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (ing.severity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: iconColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          ing.severity!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  ing.reason,
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns false for ingredient names that are OCR noise.
  bool _isValidIngredientName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 3) return false;

    final nonSpace = trimmed.replaceAll(RegExp(r'\s'), '');
    if (nonSpace.isEmpty) return false;

    final symbolCount =
        nonSpace.replaceAll(RegExp(r'[\p{L}\p{N}]', unicode: true), '').length;
    if (symbolCount / nonSpace.length > 0.5) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // This widget is used via the static show() method, not placed in a tree.
    return const SizedBox.shrink();
  }
}
