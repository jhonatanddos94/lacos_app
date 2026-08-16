import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/clients/application/services/client_whatsapp_service.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

import '../../../../helpers/fake_external_url_launcher.dart';

void main() {
  final now = DateTime(2026, 8, 14);

  Client client({String name = 'Josefa Souza', String phone = '67999999999'}) {
    return Client(
      id: 'client-1',
      name: name,
      phone: phone,
      instagram: 'josefa',
      birthDate: DateTime(1990, 3, 2),
      isActive: true,
      isFavorite: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('B/C/D/F/G: abre wa.me com telefone normalizado e saudação', () async {
    final launcher = FakeExternalUrlLauncher();
    final service = ClientWhatsappService(launcher: launcher);

    final result = await service.openConversation(
      client(name: 'Josefa', phone: '(67) 99999-9999'),
    );

    expect(result, ClientWhatsappResult.launched);
    expect(launcher.calls, 1);

    final uri = launcher.launchedUris.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/5567999999999');
    expect(uri.queryParameters['text'], 'Olá, Josefa! Tudo bem?');
  });

  test('E: telefone já com 55 não recebe DDI duplicado', () async {
    final launcher = FakeExternalUrlLauncher();

    await ClientWhatsappService(
      launcher: launcher,
    ).openConversation(client(phone: '+55 67 99999-9999'));

    expect(launcher.launchedUris.single.path, '/5567999999999');
  });

  test('H/I: usa só o primeiro nome e cai no genérico sem nome', () {
    expect(
      ClientWhatsappService.initialMessage('Maria Eduarda Silva'),
      'Olá, Maria! Tudo bem?',
    );
    expect(
      ClientWhatsappService.initialMessage('  Josefa  '),
      'Olá, Josefa! Tudo bem?',
    );
    expect(ClientWhatsappService.initialMessage(''), 'Olá! Tudo bem?');
    expect(ClientWhatsappService.initialMessage('   '), 'Olá! Tudo bem?');
  });

  test('K/L: telefone vazio ou inválido não chama launcher', () async {
    final launcher = FakeExternalUrlLauncher();
    final service = ClientWhatsappService(launcher: launcher);

    for (final phone in ['', '123', '9999']) {
      expect(
        await service.openConversation(client(phone: phone)),
        ClientWhatsappResult.invalidPhone,
        reason: phone,
      );
    }
    expect(launcher.calls, 0);
  });

  test('O/P: false e exception viram falha segura', () async {
    final launcher = FakeExternalUrlLauncher(result: false);
    final service = ClientWhatsappService(launcher: launcher);

    expect(
      await service.openConversation(client()),
      ClientWhatsappResult.failed,
    );

    launcher
      ..result = true
      ..error = Exception('PlatformException channel url_launcher');
    expect(
      await service.openConversation(client()),
      ClientWhatsappResult.failed,
    );
  });

  test('Q: chamadas simultâneas não abrem duas vezes', () async {
    final launcher = FakeExternalUrlLauncher()..completer = Completer<bool>();
    final service = ClientWhatsappService(launcher: launcher);

    final first = service.openConversation(client());
    expect(
      await service.openConversation(client()),
      ClientWhatsappResult.ignored,
    );
    expect(launcher.calls, 1);

    launcher.completer!.complete(true);
    expect(await first, ClientWhatsappResult.launched);

    launcher.completer = null;
    expect(
      await service.openConversation(client()),
      ClientWhatsappResult.launched,
    );
    expect(launcher.calls, 2);
  });

  test('R/T: nada é enviado e a Client não é modificada', () async {
    final launcher = FakeExternalUrlLauncher();
    final original = client();

    await ClientWhatsappService(launcher: launcher).openConversation(original);

    expect(original.name, 'Josefa Souza');
    expect(original.phone, '67999999999');
    expect(original.isFavorite, isTrue);
    expect(launcher.launchedUris.single.queryParameters.keys, ['text']);
  });

  test('privacidade: link não carrega dados internos da ficha', () async {
    final launcher = FakeExternalUrlLauncher();
    await ClientWhatsappService(launcher: launcher).openConversation(client());

    final link = launcher.launchedUris.single.toString();
    for (final leak in ['client-1', 'josefa%40', 'instagram', '1990', 'salon']) {
      expect(link.toLowerCase(), isNot(contains(leak)), reason: leak);
    }
  });
}
