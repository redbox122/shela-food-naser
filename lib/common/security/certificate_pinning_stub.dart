/*
 * Certificate Pinning — web stub.
 *
 * Pinning relies on dart:io's SecurityContext, which does not exist on web,
 * and browsers manage TLS validation themselves. This stub is linked on web
 * via conditional import so the web build never references dart:io. The facade
 * (CertificatePinning) also guards with !kIsWeb, so these are belt-and-braces
 * no-ops that should never run on web anyway.
 */

import 'package:dio/dio.dart';

/// No-op on web: there is nothing to load.
Future<void> initPinning() async {}

/// No-op on web: requests use the browser's own TLS stack.
void applyPinning(Dio dio) {}
