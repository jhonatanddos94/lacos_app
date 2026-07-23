import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/widgets/splash_loading_indicator.dart';
import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';
import 'package:lacos_app/features/splash/presentation/pages/splash_page.dart';
import 'helpers/lacos_app_test_helper.dart';

void main() {
  testWidgets('Splash navega para a tela de login sem workspace válido', (
    WidgetTester tester,
  ) async {
    await pumpLacosApp(tester, overrides: unauthenticatedAppOverrides());
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.bySemanticsLabel('Laços'), findsOneWidget);
    expect(find.byType(SplashLoadingIndicator), findsOneWidget);
    expect(find.text(AppStrings.splashPreparing), findsOneWidget);
    expect(find.text(AppStrings.splashYourEnvironment), findsOneWidget);

    await pumpUntilLoginReady(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Bem-vinda de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
