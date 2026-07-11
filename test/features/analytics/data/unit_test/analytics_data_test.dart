import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analytics repository returns periods', () async {
    final repo = AnalyticsRepositoryImpl(
      localDataSource: AnalyticsLocalDataSourceImpl(),
    );
    final dash = await repo.getDashboard();
    expect(dash.periods.length, 3);
  });
}
