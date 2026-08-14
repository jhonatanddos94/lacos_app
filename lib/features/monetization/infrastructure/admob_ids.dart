import 'package:flutter/foundation.dart';

/// Modo de build usado só pela infra de Ads. Widgets não leem kReleaseMode.
enum AdMobBuildMode { debug, profile, release }

/// Configuração central de App IDs e Ad Unit IDs do AdMob.
///
/// ANDROID APP ID (APPLICATION_ID, contém "~"):
/// ca-app-pub-4853066438888657~5831297166
///
/// ANDROID HOME BANNER PRODUCTION (unit, contém "/"):
/// ca-app-pub-4853066438888657/1248270501
///
/// Debug/profile must always use Google test ad units.
/// iOS production IDs pending AdMob registration.
///
/// Release banner units come only from dart-defines:
/// ADMOB_ANDROID_BANNER_UNIT_ID / ADMOB_IOS_BANNER_UNIT_ID.
/// Empty define → no ads in release (never a Test Ad).
abstract final class AdMobIds {
  static const androidProductionAppId =
      'ca-app-pub-4853066438888657~5831297166';
  static const androidProductionBannerUnitId =
      'ca-app-pub-4853066438888657/1248270501';

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const androidTestBannerUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const iosTestBannerUnitId = 'ca-app-pub-3940256099942544/2435281174';

  static const _androidBannerOverride = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_UNIT_ID',
  );
  static const _iosBannerOverride = String.fromEnvironment(
    'ADMOB_IOS_BANNER_UNIT_ID',
  );

  static bool isAppId(String value) =>
      value.startsWith('ca-app-pub-') &&
      value.contains('~') &&
      !value.contains('/');

  static bool isBannerUnitId(String value) =>
      value.startsWith('ca-app-pub-') &&
      value.contains('/') &&
      !value.contains('~');

  /// Unit ID de banner para a plataforma/modo, ou null se Ads não devem aparecer.
  static String? bannerAdUnitId({
    required TargetPlatform platform,
    required AdMobBuildMode buildMode,
    String? androidProductionBannerUnitId,
    String? iosProductionBannerUnitId,
  }) {
    if (buildMode != AdMobBuildMode.release) {
      return platform == TargetPlatform.iOS
          ? iosTestBannerUnitId
          : androidTestBannerUnitId;
    }

    final production = platform == TargetPlatform.iOS
        ? (iosProductionBannerUnitId ?? defaultIosProductionBannerUnitId)
        : (androidProductionBannerUnitId ??
              defaultAndroidProductionBannerUnitId);
    if (!_isUsableProductionBannerUnit(production, platform: platform)) {
      return null;
    }
    return production;
  }

  static String get defaultAndroidProductionBannerUnitId =>
      _androidBannerOverride;

  static String get defaultIosProductionBannerUnitId => _iosBannerOverride;

  static bool _isUsableProductionBannerUnit(
    String value, {
    required TargetPlatform platform,
  }) {
    if (!isBannerUnitId(value)) return false;
    if (value == androidTestBannerUnitId || value == iosTestBannerUnitId) {
      return false;
    }
    if (platform == TargetPlatform.iOS &&
        value == androidProductionBannerUnitId) {
      return false;
    }
    if (platform == TargetPlatform.android && value == iosTestBannerUnitId) {
      return false;
    }
    return true;
  }
}

class AdMobAdsConfig {
  const AdMobAdsConfig({
    required this.buildMode,
    this.androidProductionBannerUnitId = '',
    this.iosProductionBannerUnitId = '',
  });

  factory AdMobAdsConfig.current() {
    return AdMobAdsConfig(
      buildMode: AdMobBuildModeX.current,
      androidProductionBannerUnitId:
          AdMobIds.defaultAndroidProductionBannerUnitId,
      iosProductionBannerUnitId: AdMobIds.defaultIosProductionBannerUnitId,
    );
  }

  final AdMobBuildMode buildMode;
  final String androidProductionBannerUnitId;
  final String iosProductionBannerUnitId;

  String? bannerAdUnitId(TargetPlatform platform) {
    return AdMobIds.bannerAdUnitId(
      platform: platform,
      buildMode: buildMode,
      androidProductionBannerUnitId: androidProductionBannerUnitId,
      iosProductionBannerUnitId: iosProductionBannerUnitId,
    );
  }

  bool hasBannerUnit(TargetPlatform platform) =>
      bannerAdUnitId(platform) != null;
}

extension AdMobBuildModeX on AdMobBuildMode {
  static AdMobBuildMode get current {
    if (kReleaseMode) return AdMobBuildMode.release;
    if (kProfileMode) return AdMobBuildMode.profile;
    return AdMobBuildMode.debug;
  }
}
