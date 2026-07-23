import 'package:lacos_app/features/salon/domain/entities/salon.dart';

/// Contrato de persistência de salões do Laços.
abstract interface class SalonRepository {
  Future<Salon?> getCurrentSalon();

  Future<Salon> create({required String name, required String responsibleName});
}
