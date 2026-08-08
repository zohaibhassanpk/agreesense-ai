import 'dart:async';

import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/home_dashboard.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/smart_action.dart';
import 'package:agrisenseaiapp/features/home/domain/repositories/home_repository.dart';
import 'package:agrisenseaiapp/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeRepository implements HomeRepository {
  final StreamController<HomeDashboard> dashboards =
      StreamController<HomeDashboard>.broadcast(sync: true);
  Completer<void>? pumpWrite;
  Object? pumpError;
  final List<bool> pumpWrites = <bool>[];

  @override
  Future<HomeDashboard> getDashboard() async => _dashboard();

  @override
  Future<void> setPumpStatus(bool isOn) async {
    pumpWrites.add(isOn);
    final Object? error = pumpError;
    if (error != null) {
      throw error;
    }
    await pumpWrite?.future;
  }

  @override
  Stream<HomeDashboard> watchDashboard() => dashboards.stream;

  Future<void> close() => dashboards.close();
}

HomeDashboard _dashboard({bool pumpOn = false, bool deviceOnline = true}) {
  return HomeDashboard(
    greeting: 'Welcome back',
    fieldName: 'Field 01',
    connectionStatus: 'Device Online',
    smartAction: const SmartAction(
      title: 'Smart Action',
      message: 'Conditions are ',
      highlight: 'healthy.',
    ),
    updatedLabel: 'Updated now',
    sensors: const [],
    deviceStatus: deviceOnline ? DeviceStatus.online : DeviceStatus.offline,
    pumpOn: pumpOn,
  );
}

void main() {
  test('home provider loads dashboard', () async {
    final provider = HomeProvider(
      repository: HomeRepositoryImpl(
        localDataSource: HomeLocalDataSourceImpl(),
      ),
    );
    await provider.loadDashboard();
    expect(provider.dashboard, isNotNull);
  });

  test('pump status updates optimistically and writes to Firebase', () async {
    final _FakeHomeRepository repository = _FakeHomeRepository();
    final HomeProvider provider = HomeProvider(repository: repository);
    final Future<void> load = provider.loadDashboard();
    await Future<void>.delayed(Duration.zero);
    repository.dashboards.add(_dashboard());
    await load;

    repository.pumpWrite = Completer<void>();
    final Future<bool> write = provider.setPumpStatus(true);

    expect(provider.dashboard?.pumpOn, isTrue);
    expect(provider.isPumpUpdating, isTrue);
    expect(repository.pumpWrites, <bool>[true]);

    repository.pumpWrite!.complete();
    expect(await write, isTrue);
    expect(provider.dashboard?.pumpOn, isTrue);
    expect(provider.isPumpUpdating, isFalse);

    provider.dispose();
    await repository.close();
  });

  test(
    'failed pump write rolls UI back to the latest Firebase value',
    () async {
      final _FakeHomeRepository repository = _FakeHomeRepository();
      final HomeProvider provider = HomeProvider(repository: repository);
      final Future<void> load = provider.loadDashboard();
      await Future<void>.delayed(Duration.zero);
      repository.dashboards.add(_dashboard());
      await load;
      repository.pumpError = StateError('permission denied');

      final Future<bool> write = provider.setPumpStatus(true);
      expect(provider.dashboard?.pumpOn, isTrue);

      expect(await write, isFalse);
      expect(provider.dashboard?.pumpOn, isFalse);
      expect(provider.isPumpUpdating, isFalse);

      provider.dispose();
      await repository.close();
    },
  );

  test('external Firebase pump changes update the provider', () async {
    final _FakeHomeRepository repository = _FakeHomeRepository();
    final HomeProvider provider = HomeProvider(repository: repository);
    final Future<void> load = provider.loadDashboard();
    await Future<void>.delayed(Duration.zero);
    repository.dashboards.add(_dashboard());
    await load;

    repository.dashboards.add(_dashboard(pumpOn: true));
    expect(provider.dashboard?.pumpOn, isTrue);
    repository.dashboards.add(_dashboard());
    expect(provider.dashboard?.pumpOn, isFalse);

    provider.dispose();
    await repository.close();
  });

  test('offline dashboard blocks pump writes', () async {
    final _FakeHomeRepository repository = _FakeHomeRepository();
    final HomeProvider provider = HomeProvider(repository: repository);
    final Future<void> load = provider.loadDashboard();
    await Future<void>.delayed(Duration.zero);
    repository.dashboards.add(_dashboard(deviceOnline: false));
    await load;

    expect(provider.canControlPump, isFalse);
    expect(await provider.setPumpStatus(true), isFalse);
    expect(repository.pumpWrites, isEmpty);
    expect(provider.dashboard?.pumpOn, isFalse);

    provider.dispose();
    await repository.close();
  });
}
