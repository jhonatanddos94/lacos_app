import 'package:flutter/material.dart';

import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class AppointmentSelectedServiceTile extends StatelessWidget {
  const AppointmentSelectedServiceTile({
    required this.service,
    required this.onTap,
    super.key,
  });

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = formatServiceDetails(
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

    return AppointmentFormSelectTile(
      title: service.name,
      subtitle: details.isNotEmpty ? details : null,
      onTap: onTap,
    );
  }
}
