import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alerts provider loads filters', () async {
    final provider = AlertsProvider(
      repository: AlertsRepositoryImpl(
        localDataSource: AlertsLocalDataSourceImpl(),
      ),
    );
    await provider.loadAlerts();
    expect(provider.filters, isNotEmpty);
  });
}
