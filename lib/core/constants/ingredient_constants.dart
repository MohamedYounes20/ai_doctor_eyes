import '../../../models/health_condition.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Ingredient Constants
//
// All static maps and lists used by IngredientCheckerService, extracted here
// for clean architecture and reusability.
// ═══════════════════════════════════════════════════════════════════════════════

/// Bilingual harmful-ingredient keyword lists, grouped by health condition.
const Map<HealthCondition, List<String>> harmfulKeywords = {
  HealthCondition.diabetes: [
    'sugar', 'sucrose', 'glucose', 'corn syrup', 'dextrose', 'maltodextrin',
    'fructose', 'high fructose', 'syrup', 'honey', 'molasses',
    'agave', 'saccharose', 'lactose', 'maltose', 'invert sugar',
    'cane sugar', 'brown sugar', 'raw sugar', 'beet sugar',
    'سكر', 'جلوكوز', 'فركتوز', 'شراب', 'مالتوديكسترين', 'سكروز',
    'ديكستروز', 'شراب ذرة', 'عسل', 'دبس', 'اجاف', 'لاكتوز',
    'مالتوز', 'سكر قصب', 'سكر بني',
  ],
  HealthCondition.hypertension: [
    'salt', 'sodium', 'nacl', 'msg', 'monosodium glutamate',
    'sodium chloride', 'sea salt', 'table salt', 'baking soda',
    'sodium bicarbonate', 'sodium nitrate', 'sodium nitrite',
    'disodium', 'sodium benzoate', 'sodium phosphate',
    'ملح', 'صوديوم', 'كلوريد الصوديوم', 'غلوتامات أحادية الصوديوم',
    'ملح البحر', 'بيكربونات الصوديوم', 'نترات الصوديوم',
    'بنزوات الصوديوم',
  ],
  HealthCondition.glutenAllergy: [
    'wheat', 'barley', 'rye', 'gluten', 'malt', 'triticale',
    'semolina', 'durum', 'spelt', 'kamut', 'einkorn', 'emmer',
    'farro', 'bulgur', 'couscous', 'wheat starch', 'wheat flour',
    'wholemeal', 'breadcrumbs',
    'قمح', 'شعير', 'جاودار', 'جلوتين', 'مالت', 'سميد',
    'دقيق القمح', 'نخالة القمح', 'كسكس', 'برغل',
  ],
  HealthCondition.nutAllergy: [
    'peanut', 'almond', 'cashew', 'walnut', 'hazelnut', 'pecan',
    'pistachio', 'macadamia', 'tree nut', 'nuts', 'nut',
    'groundnut', 'pine nut', 'brazil nut', 'chestnut',
    'فول سوداني', 'لوز', 'كاجو', 'جوز', 'بندق', 'بكان',
    'فستق', 'ماكاديميا', 'مكسرات', 'صنوبر', 'كستناء',
  ],
};

