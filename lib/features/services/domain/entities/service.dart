class Service {
  const Service({
    required this.id,
    required this.name,
    this.category,
    this.durationMinutes,
    this.price,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? category;
  final int? durationMinutes;
  final double? price;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
