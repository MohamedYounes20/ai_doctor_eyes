import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_history_item.dart';

/// Offline database helper using sqflite.
/// Stores scan history: id, productName, status, harmfulIngredients, timestamp.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  static const String _tableScanHistory = 'scan_history';
  static const int _version = 1;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_doctor_eyes.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableScanHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT NOT NULL,
        status TEXT NOT NULL,
        harmfulIngredients TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  /// Insert a scan result
  Future<int> insertScanHistory(ScanHistoryItem item) async {
    final db = await database;
    return db.insert(
      _tableScanHistory,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all scan history ordered by timestamp (newest first)
  Future<List<ScanHistoryItem>> getAllScanHistory() async {
    final db = await database;
    final maps = await db.query(
      _tableScanHistory,
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ScanHistoryItem.fromMap(m)).toList();
  }

  /// Delete a scan history entry
  Future<int> deleteScanHistory(int id) async {
    final db = await database;
    return db.delete(
      _tableScanHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close database (for testing or cleanup)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
