import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';

class Workspace {
  const Workspace({
    required this.user,
    required this.salon,
    required this.professional,
  });

  final AuthenticatedUser user;
  final Salon? salon;
  final Professional? professional;

  bool get hasVerifiedEmail => user.isEmailVerified;
  bool get hasSalon => salon != null;
  bool get hasProfessional => professional != null;
}
