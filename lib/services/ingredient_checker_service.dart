import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/health_condition.dart';
import '../logic/extractor/ocr_cleaner.dart';
import '../logic/transformer/ingredient_transformer.dart';
import '../logic/analyzer/health_analyzer.dart';
import 'database_helper.dart';
import 'preferences_service.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IngredientStatus { safe, warning, danger }

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

  const IngredientAnalysis({
    required this.ingredientName,
    required this.status,
    required this.reason,
    this.severity,
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

// ─── Service Orchestrator ───────────────────────────────────────────────────

/// Hybrid Offline-Online Ingredient Checker Service (Orchestrator)
///
/// Strict pipeline: **Extract → Transform → Analyze**
class IngredientCheckerService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final PreferencesService _prefs = PreferencesService();

  final OcrCleaner _extractor = OcrCleaner();
  final IngredientTransformer _transformer = IngredientTransformer();
  final HealthAnalyzer _analyzer = HealthAnalyzer();

  /// Main entry point – strict **Extract → Transform → Analyze** pipeline.
  Future<ProductAnalysisResult> analyzeIngredients(
    String rawOcrText,
    List<HealthCondition> conditions,
  ) async {
    // ═══════ EXTRACT ═══════
    final cleanedText = _extractor.cleanOcrText(rawOcrText);
    if (cleanedText.isEmpty) {
      return const ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: [],
        source: AnalysisSource.localScan,
        localFoundHarmful: false,
      );
    }

    // ═══════ TRANSFORM ═══════
    final transformResult = _transformer.transform(cleanedText, conditions);
    final textForAnalysis = transformResult.mergedRawText;
    final isHeavyArabic = transformResult.isHeavyArabic;

    // ═══════ ANALYZE — Phase 1: Local scan (ALWAYS first) ═══════
    final localResult = _analyzer.analyzeLocal(transformResult.uniqueCanonicalNames, conditions);

    // IMMEDIATE RETURN if local scan found anything harmful.
    // gemini is NEVER called → eliminates "AI analysis timed out" message.
    if (localResult.status == IngredientStatus.danger ||
        localResult.status == IngredientStatus.warning) {
      return ProductAnalysisResult(
        overallStatus: localResult.status,
        details: localResult.details,
        source: AnalysisSource.localScan,
        partialArabicWarning:
            isHeavyArabic && transformResult.usedArabicGuess,
        localFoundHarmful: true,
      );
    }

    // ═══════ ANALYZE — Phase 2: gemini (only when Safe + online) ═══════
    final connectivityList = await Connectivity().checkConnectivity();
    final isOnline = connectivityList.isNotEmpty &&
        !connectivityList.contains(ConnectivityResult.none);

    if (!isOnline) {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.localScan,
        partialArabicWarning:
            isHeavyArabic && transformResult.usedArabicGuess,
        localFoundHarmful: false, // Since this branch means local scan was safe
      );
    }

    // Check AI cache.
    final key = _cacheKey(textForAnalysis, conditions);
    final cached = await _db.getCachedProductAnalysis(key);
    if (cached != null) {
      final status = _statusFromString(cached['status'] as String);
      final harmful = (jsonDecode(cached['found_harmful'] as String) as List)
          .cast<String>();
      return ProductAnalysisResult(
        overallStatus: status,
        details: _mergeDetails(localResult.details, harmful, status),
        source: AnalysisSource.aiCached,
        foundHarmful: harmful,
        reasonAr: cached['reason_ar'] as String? ?? '',
        analysisEn: cached['analysis_en'] as String? ?? '',
        localFoundHarmful: false, // Since this branch means local scan was safe
      );
    }

    // Call gemini.
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.localScan,
        localFoundHarmful: false,
      );
    }

    final conditionNames = conditions.map((c) => c.displayName).join(' and ');
    String ageContext = '';
    final yob = await _prefs.getYearOfBirth();
    if (yob != null) {
      ageContext = ' (patient age: ${DateTime.now().year - yob})';
    }
    final conditionDescriptions = conditions
        .map((c) => '${c.displayName}: ${c.description}')
        .join('; ');

    final prompt = '''
Task: Analyze the provided "Ingredients" text only.

Internal Translation: Identify both Arabic and English ingredients and treat them as one entity.

Arabic OCR Note: If Arabic text appears garbled, partially recognized, or contains character errors, cross-reference it with any English text present on the same label. Also compare garbled Arabic tokens against this list of common harmful ingredients: سكر، جلوكوز، فركتوز، ملح، صوديوم، قمح، جلوتين، فول سوداني، لوز، مالتوديكسترين. Attempt to infer the correct ingredient rather than discarding garbled text.

Strict Rule: IGNORE all nutritional values, percentages, and anything related to the Nutrition Facts table.

Personalized Risk: This patient has $conditionNames$ageContext. Condition details: $conditionDescriptions. Tailor the risk assessment specifically for this patient profile.

Note: Basic harmful keywords have already been screened locally. Focus on complex, compound, or less-obvious harmful ingredients.

Output: Return ONLY a raw JSON object with no markdown fences. Do not include any introductory text. Keep analysis brief to avoid truncation:
{"status": "warning" or "safe", "found_harmful": ["..."], "reason_ar": "سبب مختصر بالعربية", "analysis_en": "Short English analysis"}

Ingredients text:
$textForAnalysis
''';

    // ── Direct REST call to Gemini v1beta ─────────────────────────────────
    const geminiEndpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

    try {
      final uri = Uri.parse('$geminiEndpoint?key=$apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
        },
      });

      final httpResponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      if (httpResponse.statusCode == 200) {
        final decoded =
            jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List?;
        final content =
            candidates?.isNotEmpty == true
                ? candidates![0]['content'] as Map<String, dynamic>?
                : null;
        final parts = content?['parts'] as List?;
        final responseText = parts?.isNotEmpty == true
            ? parts![0]['text'] as String?
            : null;

        if (responseText != null) {
          final json = _parseJson(responseText);
          if (json != null &&
              json.containsKey('status') &&
              json.containsKey('found_harmful')) {
            final aiStatus =
                _statusFromString(json['status'] as String? ?? 'safe');
            final foundHarmful =
                (json['found_harmful'] as List? ?? []).cast<String>();
            final reasonAr = json['reason_ar'] as String? ?? '';
            final analysisEn = json['analysis_en'] as String? ?? '';

            final mergedDetails =
                _mergeDetails(localResult.details, foundHarmful, aiStatus);

            await _db.cacheProductAnalysis(
              key: key,
              conditions: conditionNames,
              status: _statusToString(aiStatus),
              foundHarmful: jsonEncode(foundHarmful),
              reasonAr: reasonAr,
              analysisEn: analysisEn,
            );

            return ProductAnalysisResult(
              overallStatus: aiStatus,
              details: mergedDetails,
              source: AnalysisSource.aiAnalysis,
              foundHarmful: foundHarmful,
              reasonAr: reasonAr,
              analysisEn: analysisEn,
              localFoundHarmful: false,
            );
          }
        }
      }
    } on TimeoutException {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.fallback,
        localFoundHarmful: false,
      );
    } catch (_) {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.fallback,
        localFoundHarmful: false,
      );
    }

    return ProductAnalysisResult(
      overallStatus: IngredientStatus.safe,
      details: localResult.details,
      source: AnalysisSource.fallback,
      localFoundHarmful: false,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _cacheKey(String cleanedText, List<HealthCondition> conditions) {
    final condStr = (conditions.map((c) => c.name).toList()..sort()).join('|');
    final raw = '$cleanedText::$condStr';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Map<String, dynamic>? _parseJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start != -1) {
      String slice;
      if (end != -1 && end > start) {
        slice = text.substring(start, end + 1).trim();
      } else {
        // Truncated response: manually append the closing brace
        slice = '${text.substring(start).trim()}}';
      }

      try {
        return jsonDecode(slice) as Map<String, dynamic>;
      } catch (e) {
        // ignore: avoid_print
        print('[IngredientCheckerService] _parseJson failed.\nSlice:\n$slice\nError: $e');
        return null;
      }
    }
    
    // Fallback if no brackets found (unlikely)
    try {
      return jsonDecode(text.trim()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  IngredientStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'danger':
      case 'warning':
        return IngredientStatus.danger;
      default:
        return IngredientStatus.safe;
    }
  }

  String _statusToString(IngredientStatus s) =>
      s == IngredientStatus.danger ? 'danger' : 'safe';

  /// Merge local keyword details with AI-found harmful list.
  List<IngredientAnalysis> _mergeDetails(
    List<IngredientAnalysis> localDetails,
    List<String> aiHarmful,
    IngredientStatus aiStatus,
  ) {
    if (aiHarmful.isEmpty || aiStatus != IngredientStatus.danger) {
      return localDetails;
    }

    final merged = List<IngredientAnalysis>.from(localDetails);

    for (final h in aiHarmful) {
      final hLower = h.toLowerCase();
      
      // Find if this ingredient already exists in the local details
      final matchIndex = merged.indexWhere((d) {
        final dLower = d.ingredientName.toLowerCase();
        return dLower.contains(hLower) || hLower.contains(dLower);
      });

      if (matchIndex != -1) {
        // If it exists but was marked safe by the local scan, OVERRIDE it to danger
        if (merged[matchIndex].status != IngredientStatus.danger) {
          merged[matchIndex] = IngredientAnalysis(
            ingredientName: merged[matchIndex].ingredientName, // keep original name
            status: IngredientStatus.danger,
            reason: 'Identified as harmful by AI analysis.',
            severity: 'High',
          );
        }
      } else {
        // If it wasn't caught locally at all, add it as a new danger item
        merged.add(IngredientAnalysis(
          ingredientName: h,
          status: IngredientStatus.danger,
          reason: 'Identified as harmful by AI analysis.',
          severity: 'High',
        ));
      }
    }
    return merged;
  }
}
