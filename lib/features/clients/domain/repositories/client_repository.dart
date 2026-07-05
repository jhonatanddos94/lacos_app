import 'package:lacos_app/features/clients/domain/entities/client.dart';

abstract interface class ClientRepository {
  Future<Client> create({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
  });

  Future<Client> update(Client client);

  Future<void> delete(String clientId);

  Future<List<Client>> findAll();
}
