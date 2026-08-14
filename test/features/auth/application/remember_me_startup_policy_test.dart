import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/auth/application/policies/remember_me_startup_policy.dart';

void main() {
  const policy = RememberMeStartupPolicy();

  test('A/G: rememberMe true never signs out persisted sessions', () async {
    var parseCalls = 0;
    var firebaseCalls = 0;

    await policy.apply(
      rememberMe: true,
      hasFirebaseSession: true,
      hasParseSession: true,
      signOutParse: () async => parseCalls++,
      signOutFirebase: () async => firebaseCalls++,
    );

    expect(parseCalls, 0);
    expect(firebaseCalls, 0);
  });

  test('G/M/N: rememberMe false signs out Parse then Firebase', () async {
    final order = <String>[];

    await policy.apply(
      rememberMe: false,
      hasFirebaseSession: true,
      hasParseSession: true,
      signOutParse: () async => order.add('parse'),
      signOutFirebase: () async => order.add('firebase'),
    );

    expect(order, ['parse', 'firebase']);
  });

  test('does nothing when rememberMe is false and no session exists', () async {
    var parseCalls = 0;
    var firebaseCalls = 0;

    await policy.apply(
      rememberMe: false,
      hasFirebaseSession: false,
      hasParseSession: false,
      signOutParse: () async => parseCalls++,
      signOutFirebase: () async => firebaseCalls++,
    );

    expect(parseCalls, 0);
    expect(firebaseCalls, 0);
  });

  test('N: Parse-only persisted session is still cleared', () async {
    var parseCalls = 0;
    var firebaseCalls = 0;

    await policy.apply(
      rememberMe: false,
      hasFirebaseSession: false,
      hasParseSession: true,
      signOutParse: () async => parseCalls++,
      signOutFirebase: () async => firebaseCalls++,
    );

    expect(parseCalls, 1);
    expect(firebaseCalls, 1);
  });

  test('O: Parse logout failure still signs out Firebase', () async {
    var firebaseCalls = 0;
    final errors = <String>[];

    await policy.apply(
      rememberMe: false,
      hasFirebaseSession: true,
      hasParseSession: true,
      signOutParse: () async {
        throw const FormatException('parse fail');
      },
      signOutFirebase: () async => firebaseCalls++,
      onSanitizedError: errors.add,
    );

    expect(firebaseCalls, 1);
    expect(errors, isNotEmpty);
    expect(errors.first, contains('Parse'));
    expect(errors.first, isNot(contains('token')));
  });

  test('P: two startups apply independently without sharing state', () async {
    var parseCalls = 0;

    Future<void> run() {
      return policy.apply(
        rememberMe: false,
        hasFirebaseSession: true,
        hasParseSession: false,
        signOutParse: () async => parseCalls++,
        signOutFirebase: () async {},
      );
    }

    await Future.wait([run(), run()]);
    expect(parseCalls, 2);
  });
}
