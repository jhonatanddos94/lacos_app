import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/external_url/external_url_launcher.dart';
import 'package:lacos_app/core/external_url/whatsapp_uri_builder.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

enum ClientWhatsappResult { launched, failed, invalidPhone, ignored }

class ClientWhatsappService {
  ClientWhatsappService({required ExternalUrlLauncher launcher})
    : _launcher = launcher;

  final ExternalUrlLauncher _launcher;
  var _isLaunching = false;

  /// Mensagem neutra de abertura: apenas o primeiro nome, sem dados da ficha.
  static String initialMessage(String name) {
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    return firstName.isEmpty
        ? AppStrings.clientWhatsappGreetingFallback
        : AppStrings.clientWhatsappGreeting(firstName);
  }

  Future<ClientWhatsappResult> openConversation(Client client) async {
    if (_isLaunching) return ClientWhatsappResult.ignored;
    if (!WhatsAppUriBuilder.isValidPhone(client.phone)) {
      return ClientWhatsappResult.invalidPhone;
    }

    _isLaunching = true;
    try {
      final uri = WhatsAppUriBuilder.build(
        phone: client.phone,
        message: initialMessage(client.name),
      );
      final launched = await _launcher.launch(uri);
      return launched
          ? ClientWhatsappResult.launched
          : ClientWhatsappResult.failed;
    } on Object {
      return ClientWhatsappResult.failed;
    } finally {
      _isLaunching = false;
    }
  }
}
