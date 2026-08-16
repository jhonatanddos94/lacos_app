import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';

/// Fonte única de decisão Free/Premium.
///
/// Telas não devem consultar `user.isPremium`. Toda elegibilidade de Ads
/// passa por aqui. A origem do entitlement poderá ser trocada no futuro
/// (Play Billing / App Store + backend) sem refatorar a Home.
///
/// IA ainda não existe. [hasAiAccess] permanece `false` em todos os tiers
/// até uma decisão explícita de produto.
class MonetizationAccess {
  const MonetizationAccess({required this.tier});

  final MonetizationTier tier;

  bool get shouldShowAds => tier == MonetizationTier.free;

  bool get hasAiAccess => false;
}
