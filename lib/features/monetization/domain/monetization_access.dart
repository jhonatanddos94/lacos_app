import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';

/// Fonte única de decisão Free/Premium.
///
/// Telas não devem consultar `user.isPremium`. Toda elegibilidade de Ads/IA
/// passa por aqui. A origem do entitlement poderá ser trocada no futuro
/// (App Store / Play Billing) sem refatorar a Home.
class MonetizationAccess {
  const MonetizationAccess({required this.tier});

  final MonetizationTier tier;

  bool get shouldShowAds => tier == MonetizationTier.free;

  bool get hasAiAccess => tier == MonetizationTier.premium;
}
