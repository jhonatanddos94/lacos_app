import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_form_bottom_sheet.dart';

Future<Service?> showServiceFormBottomSheet(
  BuildContext context, {
  Service? service,
}) {
  return showModalBottomSheet<Service>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => ServiceFormBottomSheet(service: service),
  );
}
