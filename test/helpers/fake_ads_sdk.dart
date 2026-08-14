import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';

class FakeAdsSdk implements AdsSdk {
  FakeAdsSdk({
    this.isSupported = true,
    this.canRequestAds = true,
    this.privacyOptionsRequired = false,
    this.prepareFails = false,
    this.initializeFails = false,
    this.loadFails = false,
    this.adaptiveSizeNull = false,
    this.bannerSize = const Size(320, 50),
    this.prepareCompleter,
    this.loadCompleter,
  });

  @override
  final bool isSupported;

  bool canRequestAds;
  bool privacyOptionsRequired;
  bool prepareFails;
  bool initializeFails;
  bool loadFails;
  bool adaptiveSizeNull;
  Size bannerSize;
  Completer<void>? prepareCompleter;
  Completer<LoadedBannerAd?>? loadCompleter;

  int prepareCalls = 0;
  int initializeEquivalentCalls = 0;
  int loadCalls = 0;
  int disposeCalls = 0;
  int privacyOptionsCalls = 0;
  FakeLoadedBannerAd? lastBanner;

  @override
  Future<AdsPreparation> prepare() async {
    prepareCalls++;
    initializeEquivalentCalls++;
    if (prepareCompleter != null) {
      await prepareCompleter!.future;
    }
    if (prepareFails) {
      return AdsPreparation(
        canRequestAds: canRequestAds,
        privacyOptionsRequired: privacyOptionsRequired,
        failed: true,
      );
    }
    if (initializeFails) {
      return AdsPreparation(
        canRequestAds: false,
        privacyOptionsRequired: privacyOptionsRequired,
        failed: true,
      );
    }
    return AdsPreparation(
      canRequestAds: canRequestAds,
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsCalls++;
  }

  @override
  Future<LoadedBannerAd?> loadAnchoredAdaptiveBanner({
    required int widthDp,
  }) async {
    loadCalls++;
    if (loadCompleter != null) {
      return loadCompleter!.future;
    }
    if (loadFails || adaptiveSizeNull) return null;
    lastBanner = FakeLoadedBannerAd(
      size: bannerSize,
      onDispose: () => disposeCalls++,
    );
    return lastBanner;
  }
}

class FakeLoadedBannerAd implements LoadedBannerAd {
  FakeLoadedBannerAd({required this.size, required this.onDispose});

  @override
  final Size size;
  final VoidCallback onDispose;

  @override
  Widget buildWidget() {
    return const ColoredBox(
      color: Color(0xFFEDE7F6),
      child: Center(child: Text('AdMob Test')),
    );
  }

  @override
  void dispose() => onDispose();
}
