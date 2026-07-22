import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Recovers a product's EXTRA photos client-side (sync-proof, no backend, no
/// external API).
///
/// Hyper Shela's daily sync imports only ONE image per product, but the source
/// CDN (images.todoorstep.com) keeps the full gallery in the same
/// `/product/{sku}/` folder as `side1.jpg`, `side2.jpg`, … The main image URL
/// Shela already stores embeds that `{sku}`, so we can reach the sides directly.
///
/// Gotcha: a MISSING side does not 404 — the CDN returns a fixed 3844-byte
/// placeholder with HTTP 200. So real images are detected by Content-Length
/// (real product photos are tens/hundreds of KB). Sides are contiguous
/// (side1..sideK), so we stop at the first placeholder.
class ProductSideImages {
  ProductSideImages._();

  /// Universal "no image" placeholder size on the CDN (bytes).
  static const int _placeholderBytes = 3844;
  static const int _maxSides = 12;
  static final RegExp _folder = RegExp(r'(.*/product/[^/]+/)');

  /// Full-resolution side image URLs that really exist for [mainImageUrl], in
  /// order. Returns empty on web (CORS), on non-CDN URLs, or when there are no
  /// extra photos.
  static Future<List<String>> fetch(String mainImageUrl) async {
    if (kIsWeb || mainImageUrl.isEmpty) return const [];
    final m = _folder.firstMatch(mainImageUrl);
    if (m == null) return const [];
    final String base = m.group(1)!; // …/product/{sku}/
    // Preserve any ?t= cache-buster carried by the main URL.
    final int q = mainImageUrl.indexOf('?');
    final String query = q >= 0 ? mainImageUrl.substring(q) : '';

    final sides = <String>[];
    for (int i = 1; i <= _maxSides; i++) {
      final String url = '${base}side$i.jpg$query';
      try {
        final r = await http
            .head(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (r.statusCode != 200) break;
        final int len = int.tryParse(r.headers['content-length'] ?? '') ?? 0;
        // Placeholder (or empty) → we've passed the last real side.
        if (len <= _placeholderBytes + 256) break;
        sides.add(url);
      } catch (_) {
        break;
      }
    }
    return sides;
  }
}
