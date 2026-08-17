class ProfessionalWorkingHours {
  const ProfessionalWorkingHours({
    required this.id,
    required this.salonId,
    required this.professionalId,
    required this.weekday,
    required this.isWorking,
    required this.startMinutes,
    required this.endMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String salonId;
  final String professionalId;
  final int weekday;
  final bool isWorking;
  final int startMinutes;
  final int endMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfessionalWorkingHours copyWith({
    String? id,
    String? salonId,
    String? professionalId,
    int? weekday,
    bool? isWorking,
    int? startMinutes,
    int? endMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfessionalWorkingHours(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      professionalId: professionalId ?? this.professionalId,
      weekday: weekday ?? this.weekday,
      isWorking: isWorking ?? this.isWorking,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
