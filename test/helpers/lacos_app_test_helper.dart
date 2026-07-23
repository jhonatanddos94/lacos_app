import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/app/app.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'fake_auth_repository.dart';

List<Override> unauthenticatedAppOverrides() {
  return [
    workspaceProvider.overrideWith((ref) async => null),
    authRepositoryProvider.overrideWithValue(
      FakeUnauthenticatedAuthRepository(),
    ),
  ];
}

Future<void> pumpLacosApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const LacosApp()),
  );
}

Future<void> pumpUntilLoginReady(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));

    final loginVisible = find.text('Bem-vinda de volta!').evaluate().isNotEmpty;
    final splashVisible = find
        .text(AppStrings.splashPreparing)
        .evaluate()
        .isNotEmpty;

    if (loginVisible && !splashVisible) {
      return;
    }
  }

  fail('Login não ficou visível ou a Splash permaneceu na tela');
}
