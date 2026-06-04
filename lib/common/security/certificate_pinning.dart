/*
 * Certificate Pinning (TLS) — public facade
 *
 * Pins our own-domain Dio clients to the bundled GTS WE1 intermediate and
 * GTS Root R4 CA certificates using a custom SecurityContext that trusts ONLY
 * those CAs (system root store disabled for these connections).
 *
 * Design contract:
 *  - Controlled exclusively by EnvironmentConfig.enableCertificatePinning.
 *  - When the flag is OFF: every method here is a no-op. No assets are loaded,
 *    no SecurityContext is created, and clients keep using normal OS-validated
 *    HTTPS. Zero behavioural change.
 *  - When the flag is ON (mobile only — kIsWeb is always skipped):
 *      * init() loads the PEM assets and builds the pinned SecurityContext.
 *      * init() throws clearly if an asset is missing/empty (fail-closed —
 *        it never silently downgrades to "trust anything").
 *      * apply(dio) routes that client through the pinned context. If the
 *        context was never initialised, the connection is refused (fail-closed),
 *        never allowed.
 *
 * Pinning on the public web target is intentionally unsupported (browsers manage
 * TLS themselves), so the web build links a no-op stub via conditional import.
 */

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/util/environment_config.dart';

// Conditional import: real dart:io implementation on mobile/desktop, no-op stub
// on web so the web build never references dart:io / SecurityContext.
import 'certificate_pinning_stub.dart'
    if (dart.library.io) 'certificate_pinning_io.dart' as impl;

class CertificatePinning {
  CertificatePinning._();

  /// True only when pinning is switched on AND we are on a platform that can
  /// enforce it (never web).
  static bool get isEnabled =>
      EnvironmentConfig.enableCertificatePinning && !kIsWeb;

  /// Loads the pinned CA certificates and builds the SecurityContext.
  /// Must be awaited once at startup before any pinned request is issued.
  ///
  /// No-op when [isEnabled] is false. Throws (fail-closed) when enabled but a
  /// certificate asset is missing or unreadable.
  static Future<void> init() async {
    if (!isEnabled) return;
    await impl.initPinning();
  }

  /// Routes [dio] through the pinned SecurityContext.
  ///
  /// Only call this for clients that talk to our own domain. No-op when
  /// [isEnabled] is false, so it is always safe to call unconditionally.
  static void apply(Dio dio) {
    if (!isEnabled) return;
    impl.applyPinning(dio);
  }
}
