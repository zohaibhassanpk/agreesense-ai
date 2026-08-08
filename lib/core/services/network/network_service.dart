import 'package:connectivity_plus/connectivity_plus.dart';

/// Network Info Class for checking connectivity
class NetworkService {
  final Connectivity _connectivity;

  NetworkService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get connectionStream {
    return _connectivity.onConnectivityChanged;
  }

  /// Bool stream that yields the **current** offline state first, then
  /// re-emits on every OS connectivity change. Prefer this over
  /// [connectionStream] in widgets — the platform stream is change-only,
  /// so users who open a screen while already offline would otherwise see
  /// the "online" default until they toggle connectivity.
  Stream<bool> get offlineStream async* {
    final initial = await _connectivity.checkConnectivity();
    yield initial.isEmpty || initial.contains(ConnectivityResult.none);
    yield* _connectivity.onConnectivityChanged.map(
      (results) => results.isEmpty || results.contains(ConnectivityResult.none),
    );
  }
}
