import 'ads_platform_stub.dart'
    if (dart.library.io) 'ads_platform_io.dart'
    as impl;

abstract final class AdsPlatform {
  static bool get isSupported => impl.isAdsPlatformSupported;
}
