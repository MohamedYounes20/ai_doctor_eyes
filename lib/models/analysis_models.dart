// ═══════════════════════════════════════════════════════════════════════════════
// Analysis Models
//
// Enums and data classes used throughout the analysis pipeline:
//   IngredientCheckerService → HealthAnalyzer → UI Screens
//
// Extracted from ingredient_checker_service.dart for clean architecture
// (models should not live in service files).
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IngredientStatus { safe, trace, warning, danger }

/// Indicates how the final result was produced.
enum AnalysisSource {
  localScan,   // Offline keyword matching only
  aiAnalysis,  // Fresh gemini API call
  aiCached,    // Retrieved from local DB cache
  fallback,    // gemini timed-out/failed → fell back to local scan
}

// ─── Models ───────────────────────────────────────────────────────────────────

class IngredientAnalysis {
  final String ingredientName;
  final IngredientStatus status;
  final String reason;
  final String? severity; // Low | Medium | High
  final bool isMedicalProfileHit;
  final double positionRatio;

  const IngredientAnalysis({
    required this.ingredientName,
    required this.status,
    required this.reason,
    this.severity,
    this.isMedicalProfileHit = false,
    this.positionRatio = 0.0,
  });
}

class ProductAnalysisResult {
  final IngredientStatus overallStatus;
  final List<IngredientAnalysis> details;
  final AnalysisSource source;

  /// Bilingual summary fields (populated by gemini; empty for local-only scans)
  final List<String> foundHarmful;
  final String reasonAr;
  final String analysisEn;

  /// True when garbled Arabic was guessed – UI should show a warning note.
  final bool partialArabicWarning;

  /// True if the local scan found harmful ingredients before AI was called/failed
  final bool localFoundHarmful;

  const ProductAnalysisResult({
    required this.overallStatus,
    required this.details,
    required this.source,
    this.foundHarmful = const [],
    this.reasonAr = '',
    this.analysisEn = '',
    this.partialArabicWarning = false,
    this.localFoundHarmful = false,
  });
}
