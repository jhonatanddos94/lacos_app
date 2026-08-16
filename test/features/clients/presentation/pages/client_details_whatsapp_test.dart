import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/external_url/external_url_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

import '../../../../helpers/fake_external_url_launcher.dart';
import '../../../../helpers/in_memory_client_repository.dart';

void main() {
  final now = DateTime(2026, 8, 14);

  Client josefa({String phone = '67999999999'}) {
    return Client(
      id: 'client-1',
      name: 'Josefa Souza',
      phone: phone,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<InMemoryClientRepository> pumpDetails(
    WidgetTester tester, {
    required FakeExternalUrlLauncher launcher,
    Client? client,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final resolvedClient = client ?? josefa();
    final repository = InMemoryClientRepository(clients: [resolvedClient]);
    final memoryRepository = _FakeClientMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientRepositoryProvider.overrideWithValue(repository),
          clientMemoryRepositoryProvider.overrideWithValue(memoryRepository),
          externalUrlLauncherProvider.overrideWithValue(launcher),
          clientServiceHistoryProvider('client-1').overrideWith(
            (ref) async => const [],
          ),
          clientNextAppointmentProvider('client-1').overrideWith(
            (ref) async => null,
          ),
        ],
        child: MaterialApp(home: ClientDetailsPage(client: resolvedClient)),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  Finder whatsappAction() => find.byKey(ClientDetailsPage.whatsappActionKey);

  Finder phoneRowWhatsappIcon() => find.descendant(
    of: find.byKey(ClientDetailsPage.phoneRowKey),
    matching: find.byType(IconButton),
  );

  testWidgets('A/B/C/D/F/G/N: tap abre wa.me com saudação', (tester) async {
    final launcher = FakeExternalUrlLauncher();
    await pumpDetails(tester, launcher: launcher);

    expect(find.text(AppStrings.whatsapp), findsOneWidget);
    expect(find.text(AppStrings.talk), findsOneWidget);
    expect(whatsappAction(), findsOneWidget);

    await tester.tap(whatsappAction());
    await tester.pumpAndSettle();

    expect(launcher.calls, 1);
    final uri = launcher.launchedUris.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/5567999999999');
    expect(uri.queryParameters['text'], 'Olá, Josefa! Tudo bem?');

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('B: ícone do WhatsApp no telefone usa a mesma ação', (
    tester,
  ) async {
    final launcher = FakeExternalUrlLauncher();
    await pumpDetails(
      tester,
      launcher: launcher,
      client: josefa(phone: '(67) 99999-9999'),
    );

    await tester.tap(phoneRowWhatsappIcon());
    await tester.pumpAndSettle();

    expect(launcher.launchedUris.single.path, '/5567999999999');
  });

  testWidgets('K/L/M: telefone inválido não chama launcher', (tester) async {
    final launcher = FakeExternalUrlLauncher();
    await pumpDetails(tester, launcher: launcher, client: josefa(phone: '123'));

    await tester.tap(whatsappAction());
    await tester.pumpAndSettle();

    expect(launcher.calls, 0);
    expect(find.text(AppStrings.clientWhatsappInvalidPhone), findsOneWidget);
    expect(find.text('Josefa Souza'), findsOneWidget);
  });

  testWidgets('O/P: falha e exception mostram fallback sanitizado', (
    tester,
  ) async {
    final launcher = FakeExternalUrlLauncher(result: false);
    await pumpDetails(tester, launcher: launcher);

    await tester.tap(whatsappAction());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clientWhatsappOpenError), findsOneWidget);

    launcher.error = Exception('PlatformException wa.me channel');
    await tester.tap(whatsappAction());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clientWhatsappOpenError), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('wa.me'), findsNothing);
  });

  testWidgets('Q: duplo toque não abre duas vezes', (tester) async {
    final launcher = FakeExternalUrlLauncher()..completer = Completer<bool>();
    await pumpDetails(tester, launcher: launcher);

    await tester.tap(whatsappAction());
    await tester.pump();
    await tester.tap(whatsappAction());
    await tester.pump();

    expect(launcher.calls, 1);

    launcher.completer!.complete(true);
    await tester.pumpAndSettle();
    expect(launcher.calls, 1);
  });

  testWidgets('S/T/U/V/W: sem query, sem escrita e ficha preservada', (
    tester,
  ) async {
    final launcher = FakeExternalUrlLauncher();
    final repository = await pumpDetails(tester, launcher: launcher);
    final findAllBefore = repository.findAllCalls;

    await tester.tap(whatsappAction());
    await tester.pumpAndSettle();

    expect(repository.findAllCalls, findAllBefore);
    expect(repository.updateCalls, 0);
    expect(repository.createCalls, 0);
    expect(repository.deleteCalls, 0);
    expect(repository.clients.single.name, 'Josefa Souza');
    expect(repository.clients.single.phone, '67999999999');
    expect(repository.clients.single.updatedAt, now);

    expect(find.text(AppStrings.clientDetailsTitle), findsOneWidget);
    expect(find.text('Josefa Souza'), findsOneWidget);
    expect(find.text(AppStrings.whatsapp), findsOneWidget);
  });
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  int createCalls = 0;

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    return const [];
  }

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) {
    createCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();
}
