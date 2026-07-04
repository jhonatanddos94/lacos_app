/// Salão no domínio do Laços.
class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.responsibleName,
    this.phone,
    this.address,
    this.city,
    this.state,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String responsibleName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
