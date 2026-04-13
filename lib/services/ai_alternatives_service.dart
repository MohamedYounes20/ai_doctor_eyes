import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'preferences_service.dart';

/// Service that calls the Gemini REST API directly (v1beta) to suggest
/// healthy food alternatives based on the user's saved health profile.
///
/// Uses `http` package with raw REST calls instead of the `google_generative_ai`
/// package, bypassing all dependency / model-version issues.
///
/// Endpoint: POST https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=API_KEY
class AiAlternativesService {
  final PreferencesService _prefs = PreferencesService();

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Returns exactly 3 healthy alternatives for [cravedFood], personalised
  /// to the user's age and health condition(s).
  ///
  /// Each map contains keys: `name`, `description`, `why_its_good`.
  /// Throws [Exception] on network / parsing / API-key errors.
  Future<List<Map<String, String>>> getAlternatives(String cravedFood) async {
    // ── 1. Fetch user profile ──────────────────────────────────────────────
    final yob = await _prefs.getYearOfBirth();
    final age = yob != null ? DateTime.now().year - yob : null;
    final conditions = await _prefs.getHealthConditions();

    final conditionNames = conditions.isNotEmpty
        ? conditions.map((c) => c.displayName).join(', ')
        : 'no specific condition';

    final ageStr = age != null ? '$age' : 'unknown';

    // ── 2. Validate API key ────────────────────────────────────────────────
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is not configured. '
        'Please add GEMINI_API_KEY to your .env file.',
      );
    }

    // ── 3. Build prompt ────────────────────────────────────────────────────
    final prompt =
        'You are a smart nutritionist. The user is $ageStr years old and '
        'suffers from $conditionNames. They are craving $cravedFood. '
        'Suggest exactly 3 healthy and accessible food alternatives that are '
        'safe for their condition. Return ONLY the JSON array. '
        'Do not include any introductory text. Keep descriptions brief to avoid truncation. '
        'The array objects must have keys: \'name\', \'description\', and \'why_its_good\'. '
        'Generate clean, professional titles for each alternative. Do NOT use single quotes (\'\'), '
        'double quotes (""), or any special characters like dashes in the \'name\' field '
        '(e.g., use "Portobello Mushroom Pizzas" instead of "Portobello Mushroom \'Pizzas\'"). '
        'Do not include markdown formatting.';

    // ── 4. Call Gemini REST API ────────────────────────────────────────────
    final uri = Uri.parse('$_endpoint?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    // ── 5. Extract text from response ──────────────────────────────────────
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty response from AI. Please try again.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    final responseText = parts?[0]['text'] as String?;

    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception('Empty text in AI response. Please try again.');
    }

    // ── 6. Parse JSON array ────────────────────────────────────────────────
    return _parseAlternatives(responseText);
  }

  List<Map<String, String>> _parseAlternatives(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');

    if (start != -1) {
      String jsonSlice;
      if (end != -1 && end > start) {
        jsonSlice = text.substring(start, end + 1).trim();
      } else {
        // Truncated response: manually append the closing bracket
        jsonSlice = '${text.substring(start).trim()}]';
      }

      try {
        final List<dynamic> jsonList = jsonDecode(jsonSlice) as List<dynamic>;
        return jsonList.map<Map<String, String>>((item) {
          final map = item as Map<String, dynamic>;
          return {
            'name': (map['name'] ?? '').toString(),
            'description': (map['description'] ?? '').toString(),
            'why_its_good': (map['why_its_good'] ?? '').toString(),
          };
        }).toList();
      } catch (e) {
        // ignore: avoid_print
        print('[AiAlternativesService] jsonDecode failed.\nSlice:\n$jsonSlice');
        throw Exception('Failed to decode AI JSON array: $e');
      }
    }

    throw Exception(
      'No JSON array found in AI response. '
      'Raw text: ${text.length > 300 ? text.substring(0, 300) : text}',
    );
  }
}
