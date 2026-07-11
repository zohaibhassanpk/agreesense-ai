import '../../domain/entities/device_item.dart';

class DeviceItemModel extends DeviceItem {
  const DeviceItemModel({
    required super.name,
    required super.statusText,
    required super.icon,
    required super.type,
    required super.isConnected,
  });
}
