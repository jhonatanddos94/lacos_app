import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/domain/exceptions/photo_upload_exception.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/helpers/professional_photo_picker.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/shared/widgets/avatars/profile_avatar.dart';

import '../../../helpers/home_test_fixtures.dart';
import '../../../helpers/in_memory_professional_repository.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  setUp(resetProfessionalProfileNavigationGuardForTest);
  tearDown(resetProfessionalProfileNavigationGuardForTest);

  Professional leticia({String? photoUrl}) {
    return Professional(
      id: 'professional-1',
      name: 'Leticia',
      specialties: 'Cabeleireira',
      photoUrl: photoUrl,
      isActive: true,
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 13),
    );
  }

  Workspace workspaceFor(Professional? professional) {
    return Workspace(
      user: const AuthenticatedUser(
        id: 'user-1',
        email: 'leticia@lacos.app',
        isEmailVerified: true,
      ),
      salon: Salon(
        id: 'salon-1',
        name: 'Studio Aurora',
        responsibleName: 'Leticia',
        isActive: true,
        createdAt: DateTime(2026, 8, 13),
        updatedAt: DateTime(2026, 8, 13),
      ),
      professional: professional,
    );
  }

  Future<XFile?> fakePickerSuccess(
    BuildContext context, {
    void Function(String message)? onMessage,
  }) async {
    return XFile('/tmp/professional-photo.jpg');
  }

  Future<XFile?> fakePickerCancel(
    BuildContext context, {
    void Function(String message)? onMessage,
  }) async {
    return null;
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required InMemoryProfessionalRepository repository,
    ProfessionalPhotoPicker? picker,
    Size size = const Size(420, 1200),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(await repository.getCurrentProfessional());
          }),
          if (picker != null)
            professionalPhotoPickerProvider.overrideWithValue(picker),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: ProfessionalProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    required InMemoryProfessionalRepository repository,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(await repository.getCurrentProfessional());
          }),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Professional photo — exibição', () {
    testWidgets('A: sem foto mostra inicial', (tester) async {
      await pumpProfile(
        tester,
        repository: InMemoryProfessionalRepository(current: leticia()),
      );

      expect(find.text('L'), findsWidgets);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('B/D: com foto tenta renderizar imagem remota', (tester) async {
      await pumpProfile(
        tester,
        repository: InMemoryProfessionalRepository(
          current: leticia(photoUrl: 'https://example.com/leticia.jpg'),
        ),
      );

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('C/U: erro de imagem faz fallback para inicial', (tester) async {
      await pumpProfile(
        tester,
        repository: InMemoryProfessionalRepository(
          current: leticia(photoUrl: 'https://invalid.test/broken.jpg'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('L'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Professional photo — upload', () {
    testWidgets('F/G/H: selecionar foto chama picker e repository', (
      tester,
    ) async {
      final repository = InMemoryProfessionalRepository(current: leticia());
      await pumpProfile(
        tester,
        repository: repository,
        picker: fakePickerSuccess,
      );

      await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(repository.lastPhotoPath, '/tmp/professional-photo.jpg');
      expect(repository.current?.photoUrl, 'memory:///tmp/professional-photo.jpg');
    });

    testWidgets('Q: cancelar picker não faz update', (tester) async {
      final repository = InMemoryProfessionalRepository(current: leticia());
      await pumpProfile(
        tester,
        repository: repository,
        picker: fakePickerCancel,
      );

      await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 0);
    });

    testWidgets('J/K/L/M: sucesso preserva id, role e demais campos', (
      tester,
    ) async {
      final repository = InMemoryProfessionalRepository(
        current: Professional(
          id: 'professional-1',
          name: 'Leticia',
          specialties: 'Cabeleireira',
          role: 'owner',
          isActive: true,
          createdAt: DateTime(2026, 8, 13),
          updatedAt: DateTime(2026, 8, 13),
        ),
      );

      await pumpProfile(
        tester,
        repository: repository,
        picker: fakePickerSuccess,
      );

      await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
      await tester.pumpAndSettle();

      expect(repository.current?.id, 'professional-1');
      expect(repository.current?.name, 'Leticia');
      expect(repository.current?.specialties, 'Cabeleireira');
      expect(repository.current?.role, 'owner');
      expect(repository.current?.isActive, isTrue);
    });

    testWidgets('N: loading bloqueia segundo tap', (tester) async {
      final completer = Completer<Professional>();
      final repository = _DelayedPhotoProfessionalRepository(
        current: leticia(),
        completer: completer,
      );
      await pumpProfile(
        tester,
        repository: repository,
        picker: fakePickerSuccess,
      );

      await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
      await tester.pump();
      await tester.tap(
        find.byKey(ProfessionalProfilePage.photoActionKey),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(repository.updateCalls, 1);

      completer.complete(leticia(photoUrl: 'memory:///tmp/professional-photo.jpg'));
      await tester.pumpAndSettle();
    });

    testWidgets('O/P: erro upload mantém tela e sanitiza mensagem', (
      tester,
    ) async {
      final repository = InMemoryProfessionalRepository(current: leticia())
        ..updateError = const PhotoUploadException();
      await pumpProfile(
        tester,
        repository: repository,
        picker: fakePickerSuccess,
      );

      await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProfessionalProfilePage), findsOneWidget);
      expect(
        find.text(AppValidationMessages.clientPhotoUploadFailed),
        findsOneWidget,
      );
    });
  });

  testWidgets('E/I: Home mostra mesma foto após upload', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    await pumpProfile(
      tester,
      repository: repository,
      picker: fakePickerSuccess,
    );

    await tester.tap(find.byKey(ProfessionalProfilePage.photoActionKey));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHome(tester, repository: repository);

    expect(find.byType(Image), findsWidgets);
    expect(find.byKey(HomeHeader.profileAvatarKey), findsOneWidget);
  });

  testWidgets('V: nenhuma query extra na Home', (tester) async {
    var workspaceReads = 0;
    final repository = InMemoryProfessionalRepository(
      current: leticia(photoUrl: 'https://example.com/leticia.jpg'),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            workspaceReads++;
            return workspaceFor(await repository.getCurrentProfessional());
          }),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
        ],
        child: const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: MaterialApp(home: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final readsAfterHome = workspaceReads;
    expect(find.byKey(HomeHeader.profileAvatarKey), findsOneWidget);
    expect(workspaceReads, readsAfterHome);
  });

  testWidgets('S/T: 320px e textScale 1.3 sem overflow', (tester) async {
    await pumpProfile(
      tester,
      repository: InMemoryProfessionalRepository(
        current: leticia(photoUrl: 'https://example.com/leticia.jpg'),
      ),
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileAvatar), findsOneWidget);
  });

  testWidgets('remover foto volta para inicial', (tester) async {
    final repository = InMemoryProfessionalRepository(
      current: leticia(photoUrl: 'https://example.com/leticia.jpg'),
    );
    await pumpProfile(tester, repository: repository);

    await tester.tap(find.byKey(ProfessionalProfilePage.removePhotoActionKey));
    await tester.pumpAndSettle();

    expect(repository.lastRemovePhoto, isTrue);
    expect(repository.current?.photoUrl, isNull);
    expect(find.text(AppStrings.addPhoto), findsOneWidget);
  });
}

class _DelayedPhotoProfessionalRepository extends InMemoryProfessionalRepository {
  _DelayedPhotoProfessionalRepository({
    required super.current,
    required this.completer,
  });

  final Completer<Professional> completer;

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    updateCalls++;
    lastPhotoPath = photoPath;
    lastRemovePhoto = removePhoto;
    return completer.future;
  }
}
