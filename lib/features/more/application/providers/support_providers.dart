import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/support_config.dart';
import 'package:lacos_app/core/external_url/external_url_launcher.dart';
import 'package:lacos_app/core/external_url/url_launcher_external_url_launcher.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_service.dart';

final supportConfigProvider = Provider<SupportConfig>((ref) {
  return SupportConfig.current;
});

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return const UrlLauncherExternalUrlLauncher();
});

final supportWhatsAppServiceProvider = Provider<SupportWhatsAppService>((ref) {
  return SupportWhatsAppService(
    config: ref.watch(supportConfigProvider),
    launcher: ref.watch(externalUrlLauncherProvider),
  );
});
