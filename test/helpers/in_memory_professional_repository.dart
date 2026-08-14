import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';

class InMemoryProfessionalRepository implements ProfessionalRepository {
  InMemoryProfessionalRepository({this.current});

  Professional? current;
  int updateCalls = 0;
  Object? updateError;
  String? lastPhotoPath;
  var lastRemovePhoto = false;

  @override
  Future<Professional> create({required String name, String? specialties}) {
    throw UnimplementedError();
  }

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    updateCalls++;
    lastPhotoPath = photoPath;
    lastRemovePhoto = removePhoto;
    if (updateError != null) {
      throw updateError!;
    }

    final existing = current;
    if (existing == null || existing.id != professionalId) {
      throw const FormatException(
        'Não foi possível salvar seu perfil profissional. Tente novamente.',
      );
    }

    String? photoUrl = existing.photoUrl;
    if (removePhoto) {
      photoUrl = null;
    } else if (photoPath != null && photoPath.isNotEmpty) {
      photoUrl = 'memory://$photoPath';
    }

    current = Professional(
      id: existing.id,
      name: name,
      specialties: specialties,
      role: existing.role,
      photoUrl: photoUrl,
      isActive: existing.isActive,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 8, 14, 16),
    );
    return current!;
  }

  @override
  Future<Professional?> getCurrentProfessional() async => current;

  @override
  Future<List<Professional>> findAll() async =>
      current == null ? const [] : [current!];
}
