import 'package:lacos_app/features/salon/domain/entities/salon.dart';

/// Contrato de persistência de salões do Laços.
abstract interface class SalonRepository {
  Future<Salon?> getCurrentSalon();

  Future<Salon> create({required String name, required String responsibleName});

  Future<Salon> update({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? state,
  });
}
