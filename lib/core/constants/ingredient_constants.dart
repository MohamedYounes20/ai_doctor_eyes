import '../../models/health_condition.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Ingredient Constants  (English / Latin only)
//
// All static maps and lists used by IngredientCheckerService, extracted here
// for clean architecture and reusability.
//
// ARCHITECTURE: Shared categories prevent duplicate-key errors when multiple
// conditions reference the same ingredient. Each ingredient key appears in
// exactly ONE shared or condition-specific map, then all are composed via
// spread (...) into the global `canonicalDisplayName` map.
// ═══════════════════════════════════════════════════════════════════════════════

/// Harmful-ingredient keyword lists, grouped by health condition (English only).
const Map<HealthCondition, List<String>> harmfulKeywords = {
  HealthCondition.diabetes: [
    'sugar', 'sucrose', 'glucose', 'corn syrup', 'dextrose', 'maltodextrin',
    'fructose', 'high fructose', 'syrup', 'honey', 'molasses',
    'agave', 'saccharose', 'lactose', 'maltose', 'invert sugar',
    'cane sugar', 'brown sugar', 'raw sugar', 'beet sugar',
  ],
  HealthCondition.hypertension: [
    'salt', 'sodium', 'nacl', 'msg', 'monosodium glutamate',
    'sodium chloride', 'sea salt', 'table salt', 'baking soda',
    'sodium bicarbonate', 'sodium nitrate', 'sodium nitrite',
    'disodium', 'sodium benzoate', 'sodium phosphate',
  ],
  HealthCondition.glutenAllergy: [
    'wheat', 'barley', 'rye', 'gluten', 'malt', 'triticale',
    'semolina', 'durum', 'spelt', 'kamut', 'einkorn', 'emmer',
    'farro', 'bulgur', 'couscous', 'wheat starch', 'wheat flour',
    'wholemeal', 'breadcrumbs',
  ],
  HealthCondition.nutAllergy: [
    'peanut', 'almond', 'cashew', 'walnut', 'hazelnut', 'pecan',
    'pistachio', 'macadamia', 'tree nut', 'nuts', 'nut',
    'groundnut', 'pine nut', 'brazil nut', 'chestnut',
  ],

  // ── New conditions ───────────────────────────────────────────────────────

  HealthCondition.lactoseIntolerance: [
    'lactose', 'milk', 'cream', 'cheese', 'whey', 'casein', 'butter',
    'yogurt', 'ghee', 'buttermilk', 'milk powder', 'skim milk',
    'whole milk', 'milk solids', 'milk protein', 'curds',
    'half and half', 'sour cream', 'condensed milk', 'evaporated milk',
    'lactalbumin', 'lactoglobulin',
  ],
  HealthCondition.vegan: [
    'meat', 'chicken', 'beef', 'pork', 'fish', 'egg', 'eggs',
    'gelatin', 'gelatine', 'honey', 'whey', 'casein', 'lard',
    'tallow', 'shellac', 'carmine', 'cochineal', 'isinglass',
    'pepsin', 'rennet', 'albumin', 'bone char', 'collagen',
    'lanolin', 'milk', 'cream', 'butter', 'cheese', 'yogurt',
    'anchovy', 'anchovies', 'squid', 'shrimp',
  ],
  HealthCondition.keto: [
    'sugar', 'flour', 'corn starch', 'rice', 'pasta', 'bread',
    'potato starch', 'dextrin', 'maltodextrin', 'corn syrup',
    'high fructose corn syrup', 'wheat flour', 'rice flour',
    'tapioca starch', 'modified starch', 'dextrose', 'sucrose',
    'glucose syrup', 'honey', 'molasses', 'agave', 'maple syrup',
    'brown sugar', 'cane sugar', 'oat flour', 'barley malt',
  ],
  HealthCondition.lowFodmap: [
    'garlic', 'onion', 'apple', 'pear', 'honey', 'wheat', 'rye',
    'milk', 'cream', 'agave', 'sorbitol', 'mannitol', 'xylitol',
    'inulin', 'chicory root', 'artichoke', 'asparagus',
    'cauliflower', 'mushroom', 'watermelon', 'mango', 'fig',
    'dried fruit', 'fruit juice concentrate', 'high fructose corn syrup',
    'fructo-oligosaccharides', 'fos', 'gos',
  ],
  HealthCondition.shellfishAllergy: [
    'shrimp', 'crab', 'lobster', 'crayfish', 'prawn', 'shellfish',
    'oyster', 'mussel', 'clam', 'scallop', 'squid', 'octopus',
    'abalone', 'snail', 'crawfish', 'langoustine', 'cockle',
    'whelk', 'sea urchin', 'crustacean', 'mollusk', 'mollusc',
  ],
  HealthCondition.soyAllergy: [
    'soy', 'soybean', 'soya', 'soy lecithin', 'soy protein',
    'soy sauce', 'tofu', 'edamame', 'miso', 'tempeh', 'natto',
    'soy oil', 'soybean oil', 'soy flour', 'soy milk',
    'soy isolate', 'hydrolyzed soy', 'textured soy protein',
    'soy concentrate',
  ],
};

