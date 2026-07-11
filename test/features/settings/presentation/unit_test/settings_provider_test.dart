import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings provider loads values', () async {
    final provider = SettingsProvider(
      repository: SettingsRepositoryImpl(
        localDataSource: SettingsLocalDataSourceImpl(),
      ),
    );
    await provider.loadSettings();
    expect(provider.minMoisture, greaterThan(0));
  });
}
