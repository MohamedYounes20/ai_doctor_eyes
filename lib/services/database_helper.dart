import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Offline database helper using sqflite.
///
/// Tables:
///   cached_ingredients      – legacy per-ingredient AI cache
///   product_analysis_cache  – NEW: per-product AI result keyed by sha256 hash
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  static const String _tableCachedIngredients = 'cached_ingredients';
  static const String _tableProductCache = 'product_analysis_cache';
  static const int _version = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_doctor_eyes.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableCachedIngredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredientName TEXT NOT NULL,
        conditionName TEXT NOT NULL,
        status TEXT NOT NULL,
        reason TEXT NOT NULL,
        severity TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableProductCache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cache_key TEXT NOT NULL UNIQUE,
        conditions TEXT NOT NULL,
        status TEXT NOT NULL,
        found_harmful TEXT NOT NULL,
        reason_ar TEXT NOT NULL,
        analysis_en TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_tableCachedIngredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ingredientName TEXT NOT NULL,
          conditionName TEXT NOT NULL,
          status TEXT NOT NULL,
          reason TEXT NOT NULL,
          severity TEXT,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE $_tableCachedIngredients ADD COLUMN severity TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableProductCache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cache_key TEXT NOT NULL UNIQUE,
          conditions TEXT NOT NULL,
          status TEXT NOT NULL,
          found_harmful TEXT NOT NULL,
          reason_ar TEXT NOT NULL,
          analysis_en TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
  }

  // ── Legacy Per-Ingredient Cache ─────────────────────────────────────────────

  Future<int> cacheIngredient({
    required String ingredientName,
    required String conditionName,
    required String status,
    required String reason,
    String? severity,
  }) async {
    final db = await database;
    return db.insert(
      _tableCachedIngredients,
      {
        'ingredientName': ingredientName,
        'conditionName': conditionName,
        'status': status,
        'reason': reason,
        'severity': severity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedIngredient(
      String ingredientName, String conditionName) async {
    final db = await database;
    final results = await db.query(
      _tableCachedIngredients,
      where: 'ingredientName = ? AND conditionName = ?',
      whereArgs: [ingredientName, conditionName],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ── Product-Level AI Analysis Cache ────────────────────────────────────────

  /// Save a full product AI analysis result.
  /// [key]          – sha256 hash of (cleanedText + conditions)
  /// [foundHarmful] – JSON-encoded list of harmful ingredient names
  Future<int> cacheProductAnalysis({
    required String key,
    required String conditions,
    required String status,
    required String foundHarmful,
    required String reasonAr,
    required String analysisEn,
  }) async {
    final db = await database;
    return db.insert(
      _tableProductCache,
      {
        'cache_key': key,
        'conditions': conditions,
        'status': status,
        'found_harmful': foundHarmful,
        'reason_ar': reasonAr,
        'analysis_en': analysisEn,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve a cached product analysis by its hash key.
  /// Returns null if no entry exists.
  Future<Map<String, dynamic>?> getCachedProductAnalysis(String key) async {
    final db = await database;
    final results = await db.query(
      _tableProductCache,
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