// ═══════════════════════════════════════════════════════════════════════════════
// Shared Display Name Categories
//
// Ingredients that appear in multiple conditions are grouped here ONCE.
// The global `canonicalDisplayName` map is composed by spreading these.
// ═══════════════════════════════════════════════════════════════════════════════

/// Sugars & sweeteners — shared across Diabetes, Keto, Low FODMAP
const Map<String, String> _sharedSugars = {
  'sugar': 'Sugar', 'sucrose': 'Sucrose', 'glucose': 'Glucose',
  'corn syrup': 'Corn Syrup', 'dextrose': 'Dextrose',
  'maltodextrin': 'Maltodextrin', 'fructose': 'Fructose',
  'high fructose': 'High Fructose Corn Syrup', 'syrup': 'Syrup',
  'honey': 'Honey', 'molasses': 'Molasses', 'agave': 'Agave',
  'saccharose': 'Saccharose', 'lactose': 'Lactose',
  'maltose': 'Maltose', 'invert sugar': 'Invert Sugar',
  'cane sugar': 'Cane Sugar', 'brown sugar': 'Brown Sugar',
  'raw sugar': 'Raw Sugar', 'beet sugar': 'Beet Sugar',
};

/// Dairy — shared across Lactose Intolerance, Vegan, Low FODMAP
const Map<String, String> _sharedDairy = {
  'milk': 'Milk', 'cream': 'Cream', 'cheese': 'Cheese',
  'whey': 'Whey', 'casein': 'Casein', 'butter': 'Butter',
  'yogurt': 'Yogurt',
};

/// Grains — shared across Gluten Allergy, Keto, Low FODMAP
const Map<String, String> _sharedGrains = {
  'wheat': 'Wheat', 'wheat flour': 'Wheat Flour', 'rye': 'Rye',
};

/// Seafood — shared across Vegan, Shellfish Allergy
const Map<String, String> _sharedSeafood = {
  'shrimp': 'Shrimp', 'squid': 'Squid',
};

