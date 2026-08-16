import 'dart:async';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';

class InMemoryClientRepository implements ClientRepository {
  InMemoryClientRepository({List<Client>? clients})
    : clients = List<Client>.from(clients ?? const []);

  final List<Client> clients;
  int createCalls = 0;
  int updateCalls = 0;
  int findAllCalls = 0;
  int deleteCalls = 0;
  Object? updateError;
  Completer<void>? updateCompleter;
  Client? lastUpdated;
  String? lastPhotoPath;

  @override
  Future<Client> create({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
    String? photoPath,
  }) async {
    createCalls++;
    final now = DateTime(2026, 8, 14);
    final client = Client(
      id: 'client-${clients.length + 1}',
      name: name,
      phone: phone,
      birthDate: birthDate,
      instagram: instagram,
      photoUrl: photoPath == null ? null : 'memory://$photoPath',
      isActive: true,
      clientSince: now,
      createdAt: now,
      updatedAt: now,
    );
    clients.add(client);
    return client;
  }

  @override
  Future<Client> update(Client client, {String? photoPath}) async {
    updateCalls++;
    lastPhotoPath = photoPath;
    await updateCompleter?.future;
    if (updateError != null) throw updateError!;

    final index = clients.indexWhere((item) => item.id == client.id);
    if (index < 0) {
      throw const FormatException(AppStrings.clientUpdateError);
    }

    final existing = clients[index];
    final updated = Client(
      id: existing.id,
      name: client.name,
      phone: client.phone,
      birthDate: client.birthDate,
      instagram: client.instagram,
      photoUrl: photoPath == null ? client.photoUrl : 'memory://$photoPath',
      isActive: existing.isActive,
      isFavorite: client.isFavorite,
      clientSince: existing.clientSince,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 8, 14, 16),
    );
    clients[index] = updated;
    lastUpdated = updated;
    return updated;
  }

  @override
  Future<void> delete(String clientId) async {
    deleteCalls++;
    clients.removeWhere((client) => client.id == clientId);
  }

  @override
  Future<List<Client>> findAll() async {
    findAllCalls++;
    final active = clients.where((client) => client.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List<Client>.unmodifiable(active);
  }
}
