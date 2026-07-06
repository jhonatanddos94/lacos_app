import 'package:flutter/material.dart';

import 'package:lacos_app/features/appointments/presentation/widgets/appointment_duration_summary.dart';

class AppointmentSummaryCard extends StatelessWidget {
  const AppointmentSummaryCard({
    required this.durationLabel,
    this.summaryLabel,
    super.key,
  });

  final String durationLabel;
  final String? summaryLabel;

  @override
  Widget build(BuildContext context) {
    return AppointmentDurationSummary(
      durationLabel: durationLabel,
      summaryLabel: summaryLabel,
    );
  }
}