/// Canonical Display Name Map.
/// Every harmful keyword → its clean, official UI display name.
///
/// Composed by spreading shared categories first, then condition-specific
/// entries. This guarantees every key appears exactly once.
const Map<String, String> canonicalDisplayName = {
  // ── Shared categories (ingredients appearing in 2+ conditions) ────────────
  ..._sharedSugars,
  ..._sharedDairy,
  ..._sharedGrains,
  ..._sharedSeafood,

  // ── Hypertension ─────────────────────────────────────────────────────────
  'salt': 'Salt', 'sodium': 'Sodium', 'nacl': 'Sodium Chloride',
  'msg': 'MSG', 'monosodium glutamate': 'Monosodium Glutamate',
  'sodium chloride': 'Sodium Chloride', 'sea salt': 'Sea Salt',
  'table salt': 'Table Salt', 'baking soda': 'Baking Soda',
  'sodium bicarbonate': 'Sodium Bicarbonate',
  'sodium nitrate': 'Sodium Nitrate',
  'sodium nitrite': 'Sodium Nitrite', 'disodium': 'Disodium',
  'sodium benzoate': 'Sodium Benzoate',
  'sodium phosphate': 'Sodium Phosphate',

  // ── Gluten (unique entries only, shared grains already spread) ────────────
  'barley': 'Barley',
  'gluten': 'Gluten', 'malt': 'Malt', 'triticale': 'Triticale',
  'semolina': 'Semolina', 'durum': 'Durum', 'spelt': 'Spelt',
  'kamut': 'Kamut', 'einkorn': 'Einkorn', 'emmer': 'Emmer',
  'farro': 'Farro', 'bulgur': 'Bulgur', 'couscous': 'Couscous',
  'wheat starch': 'Wheat Starch',
  'wholemeal': 'Wholemeal', 'breadcrumbs': 'Breadcrumbs',

  // ── Nut ──────────────────────────────────────────────────────────────────
  'peanut': 'Peanut', 'almond': 'Almond', 'cashew': 'Cashew',
  'walnut': 'Walnut', 'hazelnut': 'Hazelnut', 'pecan': 'Pecan',
  'pistachio': 'Pistachio', 'macadamia': 'Macadamia',
  'tree nut': 'Tree Nut', 'nuts': 'Nuts', 'nut': 'Nut',
  'groundnut': 'Groundnut', 'pine nut': 'Pine Nut',
  'brazil nut': 'Brazil Nut', 'chestnut': 'Chestnut',

  // ── Lactose Intolerance (unique, shared dairy already spread) ─────────────
  'ghee': 'Ghee', 'buttermilk': 'Buttermilk',
  'milk powder': 'Milk Powder', 'skim milk': 'Skim Milk',
  'whole milk': 'Whole Milk', 'milk solids': 'Milk Solids',
  'milk protein': 'Milk Protein', 'curds': 'Curds',
  'half and half': 'Half and Half', 'sour cream': 'Sour Cream',
  'condensed milk': 'Condensed Milk', 'evaporated milk': 'Evaporated Milk',
  'lactalbumin': 'Lactalbumin', 'lactoglobulin': 'Lactoglobulin',

  // ── Vegan (unique, shared dairy & seafood already spread) ────────────────
  'meat': 'Meat', 'chicken': 'Chicken', 'beef': 'Beef',
  'pork': 'Pork', 'fish': 'Fish', 'egg': 'Egg', 'eggs': 'Eggs',
  'gelatin': 'Gelatin', 'gelatine': 'Gelatine', 'lard': 'Lard',
  'tallow': 'Tallow', 'shellac': 'Shellac', 'carmine': 'Carmine',
  'cochineal': 'Cochineal', 'isinglass': 'Isinglass',
  'pepsin': 'Pepsin', 'rennet': 'Rennet', 'albumin': 'Albumin',
  'bone char': 'Bone Char', 'collagen': 'Collagen',
  'lanolin': 'Lanolin', 'anchovy': 'Anchovy',
  'anchovies': 'Anchovies',

  // ── Keto (unique, shared sugars & grains already spread) ─────────────────
  'flour': 'Flour', 'corn starch': 'Corn Starch', 'rice': 'Rice',
  'pasta': 'Pasta', 'bread': 'Bread',
  'potato starch': 'Potato Starch', 'dextrin': 'Dextrin',
  'high fructose corn syrup': 'High Fructose Corn Syrup',
  'rice flour': 'Rice Flour',
  'tapioca starch': 'Tapioca Starch', 'modified starch': 'Modified Starch',
  'glucose syrup': 'Glucose Syrup', 'maple syrup': 'Maple Syrup',
  'oat flour': 'Oat Flour', 'barley malt': 'Barley Malt',

  // ── Low FODMAP (unique, shared sugars/dairy/grains spread) ───────────────
  'garlic': 'Garlic', 'onion': 'Onion', 'apple': 'Apple',
  'pear': 'Pear', 'sorbitol': 'Sorbitol', 'mannitol': 'Mannitol',
  'xylitol': 'Xylitol', 'inulin': 'Inulin',
  'chicory root': 'Chicory Root', 'artichoke': 'Artichoke',
  'asparagus': 'Asparagus', 'cauliflower': 'Cauliflower',
  'mushroom': 'Mushroom', 'watermelon': 'Watermelon',
  'mango': 'Mango', 'fig': 'Fig', 'dried fruit': 'Dried Fruit',
  'fruit juice concentrate': 'Fruit Juice Concentrate',
  'fructo-oligosaccharides': 'Fructo-Oligosaccharides',
  'fos': 'FOS', 'gos': 'GOS',

  // ── Shellfish Allergy (unique, shared seafood already spread) ─────────────
  'crab': 'Crab', 'lobster': 'Lobster', 'crayfish': 'Crayfish',
  'prawn': 'Prawn', 'shellfish': 'Shellfish', 'oyster': 'Oyster',
  'mussel': 'Mussel', 'clam': 'Clam', 'scallop': 'Scallop',
  'octopus': 'Octopus', 'abalone': 'Abalone', 'snail': 'Snail',
  'crawfish': 'Crawfish', 'langoustine': 'Langoustine',
  'cockle': 'Cockle', 'whelk': 'Whelk', 'sea urchin': 'Sea Urchin',
  'crustacean': 'Crustacean', 'mollusk': 'Mollusk', 'mollusc': 'Mollusc',

  // ── Soy Allergy ───────────────────────────────────────────────────────────
  'soy': 'Soy', 'soybean': 'Soybean', 'soya': 'Soya',
  'soy lecithin': 'Soy Lecithin', 'soy protein': 'Soy Protein',
  'soy sauce': 'Soy Sauce', 'tofu': 'Tofu', 'edamame': 'Edamame',
  'miso': 'Miso', 'tempeh': 'Tempeh', 'natto': 'Natto',
  'soy oil': 'Soy Oil', 'soybean oil': 'Soybean Oil',
  'soy flour': 'Soy Flour', 'soy milk': 'Soy Milk',
  'soy isolate': 'Soy Isolate', 'hydrolyzed soy': 'Hydrolyzed Soy',
  'textured soy protein': 'Textured Soy Protein',
  'soy concentrate': 'Soy Concentrate',
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
  // Lactose Intolerance
  'Iactose': 'Lactose', 'lactase': 'Lactose',
  'mi1k': 'Milk', 'miIk': 'Milk',
  'caseln': 'Casein', 'casien': 'Casein',
  'wney': 'Whey', 'whev': 'Whey',
  'butt er': 'Butter',
  'yog urt': 'Yogurt', 'yoghurt': 'Yogurt',
  // Vegan
  'ge1atin': 'Gelatin', 'gelat1n': 'Gelatin', 'gelatln': 'Gelatin',
  'gelatine': 'Gelatine',
  'co11agen': 'Collagen', 'coIlagen': 'Collagen',
  'a1bumin': 'Albumin',
  'eg g': 'Egg',
  // Keto
  'f1our': 'Flour', 'fiour': 'Flour',
  'starch': 'Starch',
  'rlce': 'Rice', 'r1ce': 'Rice',
  'dextrln': 'Dextrin',
  // Low FODMAP
  'gar1ic': 'Garlic', 'garllc': 'Garlic',
  'oni0n': 'Onion', 'onlon': 'Onion',
  'sorblto1': 'Sorbitol', 'sorbltol': 'Sorbitol',
  'mannito1': 'Mannitol',
  'inu1in': 'Inulin',
  // Shellfish Allergy
  'shrlmp': 'Shrimp', 'shr1mp': 'Shrimp',
  'she11fish': 'Shellfish',
  'lobst er': 'Lobster',
  'sca11op': 'Scallop',
  'musse1': 'Mussel',
  // Soy Allergy
  's0y': 'Soy', 'sov': 'Soy',
  'soybe an': 'Soybean', 's0ybean': 'Soybean',
  'soy 1ecithin': 'Soy Lecithin', 'soy Iecithin': 'Soy Lecithin',
  't0fu': 'Tofu',
  // Noise → discard
  'kcaine': '', 'kca': '',
};

