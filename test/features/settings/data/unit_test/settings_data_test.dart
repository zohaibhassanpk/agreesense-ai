import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings repository returns dashboard', () async {
    final repo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(),
    );
    final dash = await repo.getDashboard();
    expect(dash.selectedCrop, isNotEmpty);
  });
}