/// Canonical Display Name Map.
/// Every harmful keyword → its clean, official UI display name.
const Map<String, String> canonicalDisplayName = {
  // Diabetes – English
  'sugar': 'Sugar', 'sucrose': 'Sucrose', 'glucose': 'Glucose',
  'corn syrup': 'Corn Syrup', 'dextrose': 'Dextrose',
  'maltodextrin': 'Maltodextrin', 'fructose': 'Fructose',
  'high fructose': 'High Fructose Corn Syrup', 'syrup': 'Syrup',
  'honey': 'Honey', 'molasses': 'Molasses', 'agave': 'Agave',
  'saccharose': 'Saccharose', 'lactose': 'Lactose',
  'maltose': 'Maltose', 'invert sugar': 'Invert Sugar',
  'cane sugar': 'Cane Sugar', 'brown sugar': 'Brown Sugar',
  'raw sugar': 'Raw Sugar', 'beet sugar': 'Beet Sugar',
  // Diabetes – Arabic
  'سكر': 'سكر', 'جلوكوز': 'جلوكوز', 'فركتوز': 'فركتوز',
  'شراب': 'شراب', 'مالتوديكسترين': 'مالتوديكسترين',
  'سكروز': 'سكروز', 'ديكستروز': 'ديكستروز',
  'شراب ذرة': 'شراب ذرة', 'عسل': 'عسل', 'دبس': 'دبس',
  'اجاف': 'أجاف', 'لاكتوز': 'لاكتوز', 'مالتوز': 'مالتوز',
  'سكر قصب': 'سكر قصب', 'سكر بني': 'سكر بني',
  // Hypertension – English
  'salt': 'Salt', 'sodium': 'Sodium', 'nacl': 'Sodium Chloride',
  'msg': 'MSG', 'monosodium glutamate': 'Monosodium Glutamate',
  'sodium chloride': 'Sodium Chloride', 'sea salt': 'Sea Salt',
  'table salt': 'Table Salt', 'baking soda': 'Baking Soda',
  'sodium bicarbonate': 'Sodium Bicarbonate',
  'sodium nitrate': 'Sodium Nitrate',
  'sodium nitrite': 'Sodium Nitrite', 'disodium': 'Disodium',
  'sodium benzoate': 'Sodium Benzoate',
  'sodium phosphate': 'Sodium Phosphate',
  // Hypertension – Arabic
  'ملح': 'ملح', 'صوديوم': 'صوديوم',
  'كلوريد الصوديوم': 'كلوريد الصوديوم',
  'غلوتامات أحادية الصوديوم': 'غلوتامات أحادية الصوديوم',
  'ملح البحر': 'ملح البحر',
  'بيكربونات الصوديوم': 'بيكربونات الصوديوم',
  'نترات الصوديوم': 'نترات الصوديوم',
  'بنزوات الصوديوم': 'بنزوات الصوديوم',
  // Gluten – English
  'wheat': 'Wheat', 'barley': 'Barley', 'rye': 'Rye',
  'gluten': 'Gluten', 'malt': 'Malt', 'triticale': 'Triticale',
  'semolina': 'Semolina', 'durum': 'Durum', 'spelt': 'Spelt',
  'kamut': 'Kamut', 'einkorn': 'Einkorn', 'emmer': 'Emmer',
  'farro': 'Farro', 'bulgur': 'Bulgur', 'couscous': 'Couscous',
  'wheat starch': 'Wheat Starch', 'wheat flour': 'Wheat Flour',
  'wholemeal': 'Wholemeal', 'breadcrumbs': 'Breadcrumbs',
  // Gluten – Arabic
  'قمح': 'قمح', 'شعير': 'شعير', 'جاودار': 'جاودار',
  'جلوتين': 'جلوتين', 'مالت': 'مالت', 'سميد': 'سميد',
  'دقيق القمح': 'دقيق القمح', 'نخالة القمح': 'نخالة القمح',
  'كسكس': 'كسكس', 'برغل': 'برغل',
  // Nut – English
  'peanut': 'Peanut', 'almond': 'Almond', 'cashew': 'Cashew',
  'walnut': 'Walnut', 'hazelnut': 'Hazelnut', 'pecan': 'Pecan',
  'pistachio': 'Pistachio', 'macadamia': 'Macadamia',
  'tree nut': 'Tree Nut', 'nuts': 'Nuts', 'nut': 'Nut',
  'groundnut': 'Groundnut', 'pine nut': 'Pine Nut',
  'brazil nut': 'Brazil Nut', 'chestnut': 'Chestnut',
  // Nut – Arabic
  'فول سوداني': 'فول سوداني', 'لوز': 'لوز', 'كاجو': 'كاجو',
  'جوز': 'جوز', 'بندق': 'بندق', 'بكان': 'بكان',
  'فستق': 'فستق', 'ماكاديميا': 'ماكاديميا',
  'مكسرات': 'مكسرات', 'صنوبر': 'صنوبر', 'كستناء': 'كستناء',
};

