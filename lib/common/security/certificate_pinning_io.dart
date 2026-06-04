/*
 * Certificate Pinning — dart:io implementation (mobile / desktop).
 *
 * Builds a SecurityContext that trusts ONLY the bundled CA certificates
 * (withTrustedRoots: false), so any TLS chain that does not terminate at the
 * pinned GTS WE1 intermediate or GTS Root R4 is rejected by the OS validator.
 * Hostname verification and expiry checks still apply as usual.
 *
 * We pin the intermediate + root (NOT the leaf): leaf certificates rotate
 * frequently, but the issuing CA stays stable, so this survives normal cert
 * renewals without locking users out.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// PEM assets that form the pinned trust anchors. Order is irrelevant.
const List<String> _pinnedCertAssets = <String>[
  'assets/certs/gts_we1.pem', // intermediate (primary)
  'assets/certs/gts_root_r4.pem', // root (backup pin)
];

/// Built once by [initPinning] and reused by every pinned client.
SecurityContext? _pinnedContext;

/// Loads the PEM assets and builds the pinned [SecurityContext].
///
/// Fail-closed: throws if an asset is missing or empty so the app surfaces a
/// clear configuration error instead of silently trusting any certificate.
Future<void> initPinning() async {
  final SecurityContext context = SecurityContext(withTrustedRoots: false);

  var loaded = 0;
  for (final String assetPath in _pinnedCertAssets) {
    // rootBundle.load throws a clear FlutterError if the asset is absent.
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    if (bytes.isEmpty) {
      throw StateError(
        'Certificate pinning: CA asset "$assetPath" is empty. '
        'Refusing to start with an empty trust anchor.',
      );
    }
    context.setTrustedCertificatesBytes(bytes);
    loaded++;
  }

  if (loaded == 0) {
    // Defensive: never proceed with an empty pinned trust store.
    throw StateError(
      'Certificate pinning is enabled but no CA certificates were loaded.',
    );
  }

  _pinnedContext = context;

  if (kDebugMode) {
    debugPrint(
        '🔒 Certificate pinning active: $loaded pinned CA certificate(s) loaded.');
  }
}

/// Routes [dio] through the pinned [SecurityContext].
///
/// Fail-closed: if the context was never initialised, the per-connection
/// factory throws and the request fails — it never falls back to an
/// un-pinned / "trust anything" client.
void applyPinning(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final SecurityContext? context = _pinnedContext;
      if (context == null) {
        throw StateError(
          'Certificate pinning is enabled but the SecurityContext is not '
          'initialised. Call CertificatePinning.init() at startup before '
          'issuing requests.',
        );
      }
      return HttpClient(context: context);
    },
  );
}
