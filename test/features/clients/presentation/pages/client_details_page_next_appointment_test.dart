import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/clients/application/models/client_next_appointment_preview.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_next_appointment_section.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('ClientDetailsPage next appointment', () {
    late _FakeClientMemoryRepository memoryRepository;

    setUp(() {
      memoryRepository = _FakeClientMemoryRepository();
    });

    Future<void> pumpPage(
      WidgetTester tester, {
      required Future<ClientNextAppointmentPreview?> Function() load,
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(memoryRepository),
            clientNextAppointmentProvider('client-1').overrideWith((ref) {
              return load();
            }),
          ],
          child: MaterialApp(home: ClientDetailsPage(client: _client())),
        ),
      );

      await tester.pump();
    }

    testWidgets('exibe skeleton estável durante loading', (tester) async {
      final completer = Completer<ClientNextAppointmentPreview?>();

      await pumpPage(tester, load: () => completer.future);

      expect(find.text(AppStrings.clientNextAppointment), findsOneWidget);
      expect(
        find.byKey(ClientNextAppointmentSection.nextAppointmentSkeletonLineKey),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('exibe erro e retry invalida provider', (tester) async {
      var loadCount = 0;

      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(memoryRepository),
            clientNextAppointmentProvider('client-1').overrideWith((ref) async {
              loadCount++;
              if (loadCount == 1) {
                throw StateError('Falha simulada');
              }
              return null;
            }),
          ],
          child: MaterialApp(home: ClientDetailsPage(client: _client())),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.clientNextAppointmentLoadError),
        findsOneWidget,
      );
      expect(find.text(AppStrings.tryAgain), findsOneWidget);
      expect(
        find.text(AppStrings.clientNextAppointmentComingSoon),
        findsNothing,
      );
      expect(
        find.byKey(ClientNextAppointmentSection.nextAppointmentSkeletonLineKey),
        findsNothing,
      );

      await tester.tap(find.text(AppStrings.tryAgain));
      await tester.pumpAndSettle();

      expect(loadCount, 2);
      expect(find.text(AppStrings.clientNextAppointmentEmpty), findsOneWidget);
    });

    testWidgets('exibe vazio sem placeholder Em breve', (tester) async {
      await pumpPage(tester, load: () => Future.value(null));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.clientNextAppointmentEmpty), findsOneWidget);
      expect(
        find.text(AppStrings.clientNextAppointmentComingSoon),
        findsNothing,
      );
    });

    testWidgets('renderiza appointment real com dados corretos', (
      tester,
    ) async {
      final startAt = DateTime.now().add(const Duration(hours: 2));
      final endAt = startAt.add(const Duration(hours: 1));
      final preview = ClientNextAppointmentPreview(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        clientName: 'Maria',
        professionalName: 'Carla',
        servicesSummary: 'Corte + Coloração',
        startAt: startAt,
        endAt: endAt,
        status: AppointmentStatus.confirmed,
        operationalState: AppointmentOperationalState.upcoming,
      );

      await pumpPage(tester, load: () => Future.value(preview));
      await tester.pumpAndSettle();

      expect(find.text(formatAppointmentDateLabel(startAt)), findsOneWidget);
      expect(
        find.textContaining(formatAppointmentClockTime(startAt)),
        findsOneWidget,
      );
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('Corte + Coloração'), findsOneWidget);
      expect(
        find.text(AppStrings.clientNextAppointmentComingSoon),
        findsNothing,
      );
      expect(
        find.byKey(ClientNextAppointmentSection.nextAppointmentSkeletonLineKey),
        findsNothing,
      );
    });
  });

  group('ClientNextAppointmentSection layout', () {
    testWidgets('skeleton respeita largura reduzida e text scale', (
      tester,
    ) async {
      final completer = Completer<ClientNextAppointmentPreview?>();

      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: ProviderScope(
            overrides: [
              clientNextAppointmentProvider('client-1').overrideWith((ref) {
                return completer.future;
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ClientNextAppointmentSection(clientId: 'client-1'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(ClientNextAppointmentSection.nextAppointmentSkeletonLineKey),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ClientNextAppointmentSection temporal refresh', () {
    testWidgets('invalida provider após endAt', (tester) async {
      var loadCount = 0;
      final now = DateTime.now();
      final startAt = now.subtract(const Duration(minutes: 10));
      final endAt = now.add(const Duration(milliseconds: 300));
      final preview = ClientNextAppointmentPreview(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        clientName: 'Maria',
        professionalName: 'Carla',
        servicesSummary: 'Corte',
        startAt: startAt,
        endAt: endAt,
        status: AppointmentStatus.confirmed,
        operationalState: AppointmentOperationalState.current,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientNextAppointmentProvider('client-1').overrideWith((ref) async {
              loadCount++;
              if (loadCount == 1) {
                return preview;
              }
              return null;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientNextAppointmentSection(clientId: 'client-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Carla'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(loadCount, greaterThanOrEqualTo(2));
      expect(find.text(AppStrings.clientNextAppointmentEmpty), findsOneWidget);
    });
  });
}

Client _client() {
  final now = DateTime(2026, 7, 8);

  return Client(
    id: 'client-1',
    name: 'Maria',
    phone: '11999999999',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
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
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

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
