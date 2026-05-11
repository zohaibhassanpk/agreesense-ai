class SensorReading {
  const SensorReading({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColorKey,
    required this.statusColorKey,
  });

  final String label;
  final String value;
  final String unit;
  final String icon;
  final String iconColorKey;
  final String statusColorKey;
}
