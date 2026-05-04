import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/estimate.dart';
import '../models/place.dart';
import '../providers/compare_provider.dart';
import '../widgets/provider_card.dart';

class CompareScreen extends ConsumerWidget {
  final SelectedPlace pickup;
  final SelectedPlace drop;

  const CompareScreen({super.key, required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = CompareInput(pickup, drop);
    final asyncEst = ref.watch(estimateProvider(input));
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: asyncEst.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: '$e',
          onRetry: () => ref.invalidate(estimateProvider(input)),
        ),
        data: (est) => _ResultsList(est: est, pickup: pickup, drop: drop),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load estimates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final EstimateResponse est;
  final SelectedPlace pickup;
  final SelectedPlace drop;

  const _ResultsList({
    required this.est,
    required this.pickup,
    required this.drop,
  });

  String? _tagFor(String id, Recommendations r) {
    if (id == r.cheapest) return 'Cheapest';
    if (id == r.fastest) return 'Fastest';
    if (id == r.bestValue) return 'Best value';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showSurge = est.options.any((o) => o.surgeMultiplier > 1.2);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RouteHeader(est: est, pickup: pickup, drop: drop),
        const SizedBox(height: 16),
        if (showSurge) _SurgeAlert(surge: est.options.first.surgeMultiplier),
        ...est.options.map(
          (o) => ProviderCard(
            option: o,
            tag: _tagFor(o.rideTypeId, est.recommendations),
          ),
        ),
      ],
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final EstimateResponse est;
  final SelectedPlace pickup;
  final SelectedPlace drop;

  const _RouteHeader({
    required this.est,
    required this.pickup,
    required this.drop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickup.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drop.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Text(
                '${est.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Text(
                '~${est.durationMinutes.round()} min',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (est.usedMock) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'estimated route',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SurgeAlert extends StatelessWidget {
  final double surge;

  const _SurgeAlert({required this.surge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Surge pricing active (${surge.toStringAsFixed(1)}×). '
              'Consider waiting if not urgent.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
