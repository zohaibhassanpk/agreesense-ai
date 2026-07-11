enum DeviceItemType {
  paired,
  available,
}

class DeviceItem {
  const DeviceItem({
    required this.name,
    required this.statusText,
    required this.icon,
    required this.type,
    required this.isConnected,
  });

  final String name;
  final String statusText;
  final String icon;
  final DeviceItemType type;
  final bool isConnected;
}
