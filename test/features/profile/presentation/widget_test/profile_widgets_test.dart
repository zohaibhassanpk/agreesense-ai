import 'package:agrisenseaiapp/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:agrisenseaiapp/features/profile/presentation/widgets/profile_logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('ProfileInfoCard renders label and value', (tester) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(
        const ProfileInfoCard(
          label: 'Selected Crop',
          value: 'Tobacco',
          icon: 'assets/svgs/leaf.svg',
        ),
      ),
    );

    expect(find.text('Selected Crop'), findsOneWidget);
    expect(find.text('Tobacco'), findsOneWidget);
  });

  testWidgets('ProfileLogoutButton triggers callback', (tester) async {
    var called = false;
    await tester.pumpWidget(
      buildResponsiveTestApp(
        ProfileLogoutButton(label: 'Log Out', onPressed: () => called = true),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(called, isTrue);
  });
}
