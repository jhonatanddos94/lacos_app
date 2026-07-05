class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    this.birthDate,
    this.photoUrl,
    this.instagram,
    required this.isActive,
    this.clientSince,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? instagram;
  final bool isActive;
  final DateTime? clientSince;
  final DateTime createdAt;
  final DateTime updatedAt;
}
