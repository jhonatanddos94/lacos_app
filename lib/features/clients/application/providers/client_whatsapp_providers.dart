import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/external_url/external_url_providers.dart';
import 'package:lacos_app/features/clients/application/services/client_whatsapp_service.dart';

final clientWhatsappServiceProvider = Provider<ClientWhatsappService>((ref) {
  return ClientWhatsappService(launcher: ref.watch(externalUrlLauncherProvider));
});
