import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Represents a single restaurant result returned from the Places API.
class RestaurantResult {
  final String name;
  final String address;
  final String mapsUrl;
  final String affiliateUrl;

  const RestaurantResult({
    required this.name,
    required this.address,
    required this.mapsUrl,
    required this.affiliateUrl,
  });
}

/// Service that:
/// 1. Approximates the user's location via the free ip-api.com service
///    (no native plugin required — uses the existing `http` package).
/// 2. Calls the Google Places Text Search API to find nearby restaurants
///    matching the suggested dish name.
/// 3. Wraps each result's Maps URL with a simulated affiliate referral tag,
///    demonstrating the commission-based monetization model.
///
/// Demo mode: when GOOGLE_PLACES_API_KEY is absent from `.env`, a 1-second
/// simulated delay is applied and 3 mock restaurants are returned so the
/// UI can be demonstrated without any API keys or billing.
class RestaurantLocatorService {
  static const String _placesEndpoint =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';

  /// Affiliate tag appended to every generated Maps URL.
  static const String _affiliateTag = '?ref=ai_doctor_eyes_affiliate';

  /// Find up to 3 nearby restaurants matching [dishName].
  ///
  /// Falls back to mock data if GOOGLE_PLACES_API_KEY is absent.
  /// Throws an [Exception] if the Places API returns a non-OK status.
  Future<List<RestaurantResult>> findNearby(String dishName) async {
    // ── 1. Demo mode: return mocks if no API key configured ──────────────────
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockResults();
    }

    // ── 2. Approximate location via IP geolocation (no native plugin needed) ─
    final location = await _getLocationFromIp();

    // ── 3. Call Places Text Search API ──────────────────────────────────────
    final uri = Uri.parse(_placesEndpoint).replace(queryParameters: {
      'query': '$dishName restaurant',
      'location': '${location['lat']},${location['lng']}',
      'radius': '5000',
      'type': 'restaurant',
      'key': apiKey,
    });

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Places API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'] as String? ?? '';

    if (status == 'REQUEST_DENIED') {
      throw Exception(
        'Places API request denied — check your GOOGLE_PLACES_API_KEY is valid '
        'and the "Places API" is enabled in Google Cloud Console.',
      );
    }
    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      throw Exception('Places API returned status: $status');
    }

    // ── 4. Parse top 3 results ───────────────────────────────────────────────
    final results = (decoded['results'] as List? ?? []).take(3);

    return results.map<RestaurantResult>((place) {
      final name = place['name'] as String? ?? 'Unknown Restaurant';
      final address = place['formatted_address'] as String? ?? '';
      final placeId = place['place_id'] as String? ?? '';
      final mapsUrl = 'https://www.google.com/maps/place/?q=place_id:$placeId';
      final affiliateUrl = '$mapsUrl$_affiliateTag';
      return RestaurantResult(
        name: name,
        address: address,
        mapsUrl: mapsUrl,
        affiliateUrl: affiliateUrl,
      );
    }).toList();
  }

  // ── IP Geolocation (no native permissions, no plugin) ─────────────────────

  /// Uses the free ip-api.com JSON endpoint to obtain an approximate lat/lng
  /// based on the device's public IP address. No permissions are required.
  /// Falls back to a sensible default (Cairo, Egypt) if the call fails.
  Future<Map<String, double>> _getLocationFromIp() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=lat,lon'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return {'lat': lat, 'lng': lon};
        }
      }
    } catch (_) {
      // Silently fall through to default location
    }
    // Default fallback: Cairo, Egypt
    return {'lat': 30.0444, 'lng': 31.2357};
  }

  // ── Mock data (demo mode — no API key required) ──────────────────────────

  List<RestaurantResult> _mockResults() {
    return const [
      RestaurantResult(
        name: 'Healthy Bites',
        address: '12 Wellness Ave, Downtown',
        mapsUrl: 'https://www.google.com/maps/search/healthy+bites',
        affiliateUrl:
            'https://www.google.com/maps/search/healthy+bites?ref=ai_doctor_eyes_affiliate',
      ),
      RestaurantResult(
        name: 'Green Bowl',
        address: '37 Organic St, Health District',
        mapsUrl: 'https://www.google.com/maps/search/green+bowl+restaurant',
        affiliateUrl:
            'https://www.google.com/maps/search/green+bowl+restaurant?ref=ai_doctor_eyes_affiliate',
      ),
      RestaurantResult(
        name: 'Fit Kitchen',
        address: '88 Nutrition Blvd, City Centre',
        mapsUrl: 'https://www.google.com/maps/search/fit+kitchen+restaurant',
        affiliateUrl:
            'https://www.google.com/maps/search/fit+kitchen+restaurant?ref=ai_doctor_eyes_affiliate',
      ),
    ];
  }
}
