class Professional {
  const Professional({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.specialties,
  });

  final String id;
  final String name;
  final String? role;
  final String? specialties;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
