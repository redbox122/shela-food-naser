class EtagScopeKeyBuilder {
  EtagScopeKeyBuilder._();

  /// Builds a scoped cache key from [uri] and optional [headers].
  /// Headers that affect response content (e.g. Authorization, language)
  /// are included so different users/locales never share the same ETag slot.
  static String buildScopedUri(
    String uri, {
    Map<String, dynamic>? headers,
  }) {
    if (headers == null || headers.isEmpty) return uri;

    final relevantKeys = [
      'authorization',
      'accept-language',
      'x-localization',
      'zoneId',
      'zone-id',
    ];

    final parts = <String>[];
    for (final key in relevantKeys) {
      final value = headers[key] ?? headers[key.toLowerCase()];
      if (value != null && value.isNotEmpty) {
        parts.add('$key=$value');
      }
    }

    if (parts.isEmpty) return uri;
    return '$uri?__scope=${parts.join('&')}';
  }
}
