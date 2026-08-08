import 'package:agrisenseaiapp/features/navbar/presentation/widgets/navbar_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom navigation excludes the removed Devices tab', () {
    expect(NavbarBottomBar.items.map((item) => item.label), <String>[
      'Home',
      'Alerts',
      'Analytics',
      'Settings',
    ]);
  });
}
