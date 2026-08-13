import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/services/application/services/service_catalog_filter.dart';

import '../../helpers/fake_service_repository.dart';

void main() {
  final corte = buildTestService(id: '1', name: 'Corte feminino');
  final hidratacao = buildTestService(id: '2', name: 'Hidratação');
  final coloracao = buildTestService(id: '3', name: 'Coloração');
  final services = [coloracao, corte, hidratacao];

  test('query vazia preserva a lista e a ordem', () {
    expect(filterServicesByName(services, ''), services);
    expect(filterServicesByName(services, '   '), services);
  });

  test('filtra por substring case-insensitive e trim', () {
    expect(
      filterServicesByName(services, '  HIDRA  ').map((service) => service.id),
      ['2'],
    );
    expect(
      filterServicesByName(services, 'corte').map((service) => service.id),
      ['1'],
    );
  });

  test('preserva a ordem A–Z da lista base', () {
    expect(filterServicesByName(services, 'a').map((service) => service.name), [
      'Coloração',
      'Hidratação',
    ]);
  });

  test('sem correspondência devolve lista vazia', () {
    expect(filterServicesByName(services, 'manicure'), isEmpty);
  });
}
