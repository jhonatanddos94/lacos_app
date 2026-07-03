import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/app/app.dart';

void main() {
  testWidgets('Splash navega para a tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LacosApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Laços'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vinda de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
