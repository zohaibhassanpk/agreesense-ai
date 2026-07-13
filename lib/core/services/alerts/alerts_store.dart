import 'package:flutter/foundation.dart';

import '../../../features/alerts/domain/entities/alert_item.dart';

/// Holds the bounded list of alerts generated during the current app session.
class AlertsStore extends ChangeNotifier {
  static const int maxItems = 50;

  final List<AlertItem> _liveItems = <AlertItem>[];

  /// Returns an immutable snapshot of the current live alerts.
  List<AlertItem> get liveItems => List<AlertItem>.unmodifiable(_liveItems);

  /// Adds [item] newest-first and evicts the oldest item when at capacity.
  void addAlert(AlertItem item) {
    _liveItems.insert(0, item);
    if (_liveItems.length > maxItems) {
      _liveItems.removeLast();
    }
    notifyListeners();
  }
}
