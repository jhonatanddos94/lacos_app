import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
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
import 'package:lacos_app/features/auth/presentation/pages/verify_email_page.dart';
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

import '../../../../helpers/home_test_fixtures.dart';
import '../../../../helpers/in_memory_remember_me_preference_repository.dart';
import '../../../../helpers/lacos_app_test_helper.dart';

class _StreamingAuthRepository implements AuthRepository {
  _StreamingAuthRepository({this.onSignIn});

  final _controller = StreamController<AuthenticatedUser?>.broadcast();

  AuthenticatedUser? user;
  AuthenticatedUser Function()? onSignIn;
  Object? signInError;
  int signInCalls = 0;

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
    user = null;
    _controller.add(null);
  }
}

class _DelayedSessionRepository implements SessionRepository {
  Duration syncDelay = Duration.zero;
  Object? syncError;
  int syncCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {
    syncCalls++;
    if (syncError != null) {
      throw syncError!;
    }
    if (syncDelay > Duration.zero) {
      await Future<void>.delayed(syncDelay);
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
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

AuthenticatedUser _unverified() => const AuthenticatedUser(
  id: 'uid-new',
  email: 'new@lacos.app',
  isEmailVerified: false,
);

Workspace _workspaceFor(AuthenticatedUser user, {bool withSalon = true}) {
  if (!user.isEmailVerified) {
    return Workspace(user: user, salon: null, professional: null);
  }

  if (!withSalon) {
    return Workspace(user: user, salon: null, professional: null);
  }

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

Finder get _entrar => find.byWidgetPredicate(
  (widget) => widget is AppButton && widget.label == 'Entrar',
);
Finder get _loginTitle => find.text('Bem-vinda de volta!');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StreamingAuthRepository auth;
  late _DelayedSessionRepository session;
  late Duration workspaceDelay;
  late Workspace Function(AuthenticatedUser user) workspaceBuilder;

  List<Override> loginFlowOverrides() {
    return [
      appClockProvider.overrideWithValue(FakeAppClock(homeTestNow)),
      calendarTodayProvider.overrideWithValue(AgendaDay.from(homeTestNow)),
      authRepositoryProvider.overrideWithValue(auth),
      sessionRepositoryProvider.overrideWithValue(session),
      authFeatureFlagsProvider.overrideWithValue(false),
      rememberMePreferenceRepositoryProvider.overrideWithValue(
        InMemoryRememberMePreferenceRepository(),
      ),
      workspaceProvider.overrideWith((ref) async {
        final currentUser = ref.watch(currentAuthenticatedUserProvider);
        if (currentUser == null) return null;
        if (workspaceDelay > Duration.zero) {
          await Future<void>.delayed(workspaceDelay);
        }
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

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpLacosApp(tester, overrides: loginFlowOverrides());
    await pumpUntilLoginReady(tester);
  }

  Future<void> fillCredentials(
    WidgetTester tester, {
    String email = 'a@lacos.app',
    String password = 'secret1',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.pump();
  }

  Future<void> tapEntrarOnce(WidgetTester tester) async {
    await tester.ensureVisible(_entrar);
    await tester.tap(_entrar);
    await tester.pump();
  }

  Future<void> pumpAuthResolution(WidgetTester tester) async {
    await tester.pump(session.syncDelay + workspaceDelay);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() {
    auth = _StreamingAuthRepository(onSignIn: _userA);
    session = _DelayedSessionRepository();
    workspaceDelay = Duration.zero;
    workspaceBuilder = _workspaceFor;
  });

  tearDown(() {
    auth.dispose();
  });

  testWidgets(
    'A/F/G/H: um toque autentica com workspace assíncrono e abre Home',
    (tester) async {
      session.syncDelay = const Duration(milliseconds: 80);
      workspaceDelay = const Duration(milliseconds: 120);

      await pumpLogin(tester);
      expect(find.byType(LoginPage), findsOneWidget);

      await fillCredentials(tester);
      await tapEntrarOnce(tester);

      expect(auth.signInCalls, 1);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await pumpAuthResolution(tester);

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(AppShellPage), findsOneWidget);
      expect(find.text('Salon uid-a'), findsOneWidget);
      expect(auth.signInCalls, 1);
    },
  );

  testWidgets('B: usuário sem salão vai para Welcome com um toque', (
    tester,
  ) async {
    workspaceBuilder = (user) => _workspaceFor(user, withSalon: false);

    await pumpLogin(tester);
    await fillCredentials(tester);
    await tapEntrarOnce(tester);
    await pumpAuthResolution(tester);

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Bem-vinda ao Laços'), findsOneWidget);
    expect(auth.signInCalls, 1);
  });

  testWidgets('C: e-mail não verificado vai para verify-email com um toque', (
    tester,
  ) async {
    auth.onSignIn = _unverified;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await pumpLogin(tester);
    await fillCredentials(tester, email: 'new@lacos.app');
    await tapEntrarOnce(tester);
    await pumpAuthResolution(tester);

    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(VerifyEmailPage), findsOneWidget);
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(auth.signInCalls, 1);
  });

  testWidgets('D: credencial errada permanece no Login com erro', (
    tester,
  ) async {
    auth.signInError = const FormatException('E-mail ou senha inválidos.');

    await pumpLogin(tester);
    await fillCredentials(tester);
    await tapEntrarOnce(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(find.byType(AppShellPage), findsNothing);
    expect(auth.signInCalls, 1);
  });

  testWidgets('E: Parse falha após Firebase e não abre Home', (tester) async {
    session.syncError = const AuthSessionException(
      code: 'PARSE',
      message: 'Não foi possível sincronizar sua sessão.',
    );

    await pumpLogin(tester);
    await fillCredentials(tester);
    await tapEntrarOnce(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Não foi possível sincronizar sua sessão.'),
      findsOneWidget,
    );
    expect(find.byType(AppShellPage), findsNothing);
    expect(auth.currentUser, isNotNull);
  });

  testWidgets(
    'I: logout e login novamente abrem Home com um toque',
    (tester) async {
      await pumpLogin(tester);
      await fillCredentials(tester);
      await tapEntrarOnce(tester);
      await pumpAuthResolution(tester);

      await tester.tap(find.byKey(HomeHeader.accountButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutAction));
      await tester.pumpAndSettle();

      expect(_loginTitle, findsOneWidget);

      await fillCredentials(tester);
      await tapEntrarOnce(tester);
      await pumpAuthResolution(tester);

      expect(find.text('Salon uid-a'), findsOneWidget);
      expect(auth.signInCalls, 2);
    },
  );

  testWidgets(
    'J: usuário A logout e usuário B login usa workspace de B',
    (tester) async {
      await pumpLogin(tester);
      await fillCredentials(tester);
      await tapEntrarOnce(tester);
      await pumpAuthResolution(tester);
      expect(find.text('Salon uid-a'), findsOneWidget);

      await tester.tap(find.byKey(HomeHeader.accountButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutAction));
      await tester.pumpAndSettle();

      auth.onSignIn = _userB;
      await fillCredentials(tester, email: 'b@lacos.app');
      await tapEntrarOnce(tester);
      await pumpAuthResolution(tester);

      expect(find.text('Salon uid-b'), findsOneWidget);
      expect(find.text('Salon uid-a'), findsNothing);
    },
  );

  testWidgets('K: dois toques rápidos disparam uma autenticação', (
    tester,
  ) async {
    session.syncDelay = const Duration(milliseconds: 200);

    await pumpLogin(tester);
    await fillCredentials(tester);

    await tester.ensureVisible(_entrar);
    await tester.tap(_entrar);
    await tester.pump();
    await tester.tap(_entrar);
    await tester.pump();

    expect(auth.signInCalls, 1);

    await pumpAuthResolution(tester);
    expect(find.byType(AppShellPage), findsOneWidget);
    expect(auth.signInCalls, 1);
  });
}

