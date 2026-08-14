import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';

import '../../../helpers/fake_ads_sdk.dart';
import '../../../helpers/lacos_app_test_helper.dart';

void main() {
  testWidgets('W/X/AG: bootstrap e login não esperam Ads', (tester) async {
    final ads = FakeAdsSdk(prepareCompleter: Completer<void>());

    await pumpLacosApp(
      tester,
      overrides: [
        ...unauthenticatedAppOverrides(),
        adsSdkProvider.overrideWithValue(ads),
      ],
    );
    await tester.pump();
    await pumpUntilLoginReady(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(ads.loadCalls, 0);
  });
}
