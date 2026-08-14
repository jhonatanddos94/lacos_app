import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/professional/domain/entities/professional.dart';

sealed class SchedulingProfessionalResolution {
  const SchedulingProfessionalResolution();
}

final class SchedulingProfessionalLoading
    extends SchedulingProfessionalResolution {
  const SchedulingProfessionalLoading();
}

final class SchedulingProfessionalFailed
    extends SchedulingProfessionalResolution {
  const SchedulingProfessionalFailed();
}

final class SchedulingProfessionalNone
    extends SchedulingProfessionalResolution {
  const SchedulingProfessionalNone();
}

final class SchedulingProfessionalUnique
    extends SchedulingProfessionalResolution {
  const SchedulingProfessionalUnique(this.professional);

  final Professional professional;
}

final class SchedulingProfessionalMultiple
    extends SchedulingProfessionalResolution {
  const SchedulingProfessionalMultiple(this.professionals);

  final List<Professional> professionals;
}

/// Resolves how AppointmentForm should treat active professionals.
///
/// Never picks `first` from 2+ — that remains a manual picker case.
abstract final class SchedulingProfessionalPolicy {
  static SchedulingProfessionalResolution resolve(
    AsyncValue<List<Professional>> professionalsAsync,
  ) {
    return professionalsAsync.when(
      loading: () => const SchedulingProfessionalLoading(),
      error: (_, _) => const SchedulingProfessionalFailed(),
      data: fromProfessionals,
    );
  }

  static SchedulingProfessionalResolution fromProfessionals(
    List<Professional> professionals,
  ) {
    final active = [
      for (final professional in professionals)
        if (professional.isActive) professional,
    ];

    if (active.isEmpty) {
      return const SchedulingProfessionalNone();
    }

    if (active.length == 1) {
      return SchedulingProfessionalUnique(active.single);
    }

    return SchedulingProfessionalMultiple(active);
  }
}
