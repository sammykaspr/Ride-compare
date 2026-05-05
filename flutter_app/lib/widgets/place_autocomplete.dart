import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/compare_provider.dart';

class PlaceAutocompleteField extends ConsumerStatefulWidget {
  final String label;
  final IconData icon;
  final ValueChanged<SelectedPlace> onSelected;
  final SelectedPlace? initial;

  const PlaceAutocompleteField({
    super.key,
    required this.label,
    required this.icon,
    required this.onSelected,
    this.initial,
  });

  @override
  ConsumerState<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState
    extends ConsumerState<PlaceAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _controller.text = widget.initial!.description;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _hideOverlay();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetch(v));
  }

  Future<void> _fetch(String input) async {
    if (input.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      _hideOverlay();
      return;
    }
    setState(() => _loading = true);
    final client = ref.read(apiClientProvider);
    try {
      final results = await client.placeAutocomplete(input);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
      _showOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showOverlay() {
    _hideOverlay();
    if (_suggestions.isEmpty && !_loading) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    _overlay = OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 20),
                          title: Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _select(s),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _select(PlaceSuggestion s) async {
    _focusNode.unfocus();
    _controller.text = s.description;
    _hideOverlay();
    final client = ref.read(apiClientProvider);
    try {
      final latLng = s.latLng ?? await client.placeDetails(s.placeId);
      widget.onSelected(
        SelectedPlace(description: s.description, latLng: latLng),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load place details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}
