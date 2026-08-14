import 'package:flutter/widgets.dart';

/// Boundary do SDK de anúncios. Widgets e testes nunca falam com o singleton
/// nativo do Google Mobile Ads.
abstract class AdsSdk {
  bool get isSupported;

  /// Consentimento UMP + initialize. Nunca lança. Nunca bloqueia UI.
  Future<AdsPreparation> prepare();

  Future<bool> isPrivacyOptionsRequired();

  Future<void> showPrivacyOptions();

  Future<LoadedBannerAd?> loadAnchoredAdaptiveBanner({required int widthDp});
}

class AdsPreparation {
  const AdsPreparation({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
    this.failed = false,
  });

  static const unsupported = AdsPreparation(
    canRequestAds: false,
    privacyOptionsRequired: false,
  );

  final bool canRequestAds;
  final bool privacyOptionsRequired;
  final bool failed;
}

abstract class LoadedBannerAd {
  Size get size;

  Widget buildWidget();

  void dispose();
}
