import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';
import 'package:lacos_app/features/monetization/infrastructure/admob_ids.dart';

class GoogleMobileAdsSdk implements AdsSdk {
  GoogleMobileAdsSdk({
    ConsentInformation? consentInformation,
    TargetPlatform? platform,
    AdMobAdsConfig? config,
  }) : _consentInformation = consentInformation ?? ConsentInformation.instance,
       _platform = platform ?? defaultTargetPlatform,
       _config = config ?? AdMobAdsConfig.current();

  final ConsentInformation _consentInformation;
  final TargetPlatform _platform;
  final AdMobAdsConfig _config;
  var _initialized = false;

  @override
  bool get isSupported =>
      _platform == TargetPlatform.android || _platform == TargetPlatform.iOS;

  @override
  Future<AdsPreparation> prepare() async {
    if (!isSupported) return AdsPreparation.unsupported;

    var failed = false;
    try {
      await _requestConsentInfoUpdate();
      await _loadConsentFormIfRequired();
    } on Object {
      failed = true;
    }

    var canRequestAds = false;
    var privacyOptionsRequired = false;
    try {
      canRequestAds = await _consentInformation.canRequestAds();
    } on Object {
      failed = true;
    }
    try {
      privacyOptionsRequired = await isPrivacyOptionsRequired();
    } on Object {
      failed = true;
    }

    if (canRequestAds) {
      try {
        await _initializeSdk();
      } on Object {
        failed = true;
        canRequestAds = false;
      }
    }

    return AdsPreparation(
      canRequestAds: canRequestAds,
      privacyOptionsRequired: privacyOptionsRequired,
      failed: failed,
    );
  }

  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    _consentInformation.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (!completer.isCompleted) {
          completer.completeError(StateError(error.message));
        }
      },
    );
    return completer.future;
  }

  Future<void> _loadConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> _initializeSdk() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await _consentInformation
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!isSupported) return;
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  @override
  Future<LoadedBannerAd?> loadAnchoredAdaptiveBanner({
    required int widthDp,
  }) async {
    if (!isSupported || widthDp <= 0) return null;

    final adUnitId = _config.bannerAdUnitId(_platform);
    if (adUnitId == null) return null;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(widthDp);
    if (size == null) return null;

    final completer = Completer<LoadedBannerAd?>();
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(_GoogleLoadedBannerAd(ad as BannerAd));
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      await banner.load();
      return completer.future;
    } on Object {
      banner.dispose();
      return null;
    }
  }
}

class _GoogleLoadedBannerAd implements LoadedBannerAd {
  _GoogleLoadedBannerAd(this._ad);

  final BannerAd _ad;

  @override
  Size get size => Size(_ad.size.width.toDouble(), _ad.size.height.toDouble());

  @override
  Widget buildWidget() => AdWidget(ad: _ad);

  @override
  void dispose() => _ad.dispose();
}
