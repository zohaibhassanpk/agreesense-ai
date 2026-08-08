import 'package:agrisenseaiapp/features/home/domain/entities/sensor_reading.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/smart_action.dart';
import 'package:agrisenseaiapp/features/home/presentation/widgets/home_dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('HomeSmartActionCard renders title and highlight', (
    tester,
  ) async {
    const action = SmartAction(
      title: 'Smart Action',
      message: 'Irrigate in ',
      highlight: '2 hours.',
    );

    await tester.pumpWidget(
      buildResponsiveTestApp(const HomeSmartActionCard(action: action)),
    );

    expect(find.text('Smart Action'), findsOneWidget);
    expect(find.textContaining('2 hours.'), findsOneWidget);
  });

  testWidgets('HomeSensorCard renders value and unit', (tester) async {
    const sensor = SensorReading(
      label: 'Temperature',
      value: '24',
      unit: 'C',
      icon: 'assets/svgs/temprature.svg',
      iconColorKey: 'primary',
      statusColorKey: 'primary',
    );

    await tester.pumpWidget(
      buildResponsiveTestApp(const HomeSensorCard(sensor: sensor)),
    );

    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('HomeActionButton is disabled without an online action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(
        const Row(
          children: [
            HomeActionButton(
              label: 'Pump Control',
              icon: 'assets/svgs/pump.svg',
            ),
          ],
        ),
      ),
    );

    final OutlinedButton button = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(button.onPressed, isNull);
  });
}
