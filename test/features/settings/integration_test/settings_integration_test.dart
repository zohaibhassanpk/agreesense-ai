import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/features/settings/domain/entities/settings_dashboard.dart';
import 'package:agrisenseaiapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsDashboard> getDashboard() async {
    throw Exception('settings fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Integration', () {
    testWidgets('load and mutate values', (tester) async {
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
      );

      await provider.loadSettings();
      provider.updateMinMoisture(25);
      provider.updateMaxTemperature(31);
      provider.togglePushNotifications(false);

      expect(provider.minMoisture, 25);
      expect(provider.maxTemperature, 31);
      expect(provider.pushNotificationsEnabled, isFalse);
    });

    testWidgets('load failure produces error', (tester) async {
      final provider = SettingsProvider(
        repository: _FailingSettingsRepository(),
      );

      await provider.loadSettings();
      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load settings.');
    });
  });
}
