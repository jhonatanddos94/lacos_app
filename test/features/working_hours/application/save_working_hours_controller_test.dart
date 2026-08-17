import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/working_hours/application/controllers/save_working_hours_controller.dart';
import 'package:lacos_app/features/working_hours/application/models/working_hours_day_draft.dart';

import '../../../helpers/in_memory_professional_working_hours_repository.dart';

void main() {
  group('SaveWorkingHoursController', () {
    late InMemoryProfessionalWorkingHoursRepository repository;
    late SaveWorkingHoursController controller;

    setUp(() {
      repository = InMemoryProfessionalWorkingHoursRepository();
      controller = SaveWorkingHoursController(repository);
    });

    test('U: salvar persiste semana inteira', () async {
      final saved = await controller.saveWeek(
        salonId: 'salon-1',
        professionalId: 'pro-1',
        drafts: WorkingHoursWeekFactory.defaultWeek(),
      );

      expect(saved, isNotNull);
      expect(repository.saveWeekCalls, 1);
      expect(saved, hasLength(7));
    });

    test('V/W: erro sanitizado', () async {
      repository.saveError = Exception('Parse secret token');

      final saved = await controller.saveWeek(
        salonId: 'salon-1',
        professionalId: 'pro-1',
        drafts: WorkingHoursWeekFactory.defaultWeek(),
      );

      expect(saved, isNull);
      expect(
        controller.state.error,
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          AppStrings.workingHoursSaveError,
        ),
      );
    });
  });
}
