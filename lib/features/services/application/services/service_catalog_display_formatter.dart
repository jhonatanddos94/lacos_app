import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';

abstract final class ServiceCatalogDisplayFormatter {
  static String details({int? durationMinutes, double? price}) {
    final parts = <String>[];

    if (price != null) {
      parts.add(formatServicePrice(price));
    }

    if (durationMinutes != null && durationMinutes > 0) {
      parts.add(formatServiceDuration(durationMinutes));
    }

    return parts.join(' • ');
  }

  static String semantics({
    required String name,
    int? durationMinutes,
    double? price,
  }) {
    final parts = <String>[name.trim()];

    if (price != null) {
      parts.add(formatServicePrice(price));
    }

    if (durationMinutes != null && durationMinutes > 0) {
      parts.add('$durationMinutes minutos');
    }

    parts.add(AppStrings.servicesOpenLabel);
    return parts.join('. ');
  }
}
