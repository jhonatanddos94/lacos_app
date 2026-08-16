import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/monetization/domain/premium_product_config.dart';

void main() {
  test('catálogo V1 centraliza preço de apresentação', () {
    expect(PremiumProductConfig.current.productId, 'lacos_premium_monthly');
    expect(PremiumProductConfig.current.displayPrice, 'R\$ 14,99');
    expect(PremiumProductConfig.current.pricePerPeriod, 'R\$ 14,99/mês');
  });

  test('AK/AL/AA: sem persistência local nem escrita Parse de Premium', () {
    const sources = [
      'lib/features/monetization/domain/premium_product_config.dart',
      'lib/features/monetization/presentation/pages/premium_page.dart',
      'lib/features/more/presentation/pages/more_page.dart',
      'lib/features/more/presentation/widgets/more_premium_card.dart',
      'lib/features/more/presentation/navigation/more_navigation.dart',
    ];

    for (final path in sources) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('isPremium = true')));
      expect(source, isNot(contains("setBool('isPremium'")));
      expect(source, isNot(contains("set<bool>('isPremium'")));
      expect(source, isNot(contains('in_app_purchase')));
    }
  });

  test('AA: PremiumPage e card não consultam domínio operacional', () {
    const files = [
      'lib/features/monetization/presentation/pages/premium_page.dart',
      'lib/features/more/presentation/widgets/more_premium_card.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('workspaceProvider')));
      expect(source, isNot(contains('salonRepository')));
      expect(source, isNot(contains('professionalRepository')));
      expect(source, isNot(contains('clientRepository')));
      expect(source, isNot(contains('appointmentRepository')));
    }
  });
}
