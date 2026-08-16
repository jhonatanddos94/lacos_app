import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/external_url/external_url_launcher.dart';
import 'package:lacos_app/core/external_url/url_launcher_external_url_launcher.dart';

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return const UrlLauncherExternalUrlLauncher();
});
