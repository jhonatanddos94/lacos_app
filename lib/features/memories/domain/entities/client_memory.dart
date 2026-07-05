class ClientMemory {
  const ClientMemory({
    this.id,
    required this.clientId,
    required this.salonId,
    this.professionalId,
    required this.ownerId,
    required this.content,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String clientId;
  final String salonId;
  final String? professionalId;
  final String ownerId;
  final String content;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
