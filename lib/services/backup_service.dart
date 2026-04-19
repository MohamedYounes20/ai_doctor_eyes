import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/medical_profile.dart';
import 'database_helper.dart';

/// Handles offline-first data portability: export and import of all user data
/// as a single structured JSON file.
///
/// **Export** writes `health_backup_<timestamp>.json` to the device's Documents
/// directory.
/// **Import** reads a user-selected `.json` file and restores data into SQLite.
class BackupService {
  static const int _backupVersion = 1;

  // ── Export ──────────────────────────────────────────────────────────────────

  /// Exports all user data to a JSON file in the Documents directory.
  ///
  /// Returns the full path of the created file so the UI can display it.
  /// Throws [Exception] on write failure.
  Future<String> exportBackup() async {
    // 1. Fetch all data from SQLite
    final tables = await DatabaseHelper.instance.getAllTablesAsJson();

    // 2. Build structured backup envelope
    final backup = {
      'version': _backupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'ai_doctor_eyes',
      'tables': tables,
    };

    // 3. Resolve output directory
    final dir = await _resolveExportDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/health_backup_$timestamp.json');

    // 4. Write JSON
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
      flush: true,
    );

    return file.path;
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Opens a file picker, reads the selected JSON backup, and restores data
  /// into the local SQLite database.
  ///
  /// Throws [Exception] on:
  ///  - User cancels the picker (no file selected)
  ///  - File is not valid JSON
  ///  - Missing `tables` key (wrong file format)
  ///  - Any SQLite write error
  Future<void> importBackup() async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file was selected.');
    }

    // 2. Read content
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('The selected file appears to be empty.');
    }
    final content = utf8.decode(bytes);

    // 3. Parse JSON
    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'The selected file is not valid JSON.\n'
        'Please select a file exported by AI Doctor Eyes.',
      );
    }

    // 4. Validate structure
    if (!backup.containsKey('tables')) {
      throw Exception(
        'Invalid backup format — missing "tables" key.\n'
        'Please select a file exported by AI Doctor Eyes.',
      );
    }

    final tables = backup['tables'] as Map<String, dynamic>?;
    if (tables == null) {
      throw Exception('Backup "tables" field is empty or invalid.');
    }

    final db = DatabaseHelper.instance;

    // 5a. Restore medical_profile rows
    final profileRows = tables['medical_profile'] as List<dynamic>? ?? [];
    for (final row in profileRows) {
      final map = row as Map<String, dynamic>;
      // Remove the auto-increment id so SQLite assigns a fresh one
      map.remove('id');
      try {
        final profile = MedicalProfile.fromMap(map);
        await db.upsertMedicalProfile(profile);
      } catch (e) {
        throw Exception('Failed to restore medical profile: $e');
      }
    }

    // 5b. Restore product_analysis_cache rows
    final cacheRows =
        tables['product_analysis_cache'] as List<dynamic>? ?? [];
    for (final row in cacheRows) {
      final map = Map<String, dynamic>.from(row as Map);
      map.remove('id');
      try {
        await db.cacheProductAnalysis(
          key: map['cache_key'] as String,
          conditions: map['conditions'] as String,
          status: map['status'] as String,
          foundHarmful: map['found_harmful'] as String,
          reasonAr: map['reason_ar'] as String? ?? '',
          analysisEn: map['analysis_en'] as String? ?? '',
        );
      } catch (_) {
        // Skip duplicate cache entries silently — not critical data
      }
    }
  }

  // ── Directory resolution ────────────────────────────────────────────────────

  Future<Directory> _resolveExportDirectory() async {
    // Prefer external storage on Android (visible to user), fall back to docs.
    if (Platform.isAndroid) {
      try {
        final external = await getExternalStorageDirectory();
        if (external != null) return external;
      } catch (_) {}
    }
    return getApplicationDocumentsDirectory();
  }
}
