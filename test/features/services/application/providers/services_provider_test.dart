import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/services/application/providers/service_providers.dart';

import '../../helpers/fake_service_repository.dart';

void main() {
  test('servicesProvider devolve lista vazia do repositório', () async {
    final repository = FakeServiceRepository();
    final container = ProviderContainer(
      overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final services = await container.read(servicesProvider.future);

    expect(services, isEmpty);
    expect(repository.findAllCallCount, 1);
  });

  test('servicesProvider devolve serviços ativos ordenados por nome', () async {
    final repository = FakeServiceRepository(
      seed: [
        buildTestService(id: '2', name: 'Hidratação', price: 120),
        buildTestService(id: '1', name: 'Corte feminino', price: 80),
        buildTestService(id: '3', name: 'Coloração antiga', isActive: false),
      ],
    );
    final container = ProviderContainer(
      overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final services = await container.read(servicesProvider.future);

    expect(services.map((service) => service.name), [
      'Corte feminino',
      'Hidratação',
    ]);
    expect(repository.findAllCallCount, 1);
  });

  test('servicesProvider propaga erro do repositório', () async {
    final repository = FakeServiceRepository(
      findAllError: Exception('falha de rede'),
    );
    final container = ProviderContainer(
      overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(servicesProvider.future),
      throwsA(isA<Exception>()),
    );
    expect(repository.findAllCallCount, 1);
  });
}
