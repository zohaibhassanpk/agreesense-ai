import 'package:agrisenseaiapp/features/settings/presentation/widgets/settings_section_label.dart';
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
}
