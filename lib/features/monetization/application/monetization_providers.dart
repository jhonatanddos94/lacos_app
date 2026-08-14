import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/monetization/application/ads_consent_controller.dart';
import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';
import 'package:lacos_app/features/monetization/domain/monetization_access.dart';
import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';
import 'package:lacos_app/features/monetization/infrastructure/admob_ids.dart';
import 'package:lacos_app/features/monetization/infrastructure/ads_platform.dart';
import 'package:lacos_app/features/monetization/infrastructure/google_mobile_ads_sdk.dart';
import 'package:lacos_app/features/monetization/infrastructure/noop_ads_sdk.dart';

/// V1: todo mundo é Free. Trocar este provider quando houver entitlement real.
final monetizationTierProvider = Provider<MonetizationTier>((ref) {
  return MonetizationTier.free;
});

final monetizationAccessProvider = Provider<MonetizationAccess>((ref) {
  return MonetizationAccess(tier: ref.watch(monetizationTierProvider));
});

final adMobAdsConfigProvider = Provider<AdMobAdsConfig>((ref) {
  return AdMobAdsConfig.current();
});

final adsSdkProvider = Provider<AdsSdk>((ref) {
  if (!AdsPlatform.isSupported) {
    return const NoopAdsSdk();
  }
  return GoogleMobileAdsSdk(config: ref.watch(adMobAdsConfigProvider));
});

final adsConsentControllerProvider =
    StateNotifierProvider<AdsConsentController, AdsConsentState>((ref) {
      return AdsConsentController(ref.watch(adsSdkProvider));
    });

/// Dispara consentimento/initialize sem a UI esperar o Future.
final adsBootstrapProvider = Provider<void>((ref) {
  ref.read(adsConsentControllerProvider.notifier);
});

bool adsAreEligible({
  required MonetizationAccess access,
  required AdsConsentState consent,
  required bool hasBannerUnit,
}) {
  return access.shouldShowAds &&
      consent.isSupported &&
      consent.isReady &&
      consent.canRequestAds &&
      hasBannerUnit;
}
