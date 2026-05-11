import 'no_internet_widget.dart';
import 'package:flutter/material.dart';
import '../../services/network/network_service.dart';
import 'package:agrisenseaiapp/app/injection_container.dart';

/// Reactive wrapper that swaps between [child] and [NoInternetWidget]
/// based on the device's connectivity.
///
/// Listens to [NetworkService.offlineStream], which yields the current
/// offline state first and then live-updates on every OS change. The
/// [onRetry] callback is invoked when the user taps the retry button on
/// [NoInternetWidget] — callers typically pass their provider's refresh
/// method so data reloads the moment connectivity returns.
class ConnectivityGate extends StatelessWidget {
  final Widget child;
  final VoidCallback onRetry;

  const ConnectivityGate({
    super.key,
    required this.child,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: di<NetworkService>().offlineStream,
      builder: (context, snap) {
        final offline = snap.data ?? false;
        if (offline) {
          return NoInternetWidget(onRetry: onRetry);
        }
        return child;
      },
    );
  }
}
