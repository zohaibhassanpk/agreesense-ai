import '../../domain/entities/sensor_reading.dart';

class SensorReadingModel extends SensorReading {
  const SensorReadingModel({
    required super.label,
    required super.value,
    required super.unit,
    required super.icon,
    required super.iconColorKey,
    required super.statusColorKey,
  });
}
