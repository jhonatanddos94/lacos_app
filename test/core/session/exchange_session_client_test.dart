import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/models/exchange_session_result.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';

void main() {
  group('ExchangeSessionResult.fromDynamic', () {
    test('parses valid payload', () {
      final result = ExchangeSessionResult.fromDynamic(
        {
          'sessionToken': 'r:abc',
          'parseUserId': 'p1',
          'firebaseUid': 'uid-1',
          'email': 'a@test.com',
          'securityMode': 'permissive',
          'isNewUser': true,
        },
        expectedFirebaseUid: 'uid-1',
      );

      expect(result.sessionToken, 'r:abc');
      expect(result.parseUserId, 'p1');
      expect(result.isNewUser, isTrue);
    });

    test('fails when sessionToken missing', () {
      expect(
        () => ExchangeSessionResult.fromDynamic(
          {
            'parseUserId': 'p1',
            'firebaseUid': 'uid-1',
          },
          expectedFirebaseUid: 'uid-1',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails when parseUserId missing', () {
      expect(
        () => ExchangeSessionResult.fromDynamic(
          {
            'sessionToken': 'r:abc',
            'firebaseUid': 'uid-1',
          },
          expectedFirebaseUid: 'uid-1',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails when firebaseUid mismatches', () {
      expect(
        () => ExchangeSessionResult.fromDynamic(
          {
            'sessionToken': 'r:abc',
            'parseUserId': 'p1',
            'firebaseUid': 'other',
          },
          expectedFirebaseUid: 'uid-1',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails on malformed payload', () {
      expect(
        () => ExchangeSessionResult.fromDynamic(
          'not-a-map',
          expectedFirebaseUid: 'uid-1',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('allows optional fields absent', () {
      final result = ExchangeSessionResult.fromDynamic(
        {
          'sessionToken': 'r:abc',
          'parseUserId': 'p1',
          'firebaseUid': 'uid-1',
        },
        expectedFirebaseUid: 'uid-1',
      );

      expect(result.email, isEmpty);
      expect(result.securityMode, 'permissive');
      expect(result.isNewUser, isFalse);
      expect(result.expiresAt, isNull);
    });
  });

  group('ExchangeSessionClient', () {
    test('returns validated result on success', () async {
      final client = ExchangeSessionClient(
        executor: (_) async {
          return ParseResponse()
            ..success = true
            ..result = {
              'sessionToken': 'r:tok',
              'parseUserId': 'p1',
              'firebaseUid': 'uid-1',
              'email': 'a@test.com',
              'securityMode': 'permissive',
              'isNewUser': false,
            };
        },
      );

      final result = await client.exchange(
        idToken: 'id-token',
        expectedFirebaseUid: 'uid-1',
        requestId: 'req-1',
      );

      expect(result.parseUserId, 'p1');
      expect(result.sessionToken, 'r:tok');
    });

    test('maps cloud error JSON without leaking credentials', () async {
      final client = ExchangeSessionClient(
        executor: (_) async {
          return ParseResponse()
            ..success = false
            ..error = ParseError(
              code: 403,
              message:
                  '{"code":"UNAUTHORIZED","message":"Invalid token secret-xyz"}',
            );
        },
      );

      try {
        await client.exchange(
          idToken: 'id-token',
          expectedFirebaseUid: 'uid-1',
          requestId: 'req-1',
        );
        fail('expected AuthSessionException');
      } on AuthSessionException catch (error) {
        expect(error.code, ExchangeSessionErrorMapper.unauthorized);
        expect(error.message, isNot(contains('secret-xyz')));
        expect(error.message, isNot(contains('id-token')));
      }
    });

    test('maps EMAIL_UNVERIFIED', () async {
      final client = ExchangeSessionClient(
        executor: (_) async {
          return ParseResponse()
            ..success = false
            ..error = ParseError(
              code: 403,
              message: '{"code":"EMAIL_UNVERIFIED","message":"verify"}',
            );
        },
      );

      expect(
        () => client.exchange(
          idToken: 'id-token',
          expectedFirebaseUid: 'uid-1',
          requestId: 'req-1',
        ),
        throwsA(
          isA<AuthSessionException>().having(
            (e) => e.code,
            'code',
            ExchangeSessionErrorMapper.emailUnverified,
          ),
        ),
      );
    });
  });
}
