import 'package:lacos_app/core/external_url/whatsapp_uri_builder.dart';

abstract final class SupportWhatsAppUriBuilder {
  static Uri build({required String phone, required String message}) {
    return WhatsAppUriBuilder.build(phone: phone, message: message);
  }
}
