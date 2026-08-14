import 'package:url_launcher/url_launcher.dart';

import 'package:lacos_app/core/external_url/external_url_launcher.dart';

class UrlLauncherExternalUrlLauncher implements ExternalUrlLauncher {
  const UrlLauncherExternalUrlLauncher();

  @override
  Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