/// Nutrition-table noise patterns.
/// Lines matching any of these are stripped before analysis.
final List<RegExp> nutritionLinePatterns = [
  RegExp(r'\bnutrition\s*facts?\b', caseSensitive: false),
  RegExp(r'\bsupplements?\s*facts?\b', caseSensitive: false),
  RegExp(r'\bvaleurs?\s*nutritives?\b', caseSensitive: false),
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
  RegExp(r'\bdaily\s+value\b', caseSensitive: false),
  RegExp(r'\b%\s*dv\b', caseSensitive: false),
  RegExp(r'^\s*[\d.,]+\s*(mg|g|mcg|iu|kcal|kj|%)\s*$', caseSensitive: false),
  RegExp(r'\bserving\s+size\b', caseSensitive: false),
  RegExp(r'\bservings?\s+per\b', caseSensitive: false),
];

/// Non-ingredient packaging text that should be discarded.
const List<String> nonIngredientBlacklist = [
  'keep in a clean', 'net weight', 'net wt', 'batch no', 'batch number',
  'store in', 'ingredients:', 'best before', 'best by', 'exp date',
  'expiry date', 'use by', 'manufactured by', 'product of', 'produced by',
  'see cap', 'shake well', 'keep refrigerated', 'serving suggestion',
  'may contain traces', 'for best quality', 'once opened',
  'protect from', 'keep away', 'distributed by',
];
