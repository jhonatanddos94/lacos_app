import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/external_url/whatsapp_uri_builder.dart';

void main() {
  group('normalizePhone', () {
    test('C/D: telefone local recebe DDI 55', () {
      expect(WhatsAppUriBuilder.normalizePhone('67999999999'), '5567999999999');
      expect(
        WhatsAppUriBuilder.normalizePhone('(67) 99999-9999'),
        '5567999999999',
      );
      expect(
        WhatsAppUriBuilder.normalizePhone('67 99999-9999'),
        '5567999999999',
      );
      expect(WhatsAppUriBuilder.normalizePhone('6733334444'), '556733334444');
    });

    test('E: número já com DDI não recebe 55 duplicado', () {
      expect(WhatsAppUriBuilder.normalizePhone('5567999999999'), '5567999999999');
      expect(
        WhatsAppUriBuilder.normalizePhone('+55 67 99999-9999'),
        '5567999999999',
      );
      expect(
        WhatsAppUriBuilder.normalizePhone('005567999999999'),
        '5567999999999',
      );
      expect(
        WhatsAppUriBuilder.normalizePhone('5567999999999'),
        isNot(startsWith('5555')),
      );
    });

    test('regra vale para qualquer DDD, não só 67', () {
      expect(WhatsAppUriBuilder.normalizePhone('11988887777'), '5511988887777');
      expect(WhatsAppUriBuilder.normalizePhone('85988887777'), '5585988887777');
      expect(WhatsAppUriBuilder.normalizePhone('5511988887777'), '5511988887777');
    });

    test('K/L: vazio e incompleto são inválidos', () {
      for (final phone in ['', '   ', '123', '99999999', '(67) 9999', 'abc']) {
        expect(WhatsAppUriBuilder.normalizePhone(phone), isNull, reason: phone);
        expect(WhatsAppUriBuilder.isValidPhone(phone), isFalse, reason: phone);
      }
      expect(WhatsAppUriBuilder.isValidPhone('67999999999'), isTrue);
    });

    test('número absurdamente longo é inválido', () {
      expect(WhatsAppUriBuilder.normalizePhone('1' * 16), isNull);
    });
  });

  group('build', () {
    test('F/J: usa wa.me e encoda mensagem PT-BR', () {
      final uri = WhatsAppUriBuilder.build(
        phone: '(67) 99999-9999',
        message: 'Olá, Josefa! Tudo bem?',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/5567999999999');
      expect(uri.queryParameters['text'], 'Olá, Josefa! Tudo bem?');
      expect(uri.toString(), contains('%C3%A1'));
      expect(uri.toString(), isNot(contains(' ')));
    });

    test('telefone inválido lança ArgumentError', () {
      expect(
        () => WhatsAppUriBuilder.build(phone: '123', message: 'Olá!'),
        throwsArgumentError,
      );
    });
  });
}
