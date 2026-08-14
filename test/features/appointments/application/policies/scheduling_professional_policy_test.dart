import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/appointments/application/policies/scheduling_professional_policy.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';

void main() {
  Professional professional({
    required String id,
    required String name,
    bool isActive = true,
  }) {
    final now = DateTime(2026, 8, 13);
    return Professional(
      id: id,
      name: name,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('SchedulingProfessionalPolicy', () {
    test('A: 0 ativas → none', () {
      final resolution = SchedulingProfessionalPolicy.fromProfessionals(const []);
      expect(resolution, isA<SchedulingProfessionalNone>());
    });

    test('B: 1 ativa → unique, not first of a larger list', () {
      final leticia = professional(id: 'pro-1', name: 'Leticia');
      final resolution = SchedulingProfessionalPolicy.fromProfessionals([
        leticia,
      ]);

      expect(
        resolution,
        isA<SchedulingProfessionalUnique>().having(
          (value) => value.professional.id,
          'id',
          'pro-1',
        ),
      );
    });

    test('S: 2+ ativas → multiple, never first', () {
      final resolution = SchedulingProfessionalPolicy.fromProfessionals([
        professional(id: 'pro-1', name: 'Ana'),
        professional(id: 'pro-2', name: 'Bia'),
      ]);

      expect(resolution, isA<SchedulingProfessionalMultiple>());
      expect(resolution, isNot(isA<SchedulingProfessionalUnique>()));
      expect(
        (resolution as SchedulingProfessionalMultiple).professionals.map(
          (item) => item.id,
        ),
        ['pro-1', 'pro-2'],
      );
    });

    test('inativas não entram na cardinalidade', () {
      final resolution = SchedulingProfessionalPolicy.fromProfessionals([
        professional(id: 'pro-1', name: 'Ana', isActive: false),
        professional(id: 'pro-2', name: 'Bia'),
      ]);

      expect(
        resolution,
        isA<SchedulingProfessionalUnique>().having(
          (value) => value.professional.id,
          'id',
          'pro-2',
        ),
      );
    });

    test('loading não assume 0 profissionais', () {
      expect(
        SchedulingProfessionalPolicy.resolve(const AsyncLoading()),
        isA<SchedulingProfessionalLoading>(),
      );
    });

    test('error não assume 0 profissionais', () {
      expect(
        SchedulingProfessionalPolicy.resolve(
          AsyncError(FormatException('fail'), StackTrace.current),
        ),
        isA<SchedulingProfessionalFailed>(),
      );
    });
  });
}
