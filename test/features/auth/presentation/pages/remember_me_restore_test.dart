import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/application/providers/remember_me_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';
import 'package:lacos_app/features/auth/presentation/widgets/login/login_form_actions.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

import '../../../../core/session/fakes/session_test_fakes.dart';
import '../../../../helpers/home_test_fixtures.dart';
import '../../../../helpers/in_memory_remember_me_preference_repository.dart';
import '../../../../helpers/lacos_app_test_helper.dart';

class _PersistedAuthRepository implements AuthRepository {
  _PersistedAuthRepository({this.user, this.onSignIn});

  final _controller = StreamController<AuthenticatedUser?>.broadcast();

  AuthenticatedUser? user;
  AuthenticatedUser Function()? onSignIn;
  Object? signInError;
  int signInCalls = 0;
  int signOutCalls = 0;

  void dispose() => _controller.close();

  @override
  Stream<AuthenticatedUser?> get authenticatedUser => _controller.stream;

  @override
  AuthenticatedUser? get currentUser => user;

  @override
  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'token';

  @override
  Future<AuthenticatedUser?> reloadUser() async => user;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInError != null) {
      throw signInError!;
    }
    user = onSignIn?.call() ?? _userA();
    _controller.add(user);
    return user!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    _controller.add(null);
  }
}

class _SessionRepository implements SessionRepository {
  _SessionRepository(this.gateway);

  final FakeParseUserSessionGateway gateway;
  Object? signOutError;
  int signOutCalls = 0;

  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) {
      await gateway.clearLocalSession();
      throw signOutError!;
    }
    await gateway.logout();
  }
}

AuthenticatedUser _userA() => const AuthenticatedUser(
  id: 'uid-a',
  email: 'a@lacos.app',
  isEmailVerified: true,
);

AuthenticatedUser _userB() => const AuthenticatedUser(
  id: 'uid-b',
  email: 'b@lacos.app',
  isEmailVerified: true,
);

Workspace _completeWorkspace(AuthenticatedUser user) {
  return Workspace(
    user: user,
    salon: Salon(
      id: 'salon-${user.id}',
      name: 'Salon ${user.id}',
      responsibleName: 'Pro ${user.id}',
      isActive: true,
      createdAt: homeTestNow,
      updatedAt: homeTestNow,
    ),
    professional: Professional(
      id: 'pro-${user.id}',
      name: 'Pro ${user.id}',
      isActive: true,
      createdAt: homeTestNow,
      updatedAt: homeTestNow,
    ),
  );
}

