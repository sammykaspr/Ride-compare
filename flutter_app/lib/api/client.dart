import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/estimate.dart';
import '../models/place.dart';

class ApiClient {
  final String baseUrl;
  final String googleMapsKey;

  ApiClient({required this.baseUrl, required this.googleMapsKey});

  Future<List<PlaceSuggestion>> placeAutocomplete(String input,
      {String? sessionToken}) async {
    if (input.trim().length < 3) return [];
    if (googleMapsKey.isNotEmpty) {
      return _googleAutocomplete(input, sessionToken: sessionToken);
    }
    return _nominatimSearch(input);
  }

  Future<List<PlaceSuggestion>> _googleAutocomplete(String input,
      {String? sessionToken}) async {
    final params = <String, String>{
      'input': input,
      'key': googleMapsKey,
      if (sessionToken != null) 'sessiontoken': sessionToken,
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return [];
    return (data['predictions'] as List)
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ))
        .toList();
  }

  Future<List<PlaceSuggestion>> _nominatimSearch(String input) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': input,
      'format': 'json',
      'limit': '6',
      'addressdetails': '0',
    });
    final res = await http.get(uri, headers: const {
      'User-Agent': 'RideCompare/0.1 (dev)',
      'Accept': 'application/json',
    });
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as List;
    return data.map((p) {
      final m = p as Map<String, dynamic>;
      return PlaceSuggestion(
        placeId: '${m['place_id']}',
        description: m['display_name'] as String,
        latLng: LatLng(
          double.parse(m['lat'] as String),
          double.parse(m['lon'] as String),
        ),
      );
    }).toList();
  }

  Future<LatLng> placeDetails(String placeId, {String? sessionToken}) async {
    final params = <String, String>{
      'place_id': placeId,
      'fields': 'geometry',
      'key': googleMapsKey,
      if (sessionToken != null) 'sessiontoken': sessionToken,
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      params,
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final loc = data['result']['geometry']['location'];
    return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
  }

  Future<EstimateResponse> estimate({
    required LatLng pickup,
    required LatLng drop,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/estimate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pickup': {'lat': pickup.lat, 'lng': pickup.lng},
        'drop': {'lat': drop.lat, 'lng': drop.lng},
        'pickup_address': pickupAddress,
        'drop_address': dropAddress,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Estimate failed: ${res.statusCode} ${res.body}');
    }
    return EstimateResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
