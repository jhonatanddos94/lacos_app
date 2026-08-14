import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/bottom_sheets/professional_profile_form_bottom_sheet.dart';

Future<Professional?> showProfessionalProfileFormBottomSheet(
  BuildContext context, {
  required Professional professional,
}) {
  return showModalBottomSheet<Professional>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) =>
        ProfessionalProfileFormBottomSheet(professional: professional),
  );
}
