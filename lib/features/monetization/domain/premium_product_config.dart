/// Catálogo comercial V1 do Laços Premium.
///
/// [displayPrice] é apenas apresentação. Quando Billing entrar, o preço
/// exibido na tela de compra deverá vir da STORE, não desta constante.
/// Esta configuração NÃO confirma valor cobrado nem concede entitlement.
class PremiumProductConfig {
  const PremiumProductConfig({
    required this.productId,
    required this.billingPeriod,
    required this.displayPrice,
    required this.displayPeriodLabel,
  });

  static const current = PremiumProductConfig(
    productId: 'lacos_premium_monthly',
    billingPeriod: PremiumBillingPeriod.monthly,
    displayPrice: 'R\$ 14,99',
    displayPeriodLabel: 'mês',
  );

  /// ID futuro do produto na loja. Ainda não há Billing nesta sprint.
  final String productId;
  final PremiumBillingPeriod billingPeriod;

  /// Preço de apresentação V1. Não usar como valor cobrado.
  final String displayPrice;
  final String displayPeriodLabel;

  String get pricePerPeriod => '$displayPrice/$displayPeriodLabel';
}

enum PremiumBillingPeriod { monthly }
