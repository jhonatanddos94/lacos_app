import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';

class NoopAdsSdk implements AdsSdk {
  const NoopAdsSdk();

  @override
  bool get isSupported => false;

  @override
  Future<AdsPreparation> prepare() async => AdsPreparation.unsupported;

  @override
  Future<bool> isPrivacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<LoadedBannerAd?> loadAnchoredAdaptiveBanner({
    required int widthDp,
  }) async => null;
}
