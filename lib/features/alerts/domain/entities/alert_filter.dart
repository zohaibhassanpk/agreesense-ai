enum AlertFilterType { all, critical, warnings }

class AlertFilter {
  const AlertFilter({required this.type, required this.label});

  final AlertFilterType type;
  final String label;
}
