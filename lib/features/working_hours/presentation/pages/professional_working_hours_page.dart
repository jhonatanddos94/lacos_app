import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/working_hours/application/helpers/working_hours_provider_invalidation.dart';
import 'package:lacos_app/features/working_hours/application/models/working_hours_day_draft.dart';
import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';
import 'package:lacos_app/features/working_hours/presentation/helpers/working_hours_time_picker.dart';
import 'package:lacos_app/features/working_hours/presentation/widgets/working_hours_day_row.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ProfessionalWorkingHoursPage extends ConsumerStatefulWidget {
  const ProfessionalWorkingHoursPage({super.key});

  static const pageKey = Key('professional-working-hours-page');
  static const saveButtonKey = Key('professional-working-hours-save');
  static const saveErrorKey = Key('professional-working-hours-save-error');
  static const weekListKey = Key('professional-working-hours-week-list');

  @override
  ConsumerState<ProfessionalWorkingHoursPage> createState() =>
      _ProfessionalWorkingHoursPageState();
}

class _ProfessionalWorkingHoursPageState
    extends ConsumerState<ProfessionalWorkingHoursPage> {
  List<WorkingHoursDayDraft> _drafts = WorkingHoursWeekFactory.defaultWeek();
  var _initializedFromProvider = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(saveWorkingHoursControllerProvider.notifier).reset();
    });
  }

  void _syncDraftsFromProvider(List<WorkingHoursDayDraft> drafts) {
    if (_initializedFromProvider) return;
    _initializedFromProvider = true;
    setState(() => _drafts = drafts);
  }

  void _updateDay(int weekday, WorkingHoursDayDraft updated) {
    setState(() {
      _drafts = [
        for (final day in _drafts)
          if (day.weekday == weekday) updated else day,
      ];
      _saveError = null;
    });
  }

  Future<void> _pickStartTime(WorkingHoursDayDraft day) async {
    final picked = await showWorkingHoursTimePicker(
      context: context,
      initialMinutes: day.startMinutes,
    );
    if (!mounted || picked == null) return;

    _updateDay(
      day.weekday,
      day.copyWith(startMinutes: timeOfDayToMinutes(picked)),
    );
  }

  Future<void> _pickEndTime(WorkingHoursDayDraft day) async {
    final picked = await showWorkingHoursTimePicker(
      context: context,
      initialMinutes: day.endMinutes,
    );
    if (!mounted || picked == null) return;

    _updateDay(
      day.weekday,
      day.copyWith(endMinutes: timeOfDayToMinutes(picked)),
    );
  }

  Future<void> _save() async {
    final scope = ref.read(workingHoursScopeProvider);
    if (scope == null) {
      setState(
        () => _saveError = AppStrings.workingHoursProfessionalRequired,
      );
      return;
    }

    if (ref.read(saveWorkingHoursControllerProvider).isLoading) return;

    setState(() => _saveError = null);

    final saved = await ref
        .read(saveWorkingHoursControllerProvider.notifier)
        .saveWeek(
          salonId: scope.salonId,
          professionalId: scope.professionalId,
          drafts: _drafts,
        );

    if (!mounted) return;

    if (saved != null) {
      invalidateWorkingHoursSources(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.workingHoursUpdatedSuccess)),
      );
      Navigator.of(context).pop();
      return;
    }

    final failureMessage = ref.read(saveWorkingHoursControllerProvider).maybeWhen(
      error: (error, _) => switch (error) {
        FormatException(message: final message) => message,
        _ => AppStrings.workingHoursSaveError,
      },
      orElse: () => AppStrings.workingHoursSaveError,
    );
    setState(() => _saveError = failureMessage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = ref.watch(workingHoursScopeProvider);
    final hoursAsync = ref.watch(professionalWorkingHoursProvider);
    final isSaving = ref.watch(saveWorkingHoursControllerProvider).isLoading;

    if (!_initializedFromProvider && hoursAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initializedFromProvider) return;
        _syncDraftsFromProvider(
          WorkingHoursWeekFactory.fromPersisted(hoursAsync.requireValue),
        );
      });
    }

    final showLoading = scope != null && hoursAsync.isLoading && !hoursAsync.hasValue;
    final showError = scope != null && hoursAsync.hasError && !hoursAsync.hasValue;
    final showMissingProfessional = scope == null;

    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        key: ProfessionalWorkingHoursPage.pageKey,
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(
          backgroundColor: AppColors.warmWhite,
          foregroundColor: AppColors.graphite,
          elevation: 0,
          title: Text(
            AppStrings.workingHoursTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: showMissingProfessional
              ? _MessageState(
                  message: AppStrings.workingHoursProfessionalRequired,
                  onRetry: null,
                )
              : showLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : showError
              ? _MessageState(
                  message: AppStrings.workingHoursLoadError,
                  onRetry: () => ref.invalidate(professionalWorkingHoursProvider),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: AppSpacing.screenPadding.copyWith(
                        top: AppSpacing.sm,
                      ),
                      child: Text(
                        AppStrings.workingHoursSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView(
                        key: ProfessionalWorkingHoursPage.weekListKey,
                        padding: AppSpacing.screenPadding.copyWith(
                          bottom: AppSpacing.sm,
                        ),
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(color: AppColors.divider),
                              boxShadow: AppShadows.level1,
                            ),
                            child: Column(
                              children: [
                                for (var index = 0; index < _drafts.length; index++) ...[
                                  WorkingHoursDayRow(
                                    day: _drafts[index],
                                    onWorkingChanged: (isWorking) => _updateDay(
                                      _drafts[index].weekday,
                                      _drafts[index].copyWith(isWorking: isWorking),
                                    ),
                                    onStartTap: () => _pickStartTime(_drafts[index]),
                                    onEndTap: () => _pickEndTime(_drafts[index]),
                                  ),
                                  if (index < _drafts.length - 1)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors.divider,
                                      indent: AppSpacing.sm,
                                      endIndent: AppSpacing.sm,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_saveError != null) ...[
                      Padding(
                        padding: AppSpacing.screenPadding.copyWith(
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          _saveError!,
                          key: ProfessionalWorkingHoursPage.saveErrorKey,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: AppSpacing.screenPadding.copyWith(
                        bottom: AppSpacing.sm,
                      ),
                      child: AppButton(
                        key: ProfessionalWorkingHoursPage.saveButtonKey,
                        label: AppStrings.workingHoursSaveAction,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : _save,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: AppStrings.tryAgain,
              variant: AppButtonVariant.text,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
