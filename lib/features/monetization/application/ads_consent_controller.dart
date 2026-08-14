import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';

class AdsConsentState {
  const AdsConsentState({
    required this.isSupported,
    required this.isReady,
    required this.canRequestAds,
    required this.privacyOptionsRequired,
    required this.failed,
  });

  static const initial = AdsConsentState(
    isSupported: false,
    isReady: false,
    canRequestAds: false,
    privacyOptionsRequired: false,
    failed: false,
  );

  final bool isSupported;
  final bool isReady;
  final bool canRequestAds;
  final bool privacyOptionsRequired;
  final bool failed;
}

class AdsConsentController extends StateNotifier<AdsConsentState> {
  AdsConsentController(this._sdk) : super(AdsConsentState.initial) {
    _start();
  }

  final AdsSdk _sdk;
  var _started = false;

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    if (!_sdk.isSupported) {
      state = const AdsConsentState(
        isSupported: false,
        isReady: true,
        canRequestAds: false,
        privacyOptionsRequired: false,
        failed: false,
      );
      return;
    }

    try {
      final preparation = await _sdk.prepare();
      if (!mounted) return;
      state = AdsConsentState(
        isSupported: true,
        isReady: true,
        canRequestAds: preparation.canRequestAds,
        privacyOptionsRequired: preparation.privacyOptionsRequired,
        failed: preparation.failed,
      );
    } on Object {
      if (!mounted) return;
      state = const AdsConsentState(
        isSupported: true,
        isReady: true,
        canRequestAds: false,
        privacyOptionsRequired: false,
        failed: true,
      );
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      await _sdk.showPrivacyOptions();
    } on Object {
      // Fail-safe: a usuária continua no app.
    }
  }
}