/// OCR fuzzy-correction → canonical ingredient name.
/// Maps common OCR mis-reads to their correct canonical name.
const Map<String, String> ocrCorrections = {
  // Glucose variants
  'cucose': 'Glucose', 'glucos': 'Glucose', 'glucse': 'Glucose',
  'giucose': 'Glucose', 'gluccse': 'Glucose',
  'cose syrup': 'Glucose Syrup', 'glucose syrup': 'Glucose Syrup',
  // Sucrose variants
  'sucros': 'Sucrose', 'surcose': 'Sucrose',
  // Sugar variants
  'suger': 'Sugar', 'sugr': 'Sugar', 'sug ar': 'Sugar',
  'ngredients sugar': 'Sugar',
  // Fructose variants
  'fructos': 'Fructose', 'friuctose': 'Fructose',
  // Maltodextrin variants
  'maltodextr': 'Maltodextrin', 'maltodextri': 'Maltodextrin',
  'maltodextin': 'Maltodextrin',
  // Dextrose
  'dextros': 'Dextrose', 'dextrse': 'Dextrose',
  // Salt
  'sait': 'Salt', 'sa1t': 'Salt',
  // Sodium
  'sodlum': 'Sodium', 'sodiurn': 'Sodium',
  // Wheat
  'whea t': 'Wheat', 'wheot': 'Wheat',
  // Noise → discard
  'kcaine': '', 'kca': '',
};

/// Nutrition-table noise patterns.
/// Lines matching any of these are stripped before analysis.
final List<RegExp> nutritionLinePatterns = [
  RegExp(r'\bnutrition\s*facts?\b', caseSensitive: false),
  RegExp(r'\bsupplements?\s*facts?\b', caseSensitive: false),
  RegExp(r'\bvaleurs?\s*nutritives?\b', caseSensitive: false),
  RegExp(r'\bقيم غذائية\b', caseSensitive: false),
  RegExp(r'\bالجدول الغذائي\b', caseSensitive: false),
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
  RegExp(r'\bprotein\b', caseSensitive: false),
  RegExp(r'\bcalories?\b', caseSensitive: false),
  RegExp(r'\benergy\b', caseSensitive: false),
  RegExp(r'\bsodium\s+\d', caseSensitive: false),
  RegExp(r'\bcalcium\b', caseSensitive: false),
  RegExp(r'\biron\b', caseSensitive: false),
  RegExp(r'\bpotassium\b', caseSensitive: false),
  RegExp(r'\bvitamin\s+[a-z]\b', caseSensitive: false),
  RegExp(r'\bvitamins?\b', caseSensitive: false),
  RegExp(r'\bminerals?\b', caseSensitive: false),
  RegExp(r'\bcholesterol\b', caseSensitive: false),
  RegExp(r'\bسعرات\b', caseSensitive: false),
  RegExp(r'\bدهون\b', caseSensitive: false),
  RegExp(r'\bكربوهيدرات\b', caseSensitive: false),
  RegExp(r'\bبروتين\b', caseSensitive: false),
  RegExp(r'\bألياف\b', caseSensitive: false),
  RegExp(r'\bصوديوم\s+\d', caseSensitive: false),
  RegExp(r'\bكالسيوم\b', caseSensitive: false),
  RegExp(r'\bdaily\s+value\b', caseSensitive: false),
  RegExp(r'\b%\s*dv\b', caseSensitive: false),
  RegExp(r'\bالقيمة اليومية\b', caseSensitive: false),
  RegExp(r'^\s*[\d.,]+\s*(mg|g|mcg|iu|kcal|kj|%)\s*$', caseSensitive: false),
  RegExp(r'\bserving\s+size\b', caseSensitive: false),
  RegExp(r'\bservings?\s+per\b', caseSensitive: false),
  RegExp(r'\bحجم\s+الحصة\b', caseSensitive: false),
];

/// Non-ingredient packaging text that should be discarded.
const List<String> nonIngredientBlacklist = [
  'keep in a clean', 'net weight', 'net wt', 'batch no', 'batch number',
  'store in', 'ingredients:', 'best before', 'best by', 'exp date',
  'expiry date', 'use by', 'manufactured by', 'product of', 'produced by',
  'see cap', 'shake well', 'keep refrigerated', 'serving suggestion',
  'may contain traces', 'for best quality', 'once opened',
  'protect from', 'keep away', 'distributed by',
  'يحفظ في', 'الوزن الصافي', 'رقم التشغيلة', 'تاريخ الانتهاء',
  'صنع في', 'انتاج', 'تاريخ الانتاج', 'يستخدم قبل', 'الشركة المصنعة',
  'قد يحتوي على', 'بعد الفتح', 'رقم الشهادة',
];
