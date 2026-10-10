import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../constants/supabase_config.dart';
import 'network_status.dart';

class NetworkMonitor with WidgetsBindingObserver {
  NetworkMonitor._();

  static final NetworkMonitor instance = NetworkMonitor._();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;
  bool _probeInProgress = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _subscription ??= _connectivity.onConnectivityChanged.listen(
      _applyConnectivity,
      onError: (Object error) => NetworkStatus.reportFailure(error),
    );
    _probeTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_probeInternet()),
    );
    await checkNow();
    unawaited(_probeInternet());
  }

  Future<void> checkNow({bool refreshWhenOnline = false}) async {
    try {
      _applyConnectivity(
        await _connectivity.checkConnectivity(),
        refreshWhenOnline: refreshWhenOnline,
      );
    } catch (_) {
      // Supabase request failures remain the source of truth when the
      // platform connectivity check is unavailable.
    }
  }

  void _applyConnectivity(
    List<ConnectivityResult> results, {
    bool refreshWhenOnline = false,
  }) {
    final hasNetwork =
        results.any((result) => result != ConnectivityResult.none);
    final wasOffline = NetworkStatus.isOffline.value;
    NetworkStatus.setOffline(!hasNetwork);
    if ((wasOffline || refreshWhenOnline) && hasNetwork) {
      NetworkStatus.retry();
    }
    if (!hasNetwork) {
      _probeTimer?.cancel();
      _probeTimer = null;
    }
    if (hasNetwork && _probeTimer == null) {
      _probeTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(_probeInternet()),
      );
      unawaited(_probeInternet());
    }
  }

  /// Detects loss of Internet access even when Wi-Fi/mobile remains connected.
  Future<void> _probeInternet() async {
    if (_probeInProgress) return;
    _probeInProgress = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('${SupabaseConfig.url}/auth/v1/health');
      final request = await client.getUrl(uri).timeout(
        const Duration(seconds: 6),
      );
      request.headers.set('apikey', SupabaseConfig.anonKey);
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      await response.drain<void>();
      final wasOffline = NetworkStatus.isOffline.value;
      NetworkStatus.setOffline(false);
      if (wasOffline) NetworkStatus.retry();
    } catch (_) {
      NetworkStatus.setOffline(true);
    } finally {
      client.close(force: true);
      _probeInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow(refreshWhenOnline: true));
      unawaited(_probeInternet());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _probeTimer?.cancel();
      _probeTimer = null;
    }
  }
}
