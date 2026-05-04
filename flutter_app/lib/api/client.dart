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
    if (input.trim().isEmpty || googleMapsKey.isEmpty) return [];
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
