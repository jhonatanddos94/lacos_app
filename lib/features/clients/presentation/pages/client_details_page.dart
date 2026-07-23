import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/exceptions/client_photo_upload_exception.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/presentation/helpers/memory_form_sheet_host.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_preview_card.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_photo_picker.dart';

class ClientDetailsPage extends ConsumerStatefulWidget {
  const ClientDetailsPage({required this.client, super.key});

  static const _avatarSize = 86.0;

  final Client client;

  @override
  ConsumerState<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends ConsumerState<ClientDetailsPage> {
  late Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
  }

  Future<void> _openEditClientSheet() async {
    final updatedClient = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => ClientFormBottomSheet(client: _client),
    );

    if (!mounted || updatedClient == null) return;

    setState(() => _client = updatedClient);
    ref.invalidate(clientsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.clientUpdatedSuccess)),
    );
  }

  Future<void> _changeClientPhoto() async {
    if (ref.read(clientFormControllerProvider).isLoading) return;

    final photo = await pickClientPhoto(
      context,
      onMessage: (message) => _showMessage(message),
    );

    if (!mounted || photo == null) return;

    final updatedClient = await ref
        .read(clientFormControllerProvider.notifier)
        .save(
          initialClient: _client,
          name: _client.name,
          phone: _client.phone,
          birthDate: _client.birthDate,
          instagram: _client.instagram ?? '',
          photoPath: photo.path,
        );

    if (!mounted) return;

    if (updatedClient != null) {
      setState(() => _client = updatedClient);
      ref.invalidate(clientsProvider);
      _showMessage(AppStrings.clientUpdatedSuccess);
      return;
    }

    final error = ref.read(clientFormControllerProvider).error;
    if (error != null) {
      _showMessage(_resolveErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      ClientPhotoUploadException() =>
        AppValidationMessages.clientPhotoUploadFailed,
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ =>
        '${AppValidationMessages.unexpectedError} '
            '${AppValidationMessages.tryAgain}',
    };
  }

  Future<void> _openNewMemorySheet() async {
    final memory = await showMemoryFormBottomSheet(
      context: context,
      clientId: _client.id,
    );

    if (!mounted || memory == null) return;

    ref.invalidate(clientMemoriesProvider(_client.id));

    _showMessage(AppStrings.memorySavedSuccess);
  }

  Future<void> _openDeleteClientDialog() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteClientDialog(client: _client),
    );

    if (!mounted || deleted != true) return;

    ref.invalidate(clientsProvider);
    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.clientDeletedSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhotoLoading = ref.watch(clientFormControllerProvider).isLoading;
    final memoriesAsync = ref.watch(clientMemoriesProvider(_client.id));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        title: const Text(AppStrings.clientDetailsTitle),
        backgroundColor: AppColors.warmWhite,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.xs,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(
                client: _client,
                onEdit: _openEditClientSheet,
                onPhotoTap: _changeClientPhoto,
                onNewMemory: _openNewMemorySheet,
                isPhotoLoading: isPhotoLoading,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ClientDataCard(client: _client),
              const SizedBox(height: AppSpacing.sm),
              ClientMemoriesPreviewCard(
                memories: memoriesAsync.value ?? const [],
                isLoading: memoriesAsync.isLoading && !memoriesAsync.hasValue,
                errorMessage: memoriesAsync.hasError
                    ? AppStrings.clientMemoriesLoadError
                    : null,
                onTap: () =>
                    context.push(RoutePaths.clientMemories, extra: _client),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _HighlightSectionCard(
                title: AppStrings.clientNextAppointment,
                titleIcon: Icons.event_available_outlined,
                emptyTitle: AppStrings.clientNoNextAppointment,
                message: AppStrings.clientNextAppointmentComingSoon,
                bodyIcon: Icons.event_note_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _HighlightSectionCard(
                title: AppStrings.clientServiceHistory,
                titleIcon: Icons.history_rounded,
                emptyTitle: AppStrings.noServiceHistoryYet,
                message: AppStrings.clientHistoryComingSoon,
                bodyIcon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DeleteClientCard(onDelete: _openDeleteClientDialog),
              const SizedBox(height: AppSpacing.sm),
              const _FooterMessage(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.client,
    required this.onEdit,
    required this.onPhotoTap,
    required this.onNewMemory,
    required this.isPhotoLoading,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onPhotoTap;
  final VoidCallback onNewMemory;
  final bool isPhotoLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instagram = client.instagram;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClientAvatar(
                  client: client,
                  onTap: onPhotoTap,
                  isLoading: isPhotoLoading,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.purple900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (instagram != null && instagram.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          '@$instagram',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.purple700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      _SoftChip(
                        label:
                            '${AppStrings.clientSince} '
                            '${_formatMonthYear(client.clientSince ?? client.createdAt)}',
                        icon: Icons.calendar_month_outlined,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.purple300,
                  size: 36,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _QuickActions(
            client: client,
            onEdit: onEdit,
            onNewMemory: onNewMemory,
          ),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({
    required this.client,
    required this.onTap,
    required this.isLoading,
  });

  final Client client;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClientAvatar(
      name: client.name,
      photoUrl: client.photoUrl,
      radius: ClientDetailsPage._avatarSize / 2,
      showCameraBadge: true,
      onTap: onTap,
      isLoading: isLoading,
      backgroundColor: AppColors.surface,
      initialTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppColors.purple800,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.client,
    required this.onEdit,
    required this.onNewMemory,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onNewMemory;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.softGreen,
              title: AppStrings.whatsapp,
              subtitle: AppStrings.talk,
              onTap: () => _openWhatsApp(context, client.phone),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.calendar_month_outlined,
              title: AppStrings.schedule,
              subtitle: AppStrings.comingSoon,
              onTap: () => _showMessage(context, AppStrings.openLinkComingSoon),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.auto_awesome_rounded,
              title: AppStrings.newMemory,
              subtitle: AppStrings.remember,
              onTap: onNewMemory,
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.edit_outlined,
              title: AppStrings.edit,
              subtitle: AppStrings.clientData,
              onTap: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.purple700,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientDataCard extends StatelessWidget {
  const _ClientDataCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final instagram = client.instagram;

    return _DetailsCard(
      title: AppStrings.clientData,
      titleIcon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _CopyableInfoRow(
            label: AppStrings.clientPhone,
            value: _formatPhone(client.phone),
            copiedMessage: AppStrings.phoneCopied,
            trailingAsset: AppAssets.whatsappIcon,
            onTrailingTap: () => _openWhatsApp(context, client.phone),
          ),
          if (instagram != null && instagram.isNotEmpty)
            _CopyableInfoRow(
              label: AppStrings.clientInstagram,
              value: '@$instagram',
              copiedMessage: AppStrings.instagramCopied,
              trailingAsset: AppAssets.instagramIcon,
              onTrailingTap: () => _openInstagram(context, instagram),
            ),
          if (client.birthDate != null)
            _CopyableInfoRow(
              label: AppStrings.clientBirthDate,
              value: _formatDate(client.birthDate!),
              copiedMessage: AppStrings.birthDateCopied,
            ),
          _CopyableInfoRow(
            label: AppStrings.clientSince,
            value: _formatDate(client.clientSince ?? client.createdAt),
            copiedMessage: AppStrings.dateCopied,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.xxxs),
              Text(
                AppStrings.tapValueToCopy,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  const _CopyableInfoRow({
    required this.label,
    required this.value,
    required this.copiedMessage,
    this.trailingAsset,
    this.onTrailingTap,
  });

  final String label;
  final String value;
  final String copiedMessage;
  final String? trailingAsset;
  final VoidCallback? onTrailingTap;

  static const _labelColumnWidth = 104.0;
  static const _valueActionGap = 12.0;
  static const _trailingColumnWidth = 40.0;
  static const _trailingButtonSize = 40.0;
  static const _trailingAssetSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              SizedBox(
                width: _labelColumnWidth,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _copyValue(context, value, copiedMessage),
                  borderRadius: AppRadius.borderXs,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _valueActionGap),
              SizedBox(
                width: _trailingColumnWidth,
                height: _trailingColumnWidth,
                child: Center(
                  child: IconButton(
                    onPressed:
                        onTrailingTap ??
                        () => _copyValue(context, value, copiedMessage),
                    icon: _TrailingActionIcon(asset: trailingAsset),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: _trailingButtonSize,
                      height: _trailingButtonSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _TrailingActionIcon extends StatelessWidget {
  const _TrailingActionIcon({this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    final assetPath = asset;
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: _CopyableInfoRow._trailingAssetSize,
        height: _CopyableInfoRow._trailingAssetSize,
        fit: BoxFit.contain,
        // TODO: reexportar o PNG sem margem transparente se parecer desalinhado.
      );
    }

    return const Icon(
      Icons.copy_rounded,
      color: AppColors.purple700,
      size: AppIconSizes.sm,
    );
  }
}

class _HighlightSectionCard extends StatelessWidget {
  const _HighlightSectionCard({
    required this.title,
    required this.titleIcon,
    required this.emptyTitle,
    required this.message,
    required this.bodyIcon,
  });

  final String title;
  final IconData titleIcon;
  final String emptyTitle;
  final String message;
  final IconData bodyIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DetailsCard(
      title: title,
      titleIcon: titleIcon,
      showChevron: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.purple50,
              shape: BoxShape.circle,
            ),
            child: Icon(bodyIcon, color: AppColors.purple700),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emptyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteClientCard extends StatelessWidget {
  const _DeleteClientCard({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.softRose.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.softRose.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const _SmallIcon(
            icon: Icons.delete_outline_rounded,
            color: AppColors.softRose,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.deleteClient,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.softRose,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  AppStrings.deleteClientDescription,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          OutlinedButton(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.softRose,
              side: const BorderSide(color: AppColors.softRose),
            ),
            child: const Text(AppStrings.deleteClient),
          ),
        ],
      ),
    );
  }
}

class _DeleteClientDialog extends ConsumerStatefulWidget {
  const _DeleteClientDialog({required this.client});

  final Client client;

  @override
  ConsumerState<_DeleteClientDialog> createState() =>
      _DeleteClientDialogState();
}

class _DeleteClientDialogState extends ConsumerState<_DeleteClientDialog> {
  Future<void> _confirmDelete() async {
    final success = await ref
        .read(clientFormControllerProvider.notifier)
        .delete(widget.client);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref.read(clientFormControllerProvider).error;
    if (error != null) {
      _showMessage(_resolveErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => AppStrings.clientDeleteError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(clientFormControllerProvider).isLoading;

    return AlertDialog(
      title: const Text(AppStrings.deleteClientTitle),
      content: Text(
        AppStrings.deleteClientMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: isLoading ? null : _confirmDelete,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.softRose,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.softRose.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(AppStrings.deleteClient),
        ),
      ],
    );
  }
}

class _FooterMessage extends StatelessWidget {
  const _FooterMessage();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.clientFooterMessage,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.child,
    this.title,
    this.titleIcon,
    this.showChevron = false,
  });

  final String? title;
  final IconData? titleIcon;
  final bool showChevron;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level0,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: AppColors.purple700, size: 18),
                  const SizedBox(width: AppSpacing.xxxs),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.graphite,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, this.color = AppColors.purple700});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: AppColors.purple50,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.purple700, size: 14),
          const SizedBox(width: AppSpacing.xxxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyValue(
  BuildContext context,
  String value,
  String copiedMessage,
) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  _showMessage(context, copiedMessage);
}

void _openWhatsApp(BuildContext context, String phone) {
  final digits = digitsOnly(phone);
  if (digits.isEmpty) return;

  // TODO: abrir WhatsApp quando url_launcher ou deep link oficial estiver disponível.
  _showMessage(context, AppStrings.openLinkComingSoon);
}

void _openInstagram(BuildContext context, String instagram) {
  if (instagram.trim().isEmpty) return;

  // TODO: abrir Instagram quando url_launcher ou deep link oficial estiver disponível.
  _showMessage(context, AppStrings.openLinkComingSoon);
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _formatPhone(String phone) {
  final digits = digitsOnly(phone);
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }

  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
        '${digits.substring(7)}';
  }

  return phone;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatMonthYear(DateTime date) {
  return '${_monthName(date.month)}/${date.year}';
}

String _monthName(int month) {
  return switch (month) {
    1 => 'Jan',
    2 => 'Fev',
    3 => 'Mar',
    4 => 'Abr',
    5 => 'Mai',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Ago',
    9 => 'Set',
    10 => 'Out',
    11 => 'Nov',
    12 => 'Dez',
    _ => '',
  };
}
