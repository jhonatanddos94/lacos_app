import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/services/application/helpers/service_provider_invalidation.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';

import '../../helpers/fake_service_repository.dart';

void main() {
  testWidgets('invalidateServicesProvider recarrega apenas servicesProvider', (
    tester,
  ) async {
    final repository = FakeServiceRepository(seed: [buildTestService()]);
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await widgetRef.read(servicesProvider.future);
    expect(repository.findAllCallCount, 1);

    invalidateServicesProvider(widgetRef);
    await widgetRef.read(servicesProvider.future);

    expect(repository.findAllCallCount, 2);
  });
}
