import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Shows an address in Arabic. Store/customer addresses are usually geocoded in
/// English when the record is created; this widget reverse-geocodes the point
/// with `language=ar` to render an Arabic address, falling back to [fallback]
/// (the stored string) while loading or if the lookup fails. Results are cached
/// per coordinate so each address is fetched at most once per session.
class ArabicAddressText extends StatefulWidget {
  final String fallback;
  final String? lat;
  final String? lng;
  final TextStyle? style;
  final int maxLines;

  const ArabicAddressText({
    super.key,
    required this.fallback,
    required this.lat,
    required this.lng,
    this.style,
    this.maxLines = 2,
  });

  static const String _apiKey = 'AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8';
  static final Map<String, String> _cache = <String, String>{};

  @override
  State<ArabicAddressText> createState() => _ArabicAddressTextState();
}

class _ArabicAddressTextState extends State<ArabicAddressText> {
  String? _arabic;

  bool _hasArabic(String s) =>
      s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

  @override
  void initState() {
    super.initState();
    // If the stored address is already Arabic, keep it as-is.
    if (_hasArabic(widget.fallback)) {
      _arabic = widget.fallback;
    } else {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final a = double.tryParse(widget.lat ?? '');
    final b = double.tryParse(widget.lng ?? '');
    if (a == null || b == null || (a == 0 && b == 0)) return;
    final key = '${a.toStringAsFixed(5)},${b.toStringAsFixed(5)}';
    final cached = ArabicAddressText._cache[key];
    if (cached != null) {
      if (mounted) setState(() => _arabic = cached);
      return;
    }
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$a,$b&language=ar&region=SA&key=${ArabicAddressText._apiKey}');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return;
      final addr = results.first['formatted_address'] as String?;
      if (addr == null || addr.isEmpty) return;
      ArabicAddressText._cache[key] = addr;
      if (mounted) setState(() => _arabic = addr);
    } catch (_) {/* keep fallback */}
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _arabic ?? widget.fallback,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
