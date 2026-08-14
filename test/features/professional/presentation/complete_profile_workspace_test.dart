import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/professional/presentation/widgets/complete_profile_form.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

void main() {
  testWidgets(
    'R: complete-profile invalida workspace e a Professional aparece',
    (tester) async {
      final repository = _InMemoryProfessionalRepository();

      final router = GoRouter(
        initialLocation: RoutePaths.completeProfile,
        routes: [
          GoRoute(
            path: RoutePaths.completeProfile,
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(child: CompleteProfileForm()),
            ),
          ),
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            professionalRepositoryProvider.overrideWithValue(repository),
            workspaceProvider.overrideWith((ref) async {
              return Workspace(
                user: const AuthenticatedUser(
                  id: 'user-1',
                  email: 'leticia@lacos.app',
                  isEmailVerified: true,
                ),
                salon: Salon(
                  id: 'salon-1',
                  name: 'Studio',
                  responsibleName: 'Leticia',
                  isActive: true,
                  createdAt: DateTime(2026, 8, 13),
                  updatedAt: DateTime(2026, 8, 13),
                ),
                professional: await repository.getCurrentProfessional(),
              );
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CompleteProfileForm)),
      );
      expect(
        (await container.read(workspaceProvider.future))?.professional,
        isNull,
      );

      await tester.enterText(find.byType(TextFormField).first, 'Leticia');
      await tester.tap(find.widgetWithText(AppButton, 'Concluir configuração'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Home'), findsOneWidget);
      expect(repository.created?.name, 'Leticia');
      expect(
        (await container.read(workspaceProvider.future))?.professional?.name,
        'Leticia',
      );
    },
  );
}

class _InMemoryProfessionalRepository implements ProfessionalRepository {
  Professional? created;

  @override
  Future<Professional> create({required String name, String? specialties}) async {
    created = Professional(
      id: 'pro-1',
      name: name,
      specialties: specialties,
      isActive: true,
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 13),
    );
    return created!;
  }

  @override
  Future<Professional?> getCurrentProfessional() async => created;

  @override
  Future<List<Professional>> findAll() async =>
      created == null ? const [] : [created!];
}
