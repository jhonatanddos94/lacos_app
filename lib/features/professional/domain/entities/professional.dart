class Professional {
  const Professional({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.specialties,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? role;
  final String? specialties;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
