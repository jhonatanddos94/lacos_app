import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/clients/application/controllers/client_form_controller.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

import '../../../../helpers/in_memory_client_repository.dart';

void main() {
  final now = DateTime(2026, 8, 13);

  Client maria({bool isFavorite = true}) {
    return Client(
      id: 'client-1',
      name: 'Maria Lima',
      phone: '11999990000',
      instagram: 'maria.lima',
      isActive: true,
      isFavorite: isFavorite,
      clientSince: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('H: favoritar persiste sem criar outra cliente', () async {
    final repository = InMemoryClientRepository(clients: [maria(isFavorite: false)]);
    final controller = ClientFormController(repository);

    final updated = await controller.setFavorite(
      client: maria(isFavorite: false),
      isFavorite: true,
    );

    expect(updated?.isFavorite, isTrue);
    expect(updated?.id, 'client-1');
    expect(repository.clients, hasLength(1));
    expect(repository.clients.single.isFavorite, isTrue);
    expect(repository.updateCalls, 1);
  });

  test('I: desfavoritar persiste', () async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    final controller = ClientFormController(repository);

    final updated = await controller.setFavorite(
      client: maria(),
      isFavorite: false,
    );

    expect(updated?.isFavorite, isFalse);
    expect(repository.clients.single.isFavorite, isFalse);
  });

  test('L/M: update preserva objectId e isActive', () async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    final controller = ClientFormController(repository);

    final updated = await controller.setFavorite(
      client: maria(),
      isFavorite: false,
    );

    expect(updated?.id, 'client-1');
    expect(updated?.isActive, isTrue);
    expect(updated?.name, 'Maria Lima');
    expect(updated?.phone, '11999990000');
    expect(updated?.instagram, 'maria.lima');
    expect(updated?.createdAt, now);
  });

  test('N: loading impede segundo tap de favoritar', () async {
    final repository = InMemoryClientRepository(clients: [maria(isFavorite: false)]);
    repository.updateCompleter = Completer<void>();
    final controller = ClientFormController(repository);

    final first = controller.setFavorite(
      client: maria(isFavorite: false),
      isFavorite: true,
    );
    final second = await controller.setFavorite(
      client: maria(isFavorite: false),
      isFavorite: true,
    );

    expect(second, isNull);
    expect(repository.updateCalls, 1);

    repository.updateCompleter!.complete();
    final updated = await first;
    expect(updated?.isFavorite, isTrue);
  });

  test('O: erro de update é sanitizado', () async {
    final repository = InMemoryClientRepository(clients: [maria(isFavorite: false)]);
    repository.updateError = Exception('socket hang up 192.168.0.12');
    final controller = ClientFormController(repository);

    final updated = await controller.setFavorite(
      client: maria(isFavorite: false),
      isFavorite: true,
    );

    expect(updated, isNull);
    expect(controller.state.hasError, isTrue);
    expect(
      (controller.state.error as FormatException).message,
      contains(AppValidationMessages.unexpectedError),
    );
    expect(
      (controller.state.error as FormatException).message,
      isNot(contains('192.168')),
    );
  });

  test('R: novo Client default não é favorita', () async {
    final repository = InMemoryClientRepository();
    final controller = ClientFormController(repository);

    final created = await controller.save(
      name: 'Ana',
      phone: '11988887777',
    );

    expect(created?.isFavorite, isFalse);
    expect(repository.clients.single.isFavorite, isFalse);
  });

  test('S: edição normal não perde isFavorite', () async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    final controller = ClientFormController(repository);

    final updated = await controller.save(
      initialClient: maria(),
      name: 'Maria Lima Souza',
      phone: '11999990000',
      instagram: 'maria.lima',
    );

    expect(updated?.isFavorite, isTrue);
    expect(updated?.name, 'Maria Lima Souza');
    expect(repository.clients.single.isFavorite, isTrue);
  });

  test('Q: isFavorite ausente no domínio equivale a false', () {
    final client = Client(
      id: 'legacy',
      name: 'Helena',
      phone: '11911112222',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    expect(client.isFavorite, isFalse);
  });
}
