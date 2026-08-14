import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/monetization/application/ads_consent_controller.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/monetization/domain/monetization_access.dart';
import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';
import 'package:lacos_app/features/monetization/infrastructure/admob_ids.dart';
import 'package:lacos_app/features/monetization/infrastructure/ads_platform.dart';
import 'package:lacos_app/features/monetization/infrastructure/noop_ads_sdk.dart';

import '../../../helpers/fake_ads_sdk.dart';

void main() {
  test('A/B: App ID Android real não é Banner Unit', () {
    expect(AdMobIds.isAppId(AdMobIds.androidProductionAppId), isTrue);
    expect(AdMobIds.isBannerUnitId(AdMobIds.androidProductionAppId), isFalse);
    expect(
      AdMobIds.isBannerUnitId(AdMobIds.androidProductionBannerUnitId),
      isTrue,
    );
    expect(AdMobIds.isAppId(AdMobIds.androidProductionBannerUnitId), isFalse);
    expect(AdMobIds.androidProductionAppId.contains('~'), isTrue);
    expect(AdMobIds.androidProductionBannerUnitId.contains('/'), isTrue);
  });

  test('C: debug Android usa test Banner Unit mesmo com produção presente', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        buildMode: AdMobBuildMode.debug,
        androidProductionBannerUnitId: AdMobIds.androidProductionBannerUnitId,
      ),
      AdMobIds.androidTestBannerUnitId,
    );
  });

  test('D: profile Android usa test Banner Unit', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        buildMode: AdMobBuildMode.profile,
        androidProductionBannerUnitId: AdMobIds.androidProductionBannerUnitId,
      ),
      AdMobIds.androidTestBannerUnitId,
    );
  });

  test('E: release Android configurado usa production Banner Unit', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        buildMode: AdMobBuildMode.release,
        androidProductionBannerUnitId: AdMobIds.androidProductionBannerUnitId,
      ),
      AdMobIds.androidProductionBannerUnitId,
    );
  });

  test('F/AJ: release Android sem unit não carrega Ads', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        buildMode: AdMobBuildMode.release,
        androidProductionBannerUnitId: '',
      ),
      isNull,
    );
    expect(
      const AdMobAdsConfig(
        buildMode: AdMobBuildMode.release,
      ).hasBannerUnit(TargetPlatform.android),
      isFalse,
    );
    expect(AdMobIds.defaultAndroidProductionBannerUnitId, isEmpty);
  });

  test('G: iOS não reutiliza Android production ID', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.iOS,
        buildMode: AdMobBuildMode.release,
        iosProductionBannerUnitId: AdMobIds.androidProductionBannerUnitId,
      ),
      isNull,
    );
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.iOS,
        buildMode: AdMobBuildMode.release,
        iosProductionBannerUnitId: '',
      ),
      isNull,
    );
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.iOS,
        buildMode: AdMobBuildMode.debug,
      ),
      AdMobIds.iosTestBannerUnitId,
    );
  });

  test('H: plataforma não suportada usa Noop', () async {
    const sdk = NoopAdsSdk();
    expect(sdk.isSupported, isFalse);
    expect(AdsPlatform.isSupported, isFalse);

    final preparation = await sdk.prepare();
    expect(preparation.canRequestAds, isFalse);
    expect(preparation.privacyOptionsRequired, isFalse);
    expect(await sdk.loadAnchoredAdaptiveBanner(widthDp: 320), isNull);
  });

  test('I: Free permite Ads', () {
    const access = MonetizationAccess(tier: MonetizationTier.free);
    expect(access.shouldShowAds, isTrue);
    expect(access.hasAiAccess, isFalse);
    expect(
      adsAreEligible(
        access: access,
        consent: _readyConsent(),
        hasBannerUnit: true,
      ),
      isTrue,
    );
  });

  test('J/K: Premium bloqueia Ads e não cria banner', () {
    const access = MonetizationAccess(tier: MonetizationTier.premium);
    expect(access.shouldShowAds, isFalse);
    expect(access.hasAiAccess, isTrue);
    expect(
      adsAreEligible(
        access: access,
        consent: _readyConsent(),
        hasBannerUnit: true,
      ),
      isFalse,
    );
  });

  test('L/M: consentimento pendente ou canRequestAds false não carrega', () {
    const access = MonetizationAccess(tier: MonetizationTier.free);
    expect(
      adsAreEligible(
        access: access,
        consent: const AdsConsentState(
          isSupported: true,
          isReady: false,
          canRequestAds: false,
          privacyOptionsRequired: false,
          failed: false,
        ),
        hasBannerUnit: true,
      ),
      isFalse,
    );
    expect(
      adsAreEligible(
        access: access,
        consent: const AdsConsentState(
          isSupported: true,
          isReady: true,
          canRequestAds: false,
          privacyOptionsRequired: false,
          failed: false,
        ),
        hasBannerUnit: true,
      ),
      isFalse,
    );
  });

  test('AE: flutter test não inicializa plugin real', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(adsSdkProvider), isA<NoopAdsSdk>());
    expect(container.read(adsSdkProvider), isNot(isA<FakeAdsSdk>()));
  });

  test('AK/AL/AM: App ID, Unit ID e BannerAd ficam na infra', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final slot = File(
      'lib/features/monetization/presentation/widgets/home_ad_slot.dart',
    ).readAsStringSync();
    final home = File(
      'lib/features/home/presentation/pages/home_page.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/features/shell/presentation/pages/app_shell_page.dart',
    ).readAsStringSync();
    final sdk = File(
      'lib/features/monetization/infrastructure/google_mobile_ads_sdk.dart',
    ).readAsStringSync();

    expect(manifest, contains(AdMobIds.androidProductionAppId));
    expect(manifest, isNot(contains(AdMobIds.androidProductionBannerUnitId)));
    expect(manifest, isNot(contains(AdMobIds.androidTestAppId)));

    expect(plist, contains(AdMobIds.iosTestAppId));
    expect(plist, isNot(contains(AdMobIds.androidProductionAppId)));
    expect(plist, isNot(contains(AdMobIds.androidProductionBannerUnitId)));

    for (final source in [slot, home, shell]) {
      expect(source, isNot(contains('ca-app-pub-')));
      expect(source, isNot(contains('BannerAd(')));
    }

    expect(sdk, contains('BannerAd('));
    expect(sdk, isNot(contains('Widget build(BuildContext')));
    expect(slot, contains('WidgetsBinding.instance.addPostFrameCallback'));
  });

  test('release recusa App ID usado como unit', () {
    expect(
      AdMobIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        buildMode: AdMobBuildMode.release,
        androidProductionBannerUnitId: AdMobIds.androidProductionAppId,
      ),
      isNull,
    );
  });
}

AdsConsentState _readyConsent() {
  return const AdsConsentState(
    isSupported: true,
    isReady: true,
    canRequestAds: true,
    privacyOptionsRequired: false,
    failed: false,
  );
}
