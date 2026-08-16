import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/support_config.dart';
import 'package:lacos_app/core/external_url/external_url_providers.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_service.dart';

export 'package:lacos_app/core/external_url/external_url_providers.dart'
    show externalUrlLauncherProvider;

final supportConfigProvider = Provider<SupportConfig>((ref) {
  return SupportConfig.current;
});

final supportWhatsAppServiceProvider = Provider<SupportWhatsAppService>((ref) {
  return SupportWhatsAppService(
    config: ref.watch(supportConfigProvider),
    launcher: ref.watch(externalUrlLauncherProvider),
  );
});
