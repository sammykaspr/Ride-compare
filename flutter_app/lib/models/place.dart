class PlaceSuggestion {
  final String placeId;
  final String description;
  final LatLng? latLng;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.latLng,
  });
}

class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);
}

class SelectedPlace {
  final String description;
  final LatLng latLng;

  const SelectedPlace({required this.description, required this.latLng});
}
