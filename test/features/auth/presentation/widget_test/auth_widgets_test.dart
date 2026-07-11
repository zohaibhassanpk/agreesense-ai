import 'package:agrisenseaiapp/features/auth/presentation/widgets/auth_login_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('AuthFooterText renders terms and privacy', (tester) async {
    await tester.pumpWidget(buildResponsiveTestApp(const AuthFooterText()));

    expect(find.textContaining('Terms'), findsOneWidget);
    expect(find.textContaining('Privacy'), findsOneWidget);
  });

  testWidgets('AuthGoogleButton triggers callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildResponsiveTestApp(AuthGoogleButton(onPressed: () => tapped = true)),
    );

    await tester.tap(find.byType(OutlinedButton));
    expect(tapped, isTrue);
  });
}
