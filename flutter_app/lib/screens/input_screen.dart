import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../widgets/place_autocomplete.dart';
import 'compare_screen.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  SelectedPlace? _pickup;
  SelectedPlace? _drop;

  @override
  Widget build(BuildContext context) {
    final canCompare = _pickup != null && _drop != null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'RideCompare',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Compare prices across Uber, Ola, Rapido, and Namma Yatri.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              PlaceAutocompleteField(
                label: 'Pickup',
                icon: Icons.my_location,
                initial: _pickup,
                onSelected: (p) => setState(() => _pickup = p),
              ),
              const SizedBox(height: 12),
              PlaceAutocompleteField(
                label: 'Drop',
                icon: Icons.location_on_outlined,
                initial: _drop,
                onSelected: (p) => setState(() => _drop = p),
              ),
              const Spacer(),
              FilledButton(
                onPressed: canCompare
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompareScreen(
                              pickup: _pickup!,
                              drop: _drop!,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Compare Prices'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
