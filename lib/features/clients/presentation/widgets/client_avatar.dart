import 'dart:io';

import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';

class ClientAvatar extends StatelessWidget {
  const ClientAvatar({
    required this.name,
    super.key,
    this.photoUrl,
    this.localPhotoPath,
    this.radius = 32,
    this.showCameraBadge = false,
    this.onTap,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor = AppColors.purple100,
    this.initialTextStyle,
  });

  final String name;
  final String? photoUrl;
  final String? localPhotoPath;
  final double radius;
  final bool showCameraBadge;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool enabled;
  final Color backgroundColor;
  final TextStyle? initialTextStyle;

  double get _size => radius * 2;

  double get _badgeSize => (_size * 40 / 96).clamp(28, 40);

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'L' : trimmed.substring(0, 1);
  }

  bool get _hasLocalPhoto =>
      localPhotoPath != null && localPhotoPath!.isNotEmpty;

  bool get _hasRemotePhoto =>
      !_hasLocalPhoto && photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _buildImage(context),
          ),
          if (showCameraBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: _CameraBadge(size: _badgeSize),
            ),
          if (isLoading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.graphite.withValues(alpha: 0.28),
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: _size * 0.28,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    final canTap = enabled && !isLoading;

    return Opacity(
      opacity: canTap ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? onTap : null,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (_hasLocalPhoto) {
      return ClipOval(
        child: Image.file(
          File(localPhotoPath!),
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _InitialAvatar(
              size: _size,
              initial: _initial,
              backgroundColor: backgroundColor,
              textStyle: initialTextStyle,
            );
          },
        ),
      );
    }

    if (_hasRemotePhoto) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return _InitialAvatar(
              size: _size,
              initial: _initial,
              backgroundColor: backgroundColor,
              textStyle: initialTextStyle,
              showLoading: true,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _InitialAvatar(
              size: _size,
              initial: _initial,
              backgroundColor: backgroundColor,
              textStyle: initialTextStyle,
            );
          },
        ),
      );
    }

    return _InitialAvatar(
      size: _size,
      initial: _initial,
      backgroundColor: backgroundColor,
      textStyle: initialTextStyle,
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: AppShadows.level1,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lacosPurple,
        ),
        child: Icon(
          Icons.photo_camera_outlined,
          color: AppColors.onPrimary,
          size: size * 0.45,
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.size,
    required this.initial,
    this.backgroundColor = AppColors.purple100,
    this.textStyle,
    this.showLoading = false,
  });

  final double size;
  final String initial;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor,
        child: showLoading
            ? SizedBox.square(
                dimension: size * 0.28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purple700.withValues(alpha: 0.7),
                ),
              )
            : Text(
                initial,
                style: textStyle ??
                    theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.purple800,
                      fontWeight: FontWeight.w800,
                    ),
              ),
      ),
    );
  }
}
