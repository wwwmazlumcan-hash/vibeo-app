import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'connectivity_probe_stub.dart'
    if (dart.library.io) 'connectivity_probe_io.dart';

/// Self-healing connectivity service.
/// Monitors internet connection and notifies listeners.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  void startMonitoring() {
    if (kIsWeb) {
      _isOnline = true;
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
    _check();
  }

  void stopMonitoring() => _timer?.cancel();

  Future<void> _check() async {
    if (kIsWeb) {
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
      return;
    }

    try {
      final online = await lookupConnection();
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  /// Retries [fn] up to [maxAttempts] times with exponential backoff.
  static Future<T?> withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(delay * attempt);
      }
    }
    return null;
  }
}

/// Shows an offline banner when no internet connection.
class OfflineWrapper extends StatefulWidget {
  final Widget child;
  const OfflineWrapper({super.key, required this.child});

  @override
  State<OfflineWrapper> createState() => _OfflineWrapperState();
}

class _OfflineWrapperState extends State<OfflineWrapper> {
  final _svc = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _svc.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_svc.isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red.shade800,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'İnternet bağlantısı yok — otomatik yeniden bağlanıyor',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
