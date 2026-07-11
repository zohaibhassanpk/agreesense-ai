import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home repository returns dashboard', () async {
    final repo = HomeRepositoryImpl(localDataSource: HomeLocalDataSourceImpl());
    final dash = await repo.getDashboard();
    expect(dash.sensors, isNotEmpty);
  });
}
