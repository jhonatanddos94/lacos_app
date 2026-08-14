import 'package:lacos_app/features/professional/domain/entities/professional.dart';

abstract interface class ProfessionalRepository {
  Future<Professional> create({required String name, String? specialties});

  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  });

  Future<Professional?> getCurrentProfessional();

  Future<List<Professional>> findAll();
}
