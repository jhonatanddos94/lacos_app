import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';

abstract final class AgendaAppointmentScroll {
  static const estimatedItemHeight = 76.0;
  static const separatorHeight = 1.0;
  static const viewportAlignmentFactor = 0.25;

  static int? indexForAppointmentId(
    List<AgendaAppointmentDisplay> appointments,
    String appointmentId,
  ) {
    final index = appointments.indexWhere(
      (appointment) => appointment.appointmentId == appointmentId,
    );
    if (index < 0) {
      return null;
    }

    return index;
  }

  static double offsetForIndex(int index) {
    if (index <= 0) {
      return 0;
    }

    return index * (estimatedItemHeight + separatorHeight);
  }

  static double targetOffsetForIndex({
    required int index,
    required double maxScrollExtent,
    double viewportHeight = 0,
  }) {
    final rawOffset = offsetForIndex(index);
    final alignmentOffset = viewportHeight * viewportAlignmentFactor;
    final target = rawOffset - alignmentOffset;

    return target.clamp(0.0, maxScrollExtent);
  }

  static void animateToAppointmentIndex({
    required ScrollController scrollController,
    required int index,
    Duration duration = AppDurations.medium,
    Curve curve = Curves.easeOutCubic,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) {
          return;
        }

        final position = scrollController.position;
        final targetOffset = targetOffsetForIndex(
          index: index,
          maxScrollExtent: position.maxScrollExtent,
          viewportHeight: position.viewportDimension,
        );

        scrollController.animateTo(
          targetOffset,
          duration: duration,
          curve: curve,
        );
      });
    });
  }
}
