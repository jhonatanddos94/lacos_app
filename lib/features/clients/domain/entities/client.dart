class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    this.birthDate,
    this.photoUrl,
    this.instagram,
    required this.isActive,
    this.isFavorite = false,
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
  final bool isFavorite;
  final DateTime? clientSince;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? birthDate,
    String? photoUrl,
    String? instagram,
    bool? isActive,
    bool? isFavorite,
    DateTime? clientSince,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBirthDate = false,
    bool clearPhotoUrl = false,
    bool clearInstagram = false,
    bool clearClientSince = false,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      instagram: clearInstagram ? null : (instagram ?? this.instagram),
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      clientSince: clearClientSince ? null : (clientSince ?? this.clientSince),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
