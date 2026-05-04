import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../models/estimate.dart';
import '../models/place.dart';

const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
const _googleMapsKey =
    String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _backendUrl, googleMapsKey: _googleMapsKey);
});

class CompareInput {
  final SelectedPlace pickup;
  final SelectedPlace drop;

  const CompareInput(this.pickup, this.drop);

  @override
  bool operator ==(Object other) =>
      other is CompareInput &&
      other.pickup.latLng.lat == pickup.latLng.lat &&
      other.pickup.latLng.lng == pickup.latLng.lng &&
      other.drop.latLng.lat == drop.latLng.lat &&
      other.drop.latLng.lng == drop.latLng.lng;

  @override
  int get hashCode => Object.hash(
        pickup.latLng.lat,
        pickup.latLng.lng,
        drop.latLng.lat,
        drop.latLng.lng,
      );
}

final estimateProvider =
    FutureProvider.family<EstimateResponse, CompareInput>((ref, input) async {
  final client = ref.read(apiClientProvider);
  return client.estimate(
    pickup: input.pickup.latLng,
    drop: input.drop.latLng,
    pickupAddress: input.pickup.description,
    dropAddress: input.drop.description,
  );
});
