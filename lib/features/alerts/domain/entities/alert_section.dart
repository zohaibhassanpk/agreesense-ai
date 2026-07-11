import 'alert_item.dart';

class AlertSection {
  const AlertSection({
    required this.label,
    required this.items,
    this.isHistorical = false,
  });

  final String label;
  final List<AlertItem> items;
  final bool isHistorical;
}
