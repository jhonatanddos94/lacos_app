import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/support_config.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_service.dart';
import 'package:lacos_app/features/more/application/services/support_whatsapp_uri_builder.dart';

import '../../../../helpers/fake_external_url_launcher.dart';

void main() {
  const message = 'Olá! Preciso de ajuda com o aplicativo Laços.';

  test('F–I/L: builder sanitiza telefone e codifica mensagem PT-BR', () {
    final uri = SupportWhatsAppUriBuilder.build(
      phone: '+55 (67) 99999-9999',
      message: message,
    );

    expect(uri.host, 'wa.me');
    expect(uri.path, '/5567999999999');
    expect(uri.queryParameters['text'], message);
    expect(uri.toString(), contains('%C3%A1'));
    expect(uri.toString(), isNot(contains(' ')));
  });

  test('J: serviço usa configuração e chama launcher uma vez', () async {
    final launcher = FakeExternalUrlLauncher();
    final service = SupportWhatsAppService(
      config: const SupportConfig(
        whatsappPhone: '5567999999999',
        whatsappInitialMessage: message,
      ),
      launcher: launcher,
    );

    expect(await service.open(), SupportLaunchResult.launched);
    expect(launcher.calls, 1);
    expect(launcher.launchedUris.single.host, 'wa.me');
    expect(launcher.launchedUris.single.path, '/5567999999999');
  });

  test('K: chamadas simultâneas não duplicam launch', () async {
    final launcher = FakeExternalUrlLauncher()..completer = Completer<bool>();
    final service = SupportWhatsAppService(
      config: const SupportConfig(
        whatsappPhone: '5567999999999',
        whatsappInitialMessage: message,
      ),
      launcher: launcher,
    );

    final first = service.open();
    expect(await service.open(), SupportLaunchResult.ignored);
    expect(launcher.calls, 1);
    launcher.completer!.complete(true);
    expect(await first, SupportLaunchResult.launched);
  });

  test('M: mensagem configurada é genérica e não contém dados pessoais', () {
    expect(SupportConfig.current.whatsappPhone, '5567999351830');
    expect(SupportConfig.current.whatsappInitialMessage, message);
    expect(message, isNot(contains('@')));
    expect(message, isNot(contains('Studio')));
    expect(message, isNot(contains('appointment')));
    expect(message, isNot(contains('user-')));
  });

  test('N/P: false e exception são convertidos em falha segura', () async {
    final launcher = FakeExternalUrlLauncher(result: false);
    final service = SupportWhatsAppService(
      config: const SupportConfig(
        whatsappPhone: '5567999999999',
        whatsappInitialMessage: message,
      ),
      launcher: launcher,
    );
    expect(await service.open(), SupportLaunchResult.failed);

    launcher
      ..result = true
      ..error = Exception('PlatformException technical URL');
    expect(await service.open(), SupportLaunchResult.failed);
  });

  test('configuração sem número não tenta abrir URL falsa', () async {
    final launcher = FakeExternalUrlLauncher();
    final service = SupportWhatsAppService(
      config: const SupportConfig(
        whatsappPhone: '',
        whatsappInitialMessage: message,
      ),
      launcher: launcher,
    );

    expect(await service.open(), SupportLaunchResult.unavailable);
    expect(launcher.calls, 0);
  });
}
