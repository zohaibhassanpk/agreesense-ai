import 'package:agrisenseaiapp/features/devices/domain/entities/device_item.dart';
import 'package:agrisenseaiapp/features/devices/presentation/widgets/available_device_card.dart';
import 'package:agrisenseaiapp/features/devices/presentation/widgets/device_section_label.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('DeviceSectionLabel renders uppercase', (tester) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(
        const DeviceSectionLabel(label: 'Available devices'),
      ),
    );

    expect(find.text('AVAILABLE DEVICES'), findsOneWidget);
  });

  testWidgets('AvailableDeviceCard renders name and button', (tester) async {
    const device = DeviceItem(
      name: 'AgriSensor_B2',
      statusText: 'Ready to pair',
      icon: 'assets/svgs/squarebluetooth.svg',
      type: DeviceItemType.available,
      isConnected: false,
    );

    await tester.pumpWidget(
      buildResponsiveTestApp(const AvailableDeviceCard(device: device)),
    );

    expect(find.text('AgriSensor_B2'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
