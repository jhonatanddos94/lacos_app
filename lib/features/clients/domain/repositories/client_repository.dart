import 'package:lacos_app/features/clients/domain/entities/client.dart';

abstract interface class ClientRepository {
  Future<Client> create({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
    String? photoPath,
  });

  Future<Client> update(Client client, {String? photoPath});

  Future<void> delete(String clientId);

  Future<List<Client>> findAll();
}
