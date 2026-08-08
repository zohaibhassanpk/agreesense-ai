import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/widgets/alert_card.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/widgets/alert_filter_chip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('AlertFilterChip handles tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildResponsiveTestApp(
        AlertFilterChip(
          label: 'Critical',
          isSelected: true,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Critical'));
    expect(tapped, isTrue);
  });

  testWidgets('AlertCard renders alert content', (tester) async {
    final alert = AlertItem(
      title: 'Low Soil Moisture',
      message: 'Moisture dropped below threshold.',
      recommendedAction:
          'Inspect tobacco roots and the irrigation system before watering.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      severity: AlertSeverity.warning,
      icon: 'assets/svgs/drop.svg',
    );

    await tester.pumpWidget(buildResponsiveTestApp(AlertCard(alert: alert)));

    expect(find.text('Low Soil Moisture'), findsOneWidget);
    expect(find.text('Severity: Warning'), findsOneWidget);
    expect(find.text('Recommended action'), findsOneWidget);
    expect(find.textContaining('Inspect tobacco roots'), findsOneWidget);
    expect(find.text('1 hour ago'), findsOneWidget);
  });
}
