import 'package:agrisenseaiapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:agrisenseaiapp/features/settings/presentation/widgets/settings_threshold_card.dart';
import 'package:agrisenseaiapp/features/settings/presentation/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('SettingsSectionLabel renders uppercase text', (tester) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(const SettingsSectionLabel(label: 'Thresholds')),
    );

    expect(find.text('THRESHOLDS'), findsOneWidget);
  });

  testWidgets('SettingsToggle toggles on tap', (tester) async {
    var value = false;
    await tester.pumpWidget(
      buildResponsiveTestApp(
        SettingsToggle(value: value, onChanged: (next) => value = next),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(value, isTrue);
  });

  testWidgets('SettingsThresholdCard renders all canonical overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(
        SettingsThresholdCard(
          temperatureRange: const RangeValues(20, 30),
          humidityRange: const RangeValues(60, 75),
          moistureRange: const RangeValues(60, 85),
          lightRange: const RangeValues(45000, 70000),
          onTemperatureChanged: (_) {},
          onTemperatureChangeEnd: (_) {},
          onHumidityChanged: (_) {},
          onHumidityChangeEnd: (_) {},
          onMoistureChanged: (_) {},
          onMoistureChangeEnd: (_) {},
          onLightChanged: (_) {},
          onLightChangeEnd: (_) {},
        ),
      ),
    );

    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Humidity'), findsOneWidget);
    expect(find.text('Soil Moisture'), findsOneWidget);
    expect(find.text('Light Intensity'), findsOneWidget);
    expect(find.text('Minimum Threshold'), findsNWidgets(4));
    expect(find.text('Maximum Threshold'), findsNWidgets(4));
    expect(find.byType(RangeSlider), findsNWidgets(4));
    final List<RangeSlider> sliders = tester
        .widgetList<RangeSlider>(find.byType(RangeSlider))
        .toList(growable: false);
    expect((sliders[0].min, sliders[0].max), (0, 50));
    expect((sliders[1].min, sliders[1].max), (0, 100));
    expect((sliders[2].min, sliders[2].max), (0, 100));
    expect((sliders[3].min, sliders[3].max), (0, 100000));
  });
}
