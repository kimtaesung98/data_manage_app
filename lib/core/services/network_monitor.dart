import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  NetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_hasConnection(results));
    });
  }

  static bool _hasConnection(List<ConnectivityResult> results) => results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );

  Stream<bool> get onlineStream => _controller.stream;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
