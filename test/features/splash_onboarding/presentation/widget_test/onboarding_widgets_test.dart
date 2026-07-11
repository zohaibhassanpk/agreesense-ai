import 'package:agrisenseaiapp/features/splash_onboarding/presentation/widgets/onboarding_control_widgets.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/presentation/widgets/splash_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('SplashTitle and SplashTagline render', (tester) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(
        const Column(children: [SplashTitle(), SplashTagline()]),
      ),
    );

    expect(find.textContaining('AgriSense'), findsOneWidget);
    expect(find.text('SMART FARMING WITH AI'), findsOneWidget);
  });

  testWidgets('OnboardingSkipButton respects visibility', (tester) async {
    await tester.pumpWidget(
      buildResponsiveTestApp(const OnboardingSkipButton(isVisible: false)),
    );
    final hiddenVisibility = tester.widget<Visibility>(find.byType(Visibility));
    expect(hiddenVisibility.visible, isFalse);

    await tester.pumpWidget(
      buildResponsiveTestApp(const OnboardingSkipButton(isVisible: true)),
    );
    final visibleVisibility = tester.widget<Visibility>(
      find.byType(Visibility),
    );
    expect(visibleVisibility.visible, isTrue);
  });

  testWidgets('OnboardingPrimaryButton tap works', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildResponsiveTestApp(
        OnboardingPrimaryButton(
          label: 'Next',
          iconAsset: 'assets/svgs/forward_arrow.svg',
          onPressed: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });
}
