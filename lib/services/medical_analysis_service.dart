import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/medical_profile.dart';
import '../models/lab_record.dart';
import 'database_helper.dart';

/// Service that sends a lab-report image to Gemini Vision and extracts a
/// [MedicalProfile] (forbidden ingredients + condition + severity).
///
/// The extracted profile is automatically persisted to SQLite so the offline
/// scanner can use it for Critical-tier alerts immediately after.
class MedicalAnalysisService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _prompt =
      'Analyze this medical lab report image carefully. '
      'Identify the primary health condition indicated by the results. '
      'Then list the specific food ingredients, chemical additives, or substances '
      'this person must strictly avoid based on these results. '
      'Return ONLY a raw JSON object. No markdown, no conversational text. '
      'If the lab results are completely normal/healthy, you MUST return exactly this JSON: '
      '{"condition": "Healthy", "forbiddenKeywords": [], "severity": "None"}\n'
      'Rules: severity must be exactly "High", "Medium", "Low", or "None". '
      'forbiddenKeywords must be lowercase single words or short phrases. '
      'Do not include nutritional values or dosage amounts.';

  /// Analyse [imageFile] with Gemini Vision and persist the result to SQLite.
  ///
  /// Returns the saved [MedicalProfile] so the UI can display it immediately.
  ///
  /// Throws [Exception] on:
  ///  - Missing GEMINI_API_KEY in `.env`
  ///  - Network failure / timeout
  ///  - Non-200 HTTP response
  ///  - Invalid / missing JSON in the model's reply
  Future<MedicalProfile> analyzeMedicalReport(File imageFile) async {
    // ── 1. Validate API key ──────────────────────────────────────────────────
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is missing.\n'
        'Add GEMINI_API_KEY to your .env file.',
      );
    }

    // ── 2. Read & base64-encode image ────────────────────────────────────────
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _mimeType(imageFile.path);

    // ── 3. Build Gemini Vision request ───────────────────────────────────────
    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,   // Low temperature for deterministic extraction
        'maxOutputTokens': 4096,
      },
    });

    // ── 4. Call API ──────────────────────────────────────────────────────────
    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw Exception(
            'Request timed out. Please check your internet connection and try again.',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API returned status ${response.statusCode}.\n'
        'Body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );
    }

    // ── 5. Extract text from response ────────────────────────────────────────
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned an empty response. Please try again.');
    }
    final parts = (candidates[0]['content'] as Map?)?['parts'] as List?;
    final responseText = parts?.isNotEmpty == true
        ? parts![0]['text'] as String?
        : null;
    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception('No text in Gemini response. Please try again.');
    }

    // ── 6. Parse JSON ────────────────────────────────────────────────────────
    print('RAW GEMINI RESPONSE: $responseText');
    final json = _parseJson(responseText);
    if (json == null) {
      throw Exception(
        'Could not parse a valid medical profile from the report.\n'
        'Make sure the image is a readable lab result.',
      );
    }

    final keywords = (json['forbiddenKeywords'] as List? ?? [])
        .map((k) => k.toString().toLowerCase().trim())
        .where((k) => k.isNotEmpty)
        .toList();

    final profile = MedicalProfile(
      condition: (json['condition'] as String? ?? 'Unknown').trim(),
      forbiddenKeywords: keywords,
      severity: _normaliseSeverity(json['severity'] as String?),
      lastUpdated: DateTime.now(),
    );

    // ── 7. Persist to SQLite ─────────────────────────────────────────────────
    await DatabaseHelper.instance.upsertMedicalProfile(profile);

    final labRecord = LabRecord(
      dateTime: profile.lastUpdated,
      conditionTitle: profile.condition,
      forbiddenIngredients: profile.forbiddenKeywords,
    );
    await DatabaseHelper.instance.insertLabRecord(labRecord);

    return profile;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _normaliseSeverity(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'none':
        return 'None';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'High';
    }
  }

  Map<String, dynamic>? _parseJson(String text) {
    // Strip out markdown code blocks if Gemini wrapped the response
    String cleaned = text.replaceAll(RegExp(r'```[a-zA-Z]*'), '').replaceAll('```', '').trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1) return null;
    
    final slice = (end != -1 && end > start)
        ? cleaned.substring(start, end + 1)
        : '${cleaned.substring(start)}}';
        
    try {
      return jsonDecode(slice) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
