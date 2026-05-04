class RideOption {
  final String provider;
  final String providerLabel;
  final String rideTypeId;
  final String rideTypeLabel;
  final double priceMin;
  final double priceMax;
  final int etaMinutes;
  final double durationMinutes;
  final double distanceKm;
  final double surgeMultiplier;
  final String deepLink;

  RideOption({
    required this.provider,
    required this.providerLabel,
    required this.rideTypeId,
    required this.rideTypeLabel,
    required this.priceMin,
    required this.priceMax,
    required this.etaMinutes,
    required this.durationMinutes,
    required this.distanceKm,
    required this.surgeMultiplier,
    required this.deepLink,
  });

  factory RideOption.fromJson(Map<String, dynamic> j) => RideOption(
        provider: j['provider'] as String,
        providerLabel: j['provider_label'] as String,
        rideTypeId: j['ride_type_id'] as String,
        rideTypeLabel: j['ride_type_label'] as String,
        priceMin: (j['price_min'] as num).toDouble(),
        priceMax: (j['price_max'] as num).toDouble(),
        etaMinutes: j['eta_minutes'] as int,
        durationMinutes: (j['duration_minutes'] as num).toDouble(),
        distanceKm: (j['distance_km'] as num).toDouble(),
        surgeMultiplier: (j['surge_multiplier'] as num).toDouble(),
        deepLink: j['deep_link'] as String,
      );
}

class Recommendations {
  final String? cheapest;
  final String? fastest;
  final String? bestValue;

  const Recommendations({this.cheapest, this.fastest, this.bestValue});

  factory Recommendations.fromJson(Map<String, dynamic> j) => Recommendations(
        cheapest: j['cheapest'] as String?,
        fastest: j['fastest'] as String?,
        bestValue: j['best_value'] as String?,
      );
}

class EstimateResponse {
  final double distanceKm;
  final double durationMinutes;
  final List<RideOption> options;
  final Recommendations recommendations;
  final bool usedMock;

  EstimateResponse({
    required this.distanceKm,
    required this.durationMinutes,
    required this.options,
    required this.recommendations,
    required this.usedMock,
  });

  factory EstimateResponse.fromJson(Map<String, dynamic> j) => EstimateResponse(
        distanceKm: (j['distance_km'] as num).toDouble(),
        durationMinutes: (j['duration_minutes'] as num).toDouble(),
        options: (j['options'] as List)
            .map((o) => RideOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        recommendations:
            Recommendations.fromJson(j['recommendations'] as Map<String, dynamic>),
        usedMock: (j['used_mock'] as bool?) ?? false,
      );
}
