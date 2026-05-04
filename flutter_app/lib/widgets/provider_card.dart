import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/estimate.dart';

class ProviderCard extends StatelessWidget {
  final RideOption option;
  final String? tag;

  const ProviderCard({super.key, required this.option, this.tag});

  Color _providerColor() {
    switch (option.provider) {
      case 'uber':
        return const Color(0xFF000000);
      case 'ola':
        return const Color(0xFF7BAA3D);
      case 'rapido':
        return const Color(0xFFFFC107);
      case 'namma_yatri':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  IconData _rideIcon() {
    final l = option.rideTypeLabel.toLowerCase();
    if (l.contains('bike')) return Icons.two_wheeler;
    if (l.contains('auto')) return Icons.electric_rickshaw;
    return Icons.local_taxi;
  }

  Color _tagColor(String t) {
    switch (t) {
      case 'Cheapest':
        return Colors.green.shade700;
      case 'Fastest':
        return Colors.blue.shade700;
      case 'Best value':
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(option.deepLink);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${option.providerLabel}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _launch(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _providerColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_rideIcon(), color: _providerColor()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.providerLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${option.rideTypeLabel}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '~${option.etaMinutes} min away',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _tagColor(tag!).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _tagColor(tag!),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${option.priceMin.toInt()}–${option.priceMax.toInt()}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (option.surgeMultiplier > 1.05)
                    Text(
                      '${option.surgeMultiplier.toStringAsFixed(1)}× surge',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
