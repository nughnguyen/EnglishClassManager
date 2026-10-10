import 'package:flutter/foundation.dart';

/// Updated whenever a Supabase request confirms or loses connectivity.
class NetworkStatus {
  NetworkStatus._();

  static final ValueNotifier<bool> isOffline = ValueNotifier(false);
  static final ValueNotifier<int> dataRevision = ValueNotifier(0);
  static VoidCallback? onRetry;

  static void reportFailure(Object error) {
    final message = error.toString().toLowerCase();
    final networkFailure = [
      'socketexception',
      'clientexception',
      'handshakeexception',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'connection closed',
      'network is unreachable',
      'timed out',
      'timeout',
      'no address associated',
      'failed to fetch',
      'xmlhttprequest error',
      'network request failed',
    ].any(message.contains);
    if (networkFailure) setOffline(true);
  }

  static void setOffline(bool value) {
    if (isOffline.value != value) isOffline.value = value;
  }

  static void reportDataUpdated() => dataRevision.value++;

  static void retry() => onRetry?.call();
}
