import 'dart:async';

import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class InMemorySalonRepository implements SalonRepository {
  InMemorySalonRepository({this.current});

  Salon? current;
  int createCalls = 0;
  int updateCalls = 0;
  Object? updateError;
  Completer<void>? updateCompleter;

  @override
  Future<Salon?> getCurrentSalon() async => current;

  @override
  Future<Salon> create({
    required String name,
    required String responsibleName,
  }) {
    createCalls++;
    throw UnimplementedError();
  }

  @override
  Future<Salon> update({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) async {
    updateCalls++;
    await updateCompleter?.future;
    if (updateError != null) throw updateError!;

    final existing = current;
    if (existing == null || existing.id != salonId) {
      throw const FormatException(
        'Não foi possível salvar seu salão. Tente novamente.',
      );
    }
    current = Salon(
      id: existing.id,
      name: name,
      responsibleName: existing.responsibleName,
      phone: phone,
      address: address,
      city: city,
      state: state,
      isActive: existing.isActive,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 8, 14, 16),
    );
    return current!;
  }
}
