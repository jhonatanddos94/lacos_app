import 'package:lacos_app/core/config/support_config.dart';
import 'package:lacos_app/core/external_url/external_url_launcher.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_uri_builder.dart';

enum SupportLaunchResult { launched, failed, unavailable, ignored }

class SupportWhatsAppService {
  SupportWhatsAppService({
    required SupportConfig config,
    required ExternalUrlLauncher launcher,
  }) : _config = config,
       _launcher = launcher;

  final SupportConfig _config;
  final ExternalUrlLauncher _launcher;
  var _isLaunching = false;

  Future<SupportLaunchResult> open() async {
    if (_isLaunching) return SupportLaunchResult.ignored;
    if (_config.whatsappPhone.trim().isEmpty) {
      return SupportLaunchResult.unavailable;
    }

    _isLaunching = true;
    try {
      final uri = SupportWhatsAppUriBuilder.build(
        phone: _config.whatsappPhone,
        message: _config.whatsappInitialMessage,
      );
      final launched = await _launcher.launch(uri);
      return launched
          ? SupportLaunchResult.launched
          : SupportLaunchResult.failed;
    } on Object {
      return SupportLaunchResult.failed;
    } finally {
      _isLaunching = false;
    }
  }
}
