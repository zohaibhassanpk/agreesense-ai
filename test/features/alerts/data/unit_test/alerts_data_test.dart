import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alerts repository returns sections', () async {
    final repo = AlertsRepositoryImpl(
      localDataSource: AlertsLocalDataSourceImpl(),
    );
    final sections = await repo.getAlertSections();
    expect(sections.length, greaterThan(0));
  });
}
