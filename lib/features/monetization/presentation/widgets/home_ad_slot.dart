import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/monetization/domain/ads_sdk.dart';

/// Slot de publicidade da Home. Ciclo próprio: não observa workspace,
/// appointments, ticker operacional nem meia-noite.
class HomeAdSlot extends ConsumerStatefulWidget {
  const HomeAdSlot({super.key});

  static const slotKey = Key('home-ad-slot');
  static const bannerKey = Key('home-ad-banner');

  @override
  ConsumerState<HomeAdSlot> createState() => _HomeAdSlotState();
}

class _HomeAdSlotState extends ConsumerState<HomeAdSlot> {
  LoadedBannerAd? _banner;
  var _loadStarted = false;
  var _failed = false;
  Size? _reservedSize;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded(int widthDp) async {
    if (_loadStarted || _failed || widthDp <= 0) return;

    final access = ref.read(monetizationAccessProvider);
    final consent = ref.read(adsConsentControllerProvider);
    final hasBannerUnit = ref
        .read(adMobAdsConfigProvider)
        .hasBannerUnit(defaultTargetPlatform);
    if (!adsAreEligible(
      access: access,
      consent: consent,
      hasBannerUnit: hasBannerUnit,
    )) {
      return;
    }

    _loadStarted = true;
    try {
      final banner = await ref
          .read(adsSdkProvider)
          .loadAnchoredAdaptiveBanner(widthDp: widthDp);
      if (!mounted) {
        banner?.dispose();
        return;
      }
      setState(() {
        _banner = banner;
        _reservedSize = banner?.size;
        _failed = banner == null;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(monetizationAccessProvider);
    final consent = ref.watch(adsConsentControllerProvider);
    final hasBannerUnit = ref
        .watch(adMobAdsConfigProvider)
        .hasBannerUnit(defaultTargetPlatform);
    final eligible = adsAreEligible(
      access: access,
      consent: consent,
      hasBannerUnit: hasBannerUnit,
    );

    if (!access.shouldShowAds || !consent.isSupported || !hasBannerUnit) {
      return const SizedBox.shrink(key: HomeAdSlot.slotKey);
    }

    if (!consent.isReady || !consent.canRequestAds || _failed) {
      return const SizedBox.shrink(key: HomeAdSlot.slotKey);
    }

    return Padding(
      key: HomeAdSlot.slotKey,
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.truncate();
          if (eligible && !_loadStarted && !_failed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadIfNeeded(width);
            });
          }

          final banner = _banner;
          if (banner != null) {
            return Semantics(
              label: AppStrings.adsBannerSemantics,
              child: SizedBox(
                key: HomeAdSlot.bannerKey,
                width: banner.size.width,
                height: banner.size.height,
                child: banner.buildWidget(),
              ),
            );
          }

          if (eligible) {
            return SizedBox(
              width: constraints.maxWidth,
              height: _reservedSize?.height ?? 50,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
