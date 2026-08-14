import 'package:lacos_app/shared/widgets/avatars/profile_avatar.dart';

/// Avatar de cliente — alias semântico de [ProfileAvatar].
class ClientAvatar extends ProfileAvatar {
  const ClientAvatar({
    required super.name,
    super.key,
    super.photoUrl,
    super.localPhotoPath,
    super.radius = 32,
    super.showCameraBadge = false,
    super.onTap,
    super.isLoading = false,
    super.enabled = true,
    super.backgroundColor,
    super.initialTextStyle,
  });
}
