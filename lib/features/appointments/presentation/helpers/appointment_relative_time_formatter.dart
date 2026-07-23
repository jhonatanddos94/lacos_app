import 'package:lacos_app/core/config/app_strings.dart';

class AppointmentRelativeTimeFormatter {
  const AppointmentRelativeTimeFormatter();

  String formatSince({required DateTime reference, DateTime? now}) {
    final moment = now ?? DateTime.now();
    if (!moment.isAfter(reference)) {
      return '';
    }

    final totalMinutes = moment.difference(reference).inMinutes;

    if (totalMinutes < 60) {
      if (totalMinutes <= 1) {
        return 'há 1 minuto';
      }

      return 'há $totalMinutes minutos';
    }

    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;

    if (hours < 24) {
      if (remainingMinutes == 0) {
        return hours == 1 ? 'há 1h' : 'há ${hours}h';
      }

      return 'há ${hours}h ${remainingMinutes}min';
    }

    final days = totalMinutes ~/ (60 * 24);
    return days == 1 ? 'há 1 dia' : 'há $days dias';
  }

  String formatOverdueWaitingSince({required DateTime endAt, DateTime? now}) {
    final relative = formatSince(reference: endAt, now: now);
    if (relative.isEmpty) {
      return '';
    }

    return '${AppStrings.appointmentOperationalOverdueRelativePrefix} $relative';
  }
}