Workspace _onboardingWorkspace(AuthenticatedUser user) {
  return Workspace(user: user, salon: null, professional: null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PersistedAuthRepository auth;
  late FakeParseUserSessionGateway parseGateway;
  late _SessionRepository session;
  late InMemoryRememberMePreferenceRepository rememberMe;
  late Workspace Function(AuthenticatedUser user) workspaceBuilder;

  List<Override> overrides() {
    return [
      appClockProvider.overrideWithValue(FakeAppClock(homeTestNow)),
      calendarTodayProvider.overrideWithValue(AgendaDay.from(homeTestNow)),
      authRepositoryProvider.overrideWithValue(auth),
      sessionRepositoryProvider.overrideWithValue(session),
      parseUserSessionGatewayProvider.overrideWithValue(parseGateway),
      rememberMePreferenceRepositoryProvider.overrideWithValue(rememberMe),
      authFeatureFlagsProvider.overrideWithValue(false),
      workspaceProvider.overrideWith((ref) async {
        await ref.watch(sessionRestoreProvider.future);
        final currentUser = ref.watch(currentAuthenticatedUserProvider);
        if (currentUser == null) return null;
        return workspaceBuilder(currentUser);
      }),
      agendaAppointmentsDisplayProvider.overrideWith(
        (ref, day) async => const [],
      ),
      agendaCalendarAppointmentDaysProvider.overrideWith(
        (ref, view) async => const {},
      ),
      clientsProvider.overrideWith((ref) async => const <Client>[]),
      servicesProvider.overrideWith((ref) async => const <Service>[]),
      homeUpcomingDaysProvider.overrideWith((ref) async => const []),
    ];
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLacosApp(tester, overrides: overrides());
  }

  Future<void> pumpAuthResolution(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String email = 'a@lacos.app',
    String password = 'secret1',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.pump();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.label == 'Entrar',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() {
    auth = _PersistedAuthRepository(onSignIn: _userA);
    parseGateway = FakeParseUserSessionGateway();
    session = _SessionRepository(parseGateway);
    rememberMe = InMemoryRememberMePreferenceRepository();
    workspaceBuilder = _completeWorkspace;
  });

  tearDown(() {
    auth.dispose();
  });

  testWidgets('B: checkbox carrega false por default', (tester) async {
    await pumpApp(tester);
    await pumpUntilLoginReady(tester);
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(
      find.byKey(LoginFormActions.rememberMeKey),
    );
    expect(checkbox.value, isFalse);
  });

  testWidgets('C: login com ON persiste true', (tester) async {
    await pumpApp(tester);
    await pumpUntilLoginReady(tester);
    await tester.tap(find.byKey(LoginFormActions.rememberMeKey));
    await tester.pump();
    await fillAndSubmit(tester);

    expect(rememberMe.value, isTrue);
    expect(rememberMe.writeCalls, 1);
    expect(find.byType(AppShellPage), findsOneWidget);
  });

  testWidgets('D: login com OFF persiste false', (tester) async {
    rememberMe.value = true;
    await pumpApp(tester);
    await pumpUntilLoginReady(tester);
    await tester.tap(find.byKey(LoginFormActions.rememberMeKey));
    await tester.pump();
    await fillAndSubmit(tester);

    expect(rememberMe.value, isFalse);
    expect(find.byType(AppShellPage), findsOneWidget);
  });

  testWidgets('E: login falha e não corrompe preferência anterior', (
    tester,
  ) async {
    rememberMe.value = true;
    auth.signInError = const FormatException('E-mail ou senha inválidos.');

    await pumpApp(tester);
    await pumpUntilLoginReady(tester);
    await tester.tap(find.byKey(LoginFormActions.rememberMeKey));
    await tester.pump();
    await fillAndSubmit(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(rememberMe.value, isTrue);
    expect(rememberMe.writeCalls, 0);
  });

  testWidgets(
    'F/Q: rememberMe true + sessão persistida restaura Home sem segundo login',
    (tester) async {
      rememberMe.value = true;
      auth.user = _userA();
      parseGateway.current = const ParseUserSnapshot(
        objectId: 'p1',
        username: 'uid-a',
        sessionTokenPresent: true,
        firebaseUid: 'uid-a',
      );

      await pumpApp(tester);
      await pumpAuthResolution(tester);

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(AppShellPage), findsOneWidget);
      expect(find.text('Salon uid-a'), findsOneWidget);
      expect(auth.signOutCalls, 0);
      expect(session.signOutCalls, 0);
    },
  );

  testWidgets(
    'G/M/causality: rememberMe false + sessão persistida vai para Login sem flash de Home',
    (tester) async {
      rememberMe.value = false;
      auth.user = _userA();
      parseGateway.current = const ParseUserSnapshot(
        objectId: 'p1',
        username: 'uid-a',
        sessionTokenPresent: true,
        firebaseUid: 'uid-a',
      );

      await pumpApp(tester);

      expect(find.byType(AppShellPage), findsNothing);

      await tester.pump();
      expect(find.byType(AppShellPage), findsNothing);

      await pumpUntilLoginReady(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AppShellPage), findsNothing);
      expect(auth.currentUser, isNull);
      expect(auth.signOutCalls, 1);
      expect(session.signOutCalls, 1);
      expect(parseGateway.current, isNull);
    },
  );

  testWidgets(
    'H: OFF + background/resume continua logado nesta execução',
    (tester) async {
      await pumpApp(tester);
      await pumpUntilLoginReady(tester);
      await fillAndSubmit(tester);

      expect(find.byType(AppShellPage), findsOneWidget);
      expect(rememberMe.value, isFalse);
      expect(auth.signOutCalls, 0);

      // Same process: inactive/resumed is an app switch, not a cold start.
      // paused/hidden must not be used here — they are not a new execution
      // and must never trigger rememberMe logout.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AppShellPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(auth.signOutCalls, 0);
      expect(session.signOutCalls, 0);
    },
  );

  testWidgets(
    'I/J/K: logout manual vai ao Login e preserva preferência ON',
    (tester) async {
      rememberMe.value = true;

      await pumpApp(tester);
      await pumpUntilLoginReady(tester);
      await fillAndSubmit(tester);

      expect(find.byType(AppShellPage), findsOneWidget);
      expect(rememberMe.value, isTrue);

      await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutAction));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vinda de volta!'), findsOneWidget);
      expect(rememberMe.value, isTrue);
      expect(
        tester
            .widget<Checkbox>(find.byKey(LoginFormActions.rememberMeKey))
            .value,
        isTrue,
      );
    },
  );

  testWidgets(
    'L: A com ON, logout, B com OFF, restart vai para Login',
    (tester) async {
      rememberMe.value = true;
      await pumpApp(tester);
      await pumpUntilLoginReady(tester);
      await fillAndSubmit(tester);
      expect(find.text('Salon uid-a'), findsOneWidget);

      await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutAction));
      await tester.pumpAndSettle();

      auth.onSignIn = _userB;
      await tester.tap(find.byKey(LoginFormActions.rememberMeKey));
      await tester.pump();
      await fillAndSubmit(tester, email: 'b@lacos.app');
      expect(find.text('Salon uid-b'), findsOneWidget);
      expect(rememberMe.value, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      auth.dispose();
      auth = _PersistedAuthRepository(user: _userB());
      parseGateway.current = const ParseUserSnapshot(
        objectId: 'p-b',
        username: 'uid-b',
        sessionTokenPresent: true,
        firebaseUid: 'uid-b',
      );
      session = _SessionRepository(parseGateway);

      await pumpApp(tester);
      await pumpAuthResolution(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AppShellPage), findsNothing);
      expect(auth.currentUser, isNull);
    },
  );

  testWidgets(
    'O: falha de Parse logout no bootstrap não autentica',
    (tester) async {
      rememberMe.value = false;
      auth.user = _userA();
      parseGateway.current = const ParseUserSnapshot(
        objectId: 'p1',
        username: 'uid-a',
        sessionTokenPresent: true,
      );
      session.signOutError = const FormatException('parse fail');

      await pumpApp(tester);
      await pumpUntilLoginReady(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AppShellPage), findsNothing);
      expect(auth.currentUser, isNull);
      expect(auth.signOutCalls, 1);
    },
  );

  testWidgets(
    'R: rememberMe true sem salon vai para onboarding',
    (tester) async {
      rememberMe.value = true;
      auth.user = _userA();
      workspaceBuilder = _onboardingWorkspace;

      await pumpApp(tester);
      await pumpAuthResolution(tester);

      expect(find.byType(LoginPage), findsNothing);
      expect(find.text('Bem-vinda ao Laços'), findsOneWidget);
    },
  );
}
