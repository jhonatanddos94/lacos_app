import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/features/services/application/services/service_catalog_display_formatter.dart';

void main() {
  group('formatServiceDuration', () {
    test('minutos, hora e hora com minutos', () {
      expect(formatServiceDuration(30), '30min');
      expect(formatServiceDuration(60), '1h');
      expect(formatServiceDuration(90), '1h 30min');
      expect(formatServiceDuration(0), '');
    });
  });

  group('formatServicePrice', () {
    test('formata em reais brasileiros', () {
      expect(formatServicePrice(80), 'R\$ 80,00');
      expect(formatServicePrice(0), 'R\$ 0,00');
      expect(formatServicePrice(1200), 'R\$ 1.200,00');
    });
  });

  group('ServiceCatalogDisplayFormatter', () {
    test('preço primeiro, depois duração', () {
      expect(
        ServiceCatalogDisplayFormatter.details(durationMinutes: 60, price: 80),
        'R\$ 80,00 • 1h',
      );
    });

    test('omite partes ausentes', () {
      expect(ServiceCatalogDisplayFormatter.details(price: 50), 'R\$ 50,00');
      expect(
        ServiceCatalogDisplayFormatter.details(durationMinutes: 45),
        '45min',
      );
      expect(ServiceCatalogDisplayFormatter.details(), '');
    });

    test('semantics descreve nome, preço, duração e ação', () {
      expect(
        ServiceCatalogDisplayFormatter.semantics(
          name: 'Corte feminino',
          durationMinutes: 60,
          price: 80,
        ),
        'Corte feminino. R\$ 80,00. 60 minutos. ${AppStrings.servicesOpenLabel}',
      );
    });
  });
}
