import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medical_profile.dart';

/// Offline database helper using sqflite.
///
/// Tables (version history):
///   v2  cached_ingredients      – per-ingredient AI cache
///   v4  product_analysis_cache  – per-product AI result keyed by sha256 hash
///   v5  medical_profile         – Gemini-Vision extracted lab-report data (single row)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  static const String _tableCachedIngredients = 'cached_ingredients';
  static const String _tableProductCache = 'product_analysis_cache';
  static const String _tableMedicalProfile = 'medical_profile';
  static const int _version = 5;

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

  // ── Schema creation ─────────────────────────────────────────────────────────

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

    await db.execute(_medicalProfileDdl);
  }

  /// DDL for the medical_profile table — single-row upsert semantics.
  static const String _medicalProfileDdl = '''
    CREATE TABLE IF NOT EXISTS $_tableMedicalProfile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      condition TEXT NOT NULL,
      forbidden_keywords TEXT NOT NULL,
      severity TEXT NOT NULL,
      last_updated INTEGER NOT NULL
    )
  ''';

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
    if (oldVersion < 5) {
      await db.execute(_medicalProfileDdl);
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
  /// [key] – sha256 hash of (cleanedText + conditions)
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

  // ── Medical Profile (single-row upsert) ────────────────────────────────────

  /// Save or overwrite the user's medical profile.
  /// Uses DELETE + INSERT to enforce single-row semantics.
  Future<void> upsertMedicalProfile(MedicalProfile profile) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableMedicalProfile);
      await txn.insert(_tableMedicalProfile, profile.toMap());
    });
  }

  /// Returns the saved [MedicalProfile], or `null` if none exists yet.
  Future<MedicalProfile?> getMedicalProfile() async {
    final db = await database;
    final rows = await db.query(_tableMedicalProfile, limit: 1);
    if (rows.isEmpty) return null;
    return MedicalProfile.fromMap(rows.first);
  }

  // ── Backup Export ───────────────────────────────────────────────────────────

  /// Dumps all user-facing tables to a serialisable map for JSON backup.
  Future<Map<String, List<Map<String, dynamic>>>> getAllTablesAsJson() async {
    final db = await database;
    final productCache = await db.query(_tableProductCache);
    final medicalProfile = await db.query(_tableMedicalProfile);

    // product_analysis_cache rows contain a `found_harmful` TEXT column which
    // is already JSON-encoded — safe to pass through as-is.
    return {
      'product_analysis_cache': productCache
          .map((r) => Map<String, dynamic>.from(r))
          .toList(),
      'medical_profile': medicalProfile
          .map((r) => Map<String, dynamic>.from(r))
          .toList(),
    };
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
