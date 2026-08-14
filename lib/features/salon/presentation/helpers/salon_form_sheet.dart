import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/presentation/bottom_sheets/salon_form_bottom_sheet.dart';

Future<Salon?> showSalonFormBottomSheet(
  BuildContext context, {
  required Salon salon,
}) {
  return showModalBottomSheet<Salon>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => SalonFormBottomSheet(salon: salon),
  );
}
