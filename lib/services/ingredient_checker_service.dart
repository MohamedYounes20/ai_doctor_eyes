import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/health_condition.dart';
import 'database_helper.dart';
import 'preferences_service.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IngredientStatus { safe, warning, danger }

/// Indicates how the final result was produced.
enum AnalysisSource {
  localScan,   // Offline keyword matching only
  aiAnalysis,  // Fresh Gemini API call
  aiCached,    // Retrieved from local DB cache
  fallback,    // Gemini timed-out/failed → fell back to local scan
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

  /// Bilingual summary fields (populated by Gemini; empty for local-only scans)
  final List<String> foundHarmful;
  final String reasonAr;
  final String analysisEn;

  const ProductAnalysisResult({
    required this.overallStatus,
    required this.details,
    required this.source,
    this.foundHarmful = const [],
    this.reasonAr = '',
    this.analysisEn = '',
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Hybrid Offline-Online Ingredient Checker Service
///
/// Priority chain:
///   1. Local keyword matching (zero-latency, always runs first)
///   2. Product-level AI analysis via Gemini (online only, cached in SQLite)
///   3. Fallback to local result if Gemini times-out or fails
class IngredientCheckerService {

  // ── Bilingual harmful-ingredient lists ──────────────────────────────────────

  static const Map<HealthCondition, List<String>> _harmfulKeywords = {
    HealthCondition.diabetes: [
      // English – comprehensive list
      'sugar', 'sucrose', 'glucose', 'corn syrup', 'dextrose', 'maltodextrin',
      'fructose', 'high fructose', 'syrup', 'honey', 'molasses',
      'agave', 'saccharose', 'lactose', 'maltose', 'invert sugar',
      'cane sugar', 'brown sugar', 'raw sugar', 'beet sugar',
      // Arabic (plain, diacritics stripped at match-time)
      'سكر', 'جلوكوز', 'فركتوز', 'شراب', 'مالتوديكسترين', 'سكروز',
      'ديكستروز', 'شراب ذرة', 'عسل', 'دبس', 'اجاف', 'لاكتوز',
      'مالتوز', 'سكر قصب', 'سكر بني',
    ],
    HealthCondition.hypertension: [
      // English
      'salt', 'sodium', 'nacl', 'msg', 'monosodium glutamate',
      'sodium chloride', 'sea salt', 'table salt', 'baking soda',
      'sodium bicarbonate', 'sodium nitrate', 'sodium nitrite',
      'disodium', 'sodium benzoate', 'sodium phosphate',
      // Arabic
      'ملح', 'صوديوم', 'كلوريد الصوديوم', 'غلوتامات أحادية الصوديوم',
      'ملح البحر', 'بيكربونات الصوديوم', 'نترات الصوديوم',
      'بنزوات الصوديوم',
    ],
    HealthCondition.glutenAllergy: [
      // English
      'wheat', 'barley', 'rye', 'gluten', 'malt', 'triticale',
      'semolina', 'durum', 'spelt', 'kamut', 'einkorn', 'emmer',
      'farro', 'bulgur', 'couscous', 'wheat starch', 'wheat flour',
      'wholemeal', 'breadcrumbs',
      // Arabic
      'قمح', 'شعير', 'جاودار', 'جلوتين', 'مالت', 'سميد',
      'دقيق القمح', 'نخالة القمح', 'كسكس', 'برغل',
    ],
    HealthCondition.nutAllergy: [
      // English
      'peanut', 'almond', 'cashew', 'walnut', 'hazelnut', 'pecan',
      'pistachio', 'macadamia', 'tree nut', 'nuts', 'nut',
      'groundnut', 'pine nut', 'brazil nut', 'chestnut',
      // Arabic
      'فول سوداني', 'لوز', 'كاجو', 'جوز', 'بندق', 'بكان',
      'فستق', 'ماكاديميا', 'مكسرات', 'صنوبر', 'كستناء',
    ],
  };

  // ── Nutrition-table noise patterns ──────────────────────────────────────────
  //
  // These patterns identify lines/segments that belong to the "Nutrition Facts"
  // panel rather than the "Ingredients" list.  We strip them BEFORE any
  // keyword matching or AI analysis to prevent false positives.

  static final List<RegExp> _nutritionLinePatterns = [
    // General nutrition-table headers
    RegExp(r'\bnutrition\s*facts?\b', caseSensitive: false),
    RegExp(r'\bsupplements?\s*facts?\b', caseSensitive: false),
    RegExp(r'\bvaleurs?\s*nutritives?\b', caseSensitive: false),
    RegExp(r'\bقيم غذائية\b', caseSensitive: false),
    RegExp(r'\bالجدول الغذائي\b', caseSensitive: false),
    // Macronutrient rows
    RegExp(r'\btotal\s+fat\b', caseSensitive: false),
    RegExp(r'\bsaturated\s+fat\b', caseSensitive: false),
    RegExp(r'\btrans\s+fat\b', caseSensitive: false),
    RegExp(r'\bunsaturated\s+fat\b', caseSensitive: false),
    RegExp(r'\bpolyunsaturated\b', caseSensitive: false),
    RegExp(r'\bmonounsaturated\b', caseSensitive: false),
    RegExp(r'\btotal\s+carbohydrate\b', caseSensitive: false),
    RegExp(r'\bdietary\s+fiber\b', caseSensitive: false),
    RegExp(r'\btotal\s+sugars?\b', caseSensitive: false),
    RegExp(r'\badded\s+sugars?\b', caseSensitive: false),
    RegExp(r'\bprotein\b', caseSensitive: false),         // standalone protein row
    RegExp(r'\bcalories?\b', caseSensitive: false),
    RegExp(r'\benergy\b', caseSensitive: false),
    // Micronutrient rows
    RegExp(r'\bsodium\s+\d', caseSensitive: false),       // "Sodium 140mg"
    RegExp(r'\bcalcium\b', caseSensitive: false),
    RegExp(r'\biron\b', caseSensitive: false),
    RegExp(r'\bpotassium\b', caseSensitive: false),
    RegExp(r'\bvitamin\s+[a-z]\b', caseSensitive: false),
    RegExp(r'\bvitamins?\b', caseSensitive: false),
    RegExp(r'\bminerals?\b', caseSensitive: false),
    RegExp(r'\bcholesterol\b', caseSensitive: false),
    // Arabic nutrition terms
    RegExp(r'\bسعرات\b', caseSensitive: false),
    RegExp(r'\bدهون\b', caseSensitive: false),
    RegExp(r'\bكربوهيدرات\b', caseSensitive: false),
    RegExp(r'\bبروتين\b', caseSensitive: false),
    RegExp(r'\bألياف\b', caseSensitive: false),
    RegExp(r'\bصوديوم\s+\d', caseSensitive: false),
    RegExp(r'\bكالسيوم\b', caseSensitive: false),
    // Percentage and daily-value markers
    RegExp(r'\bdaily\s+value\b', caseSensitive: false),
    RegExp(r'\b%\s*dv\b', caseSensitive: false),
    RegExp(r'\bالقيمة اليومية\b', caseSensitive: false),
    // Lines that are purely numbers / units  (e.g. "230 mg", "12 g", "5%")
    RegExp(r'^\s*[\d.,]+\s*(mg|g|mcg|iu|kcal|kj|%)\s*$', caseSensitive: false),
    // Serving-size lines
    RegExp(r'\bserving\s+size\b', caseSensitive: false),
    RegExp(r'\bservings?\s+per\b', caseSensitive: false),
    RegExp(r'\bحجم\s+الحصة\b', caseSensitive: false),
  ];

  // ── Internal helpers ─────────────────────────────────────────────────────────

  final DatabaseHelper _db = DatabaseHelper.instance;
  final PreferencesService _prefs = PreferencesService();

  /// Cleans raw OCR text by:
  ///  1. Splitting into lines
  ///  2. Discarding lines that match any nutrition-table pattern
  ///  3. Collapsing multiple whitespace
  ///  4. Removing spurious punctuation clusters
  String cleanOcrText(String raw) {
    final lines = raw.split(RegExp(r'[\r\n]+'));
    final kept = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Skip if this line is a nutrition-table noise line
      bool isNoisy = false;
      for (final pattern in _nutritionLinePatterns) {
        if (pattern.hasMatch(trimmed)) {
          isNoisy = true;
          break;
        }
      }
      if (isNoisy) continue;

      // Skip lines that are predominantly digits/special chars
      // (heuristic: >60 % of non-space chars are digits or punctuation)
      final nonSpace = trimmed.replaceAll(' ', '');
      if (nonSpace.isNotEmpty) {
        final numericCount =
            nonSpace.replaceAll(RegExp(r'[^0-9%.,:/()-]'), '').length;
        if (numericCount / nonSpace.length > 0.6) continue;
      }

      kept.add(trimmed);
    }

    // Collapse result and strip leading "Ingredients:" label (any language)
    String result = kept.join(', ');
    result = result.replaceAll(
        RegExp(r'^(ingredients?|المكونات|مكونات)\s*[:：،,]?\s*',
            caseSensitive: false),
        '');
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return result;
  }

  /// Tokenise the cleaned text into candidate ingredient tokens.
  List<String> _tokenize(String cleanedText) {
    if (cleanedText.isEmpty) return [];

    String s = cleanedText
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bو\b'), ',')       // Arabic "and"
        .replaceAll(RegExp(r'[.؛;]'), ',')
        .replaceAll('&', ',');

    return s
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.length > 1)
        .toList();
  }

  // ── Arabic text normalisation helpers ───────────────────────────────────────

  /// Strip Tashkeel (diacritics) from Arabic text.
  /// Unicode range \u064B–\u065F covers all common diacritics + shadda/sukun.
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');

  /// Unify common Alef variants → bare Alef (ا).
  static final RegExp _alefVariantsRegex = RegExp(r'[\u0622\u0623\u0624\u0625\u0627]');

  /// Normalise Arabic string: strip diacritics, unify Alef, convert Taa Marbuta (ة → ه).
  static String _normalizeArabic(String s) {
    String result = s.replaceAll(_tashkeelRegex, '');
    result = result.replaceAll(_alefVariantsRegex, '\u0627'); // → ا
    result = result.replaceAll('\u0629', '\u0647');           // ة → ه
    return result;
  }

  // ── OCR fuzzy-correction map ─────────────────────────────────────────────────

  /// Maps common OCR mis-reads to their correct ingredient name.
  /// Matching is done case-insensitively against each token.
  static const Map<String, String> _ocrCorrections = {
    'cucose'    : 'Glucose',
    'glucos'    : 'Glucose',
    'glucse'    : 'Glucose',
    'sucros'    : 'Sucrose',
    'surcose'   : 'Sucrose',
    'fructos'   : 'Fructose',
    'maltodextr': 'Maltodextrin',
    'dextros'   : 'Dextrose',
    'kcaine'    : '',   // gibberish → remove
    'kca'       : '',   // trailing calorie noise
  };

  /// Sanitize a single ingredient token for clean UI display:
  ///  - Apply fuzzy OCR corrections.
  ///  - Strip generic prefixes ("Ingredients", "Contains", etc.).
  ///  - Remove trailing lone numbers or short gibberish fragments.
  ///  - Returns empty string if the token should be discarded.
  String sanitizeIngredientName(String raw) {
    String s = raw.trim();

    // Strip leading generic prefixes
    s = s.replaceAll(
        RegExp(r'^(ingredients?|contains?|المكونات|مكونات)\s*[:：،,]?\s*',
            caseSensitive: false),
        '');

    // Remove trailing noise: lone digits, single chars, or short gibberish
    // e.g. "Sugar 0", "Salt kcaine"
    s = s.replaceAll(RegExp(r'\s+\d+\s*$'), '');         // trailing lone number
    s = s.replaceAll(RegExp(r'\s+[a-z]{1,3}\s*$',
        caseSensitive: false), '');                        // trailing short fragment

    s = s.trim();
    if (s.isEmpty) return '';

    // Apply fuzzy corrections (whole-string match on lower-cased token)
    final lower = s.toLowerCase();
    for (final entry in _ocrCorrections.entries) {
      if (lower.contains(entry.key)) {
        return entry.value; // '' means discard
      }
    }

    // Capitalise first letter for consistency
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Run the local keyword scan. Returns discovered harmful tokens and overall
  /// status without touching the network.
  ({IngredientStatus status, List<IngredientAnalysis> details})
      _runLocalScan(List<String> tokens, List<HealthCondition> conditions) {
    final details = <IngredientAnalysis>[];
    bool hasDanger = false;

    // Build keyword map; Arabic keywords are pre-normalised for fast comparison.
    final allKeywords = <String, HealthCondition>{};
    for (final c in conditions) {
      for (final kw in (_harmfulKeywords[c] ?? [])) {
        final normalised = _isArabic(kw)
            ? _normalizeArabic(kw)
            : kw.toLowerCase();
        allKeywords[normalised] = c;
      }
    }

    for (final token in tokens) {
      // Produce both a Latin-lower and an Arabic-normalised form of the token.
      final lowerToken   = token.toLowerCase();
      final arabicToken  = _normalizeArabic(token);
      bool matched = false;

      for (final entry in allKeywords.entries) {
        final kw = entry.key;
        // Use Arabic-normalised comparison for Arabic keywords, else Latin lower.
        final tokenForm = _isArabic(kw) ? arabicToken : lowerToken;
        if (tokenForm.contains(kw)) {
          final displayName = sanitizeIngredientName(token);
          details.add(IngredientAnalysis(
            ingredientName: displayName.isEmpty ? token : displayName,
            status: IngredientStatus.danger,
            reason:
                'Identified as harmful for ${entry.value.displayName} (local database).',
            severity: 'High',
          ));
          hasDanger = true;
          matched = true;
          break;
        }
      }

      if (!matched) {
        final displayName = sanitizeIngredientName(token);
        if (displayName.isNotEmpty) {
          details.add(IngredientAnalysis(
            ingredientName: displayName,
            status: IngredientStatus.safe,
            reason: 'Not found in local harmful-ingredients database.',
          ));
        }
      }
    }

    return (
      status: hasDanger ? IngredientStatus.danger : IngredientStatus.safe,
      details: details,
    );
  }

  /// Returns true if the string contains Arabic characters.
  static bool _isArabic(String s) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  /// Build a cache key from cleaned text + condition set.
  String _cacheKey(String cleanedText, List<HealthCondition> conditions) {
    final condStr = (conditions.map((c) => c.name).toList()..sort()).join('|');
    final raw = '$cleanedText::$condStr';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Extract the JSON object embedded in Gemini's free-text response.
  Map<String, dynamic>? _parseJson(String text) {
    try {
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) return jsonDecode(match.group(0)!);
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Main entry point.
  ///
  /// [rawOcrText]   – raw text from ML Kit
  /// [conditions]   – user health conditions
  ///
  /// Two-phase priority chain:
  ///   **Phase 1 – Local scan (mandatory, zero-latency)**
  ///     • Runs always, instantly.
  ///     • If harmful keyword found → return immediately. AI is NEVER called.
  ///
  ///   **Phase 2 – Gemini deep inspection (conditional)**
  ///     • Only triggered when Phase 1 result is Safe AND device is online.
  ///     • Gemini looks for complex harmful ingredients not in the local list.
  ///     • On timeout / error → return Safe (local confirmed nothing harmful).
  Future<ProductAnalysisResult> analyzeIngredients(
    String rawOcrText,
    List<HealthCondition> conditions,
  ) async {
    // ── Step 0: Clean the OCR text ─────────────────────────────────────────
    final cleanedText = cleanOcrText(rawOcrText);
    if (cleanedText.isEmpty) {
      return const ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: [],
        source: AnalysisSource.localScan,
      );
    }

    final tokens = _tokenize(cleanedText);

    // ── Phase 1: Local keyword scan (ALWAYS runs first) ────────────────────
    final localResult = _runLocalScan(tokens, conditions);

    // IMMEDIATE RETURN if local scan found anything harmful (warning OR danger).
    // Gemini is NEVER called when a local match is found — this eliminates
    // the "AI analysis timed out" message for products with obvious bad ingredients.
    if (localResult.status == IngredientStatus.danger ||
        localResult.status == IngredientStatus.warning) {
      return ProductAnalysisResult(
        overallStatus: localResult.status,
        details: localResult.details,
        source: AnalysisSource.localScan,
      );
    }

    // ── Phase 2: Gemini deep inspection (only when local is Safe + online) ─
    final connectivityList = await Connectivity().checkConnectivity();
    final isOnline = connectivityList.isNotEmpty &&
        !connectivityList.contains(ConnectivityResult.none);

    // Offline → local said safe, so the product is safe.
    if (!isOnline) {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.localScan,
      );
    }

    // Check product-level AI cache for this exact label.
    final key = _cacheKey(cleanedText, conditions);
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
      );
    }

    // No cache hit — call Gemini.
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // No API key → treat as safe (local already confirmed nothing)
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.localScan,
      );
    }

    final conditionNames = conditions.map((c) => c.displayName).join(' and ');
    String ageContext = '';
    final yob = await _prefs.getYearOfBirth();
    if (yob != null) {
      ageContext = ' (patient age: ${DateTime.now().year - yob})';
    }

    final prompt = '''
Task: Analyze the provided "Ingredients" text only.

Internal Translation: Identify both Arabic and English ingredients and treat them as one entity.

Strict Rule: IGNORE all nutritional values, percentages, and anything related to the Nutrition Facts table.

Health Check: Identify ingredients that are harmful for a person with the following condition(s): $conditionNames$ageContext.

Note: Basic harmful keywords have already been screened locally. Focus on complex, compound, or less-obvious harmful ingredients.

Output: Return ONLY a raw JSON object with no markdown fences:
{"status": "warning" or "safe", "found_harmful": ["..."], "reason_ar": "سبب مختصر بالعربية", "analysis_en": "Short English analysis"}

Ingredients text:
$cleanedText
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      final responseText = response.text;
      if (responseText != null) {
        final json = _parseJson(responseText);
        if (json != null &&
            json.containsKey('status') &&
            json.containsKey('found_harmful')) {
          final aiStatus = _statusFromString(json['status'] as String? ?? 'safe');
          final foundHarmful =
              (json['found_harmful'] as List? ?? []).cast<String>();
          final reasonAr = json['reason_ar'] as String? ?? '';
          final analysisEn = json['analysis_en'] as String? ?? '';

          final mergedDetails =
              _mergeDetails(localResult.details, foundHarmful, aiStatus);

          // Cache the result so offline re-scans of the same product are instant.
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
          );
        }
      }
    } on TimeoutException {
      // Timeout — local scan was safe, so return safe with fallback source.
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.fallback,
      );
    } catch (_) {
      return ProductAnalysisResult(
        overallStatus: IngredientStatus.safe,
        details: localResult.details,
        source: AnalysisSource.fallback,
      );
    }

    // Unparseable AI response — local said safe, so keep it safe.
    return ProductAnalysisResult(
      overallStatus: IngredientStatus.safe,
      details: localResult.details,
      source: AnalysisSource.fallback,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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
  /// AI-flagged items that weren't caught locally are added as danger.
  List<IngredientAnalysis> _mergeDetails(
    List<IngredientAnalysis> localDetails,
    List<String> aiHarmful,
    IngredientStatus aiStatus,
  ) {
    if (aiHarmful.isEmpty || aiStatus != IngredientStatus.danger) {
      return localDetails;
    }

    final merged = List<IngredientAnalysis>.from(localDetails);
    final existing = localDetails.map((d) => d.ingredientName.toLowerCase()).toSet();

    for (final h in aiHarmful) {
      if (!existing.any((e) => e.contains(h.toLowerCase()) || h.toLowerCase().contains(e))) {
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
