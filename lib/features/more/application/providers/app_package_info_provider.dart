import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appPackageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return PackageInfo.fromPlatform();
  } on Object {
    return PackageInfo(
      appName: 'Laços',
      packageName: 'lacos_app',
      version: '1.0.0',
      buildNumber: '1',
    );
  }
});
