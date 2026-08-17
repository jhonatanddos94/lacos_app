import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/working_hours/infrastructure/repositories/parse_professional_working_hours_repository.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  final salonA = Salon(
    id: 'salon-a',
    name: 'Salão A',
    responsibleName: 'Ana',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final professionalA = Professional(
    id: 'pro-a',
    name: 'Ana',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final professionalB = Professional(
    id: 'pro-b',
    name: 'Bia',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  group('ParseProfessionalWorkingHoursRepository tenancy', () {
    test('M: Professional B não acessa escopo da A', () async {
      final repository = ParseProfessionalWorkingHoursRepository(
        _FakeSalonRepository(salonA),
        _FakeProfessionalRepository(professionalA),
      );

      await expectLater(
        repository.findWeek(salonId: salonA.id, professionalId: professionalB.id),
        throwsA(isA<StateError>()),
      );
    });

    test('L: salon atual escopa a configuração', () async {
      final repository = ParseProfessionalWorkingHoursRepository(
        _FakeSalonRepository(salonA),
        _FakeProfessionalRepository(professionalA),
      );

      await expectLater(
        repository.findWeek(salonId: 'salon-other', professionalId: professionalA.id),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FakeSalonRepository implements SalonRepository {
  _FakeSalonRepository(this.salon);

  final Salon salon;

  @override
  Future<Salon> create({
    required String name,
    required String responsibleName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Salon?> getCurrentSalon() async => salon;

  @override
  Future<Salon> update({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) {
    throw UnimplementedError();
  }
}

class _FakeProfessionalRepository implements ProfessionalRepository {
  _FakeProfessionalRepository(this.professional);

  final Professional professional;

  @override
  Future<Professional> create({required String name, String? specialties}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Professional>> findAll() async => [professional];

  @override
  Future<Professional?> getCurrentProfessional() async => professional;

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) {
    throw UnimplementedError();
  }
}
