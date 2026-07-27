'use strict';

const assert = require('assert');
const { exchangeSession } = require('../../functions/exchangeSession');
const { CloudError, ErrorCodes } = require('../../shared/errors');

function baseConfig() {
  return {
    featureFlags: { securityMode: 'permissive' },
    constants: { MAX_ID_TOKEN_LENGTH: 16384, APP_NAME: 'lacos-cloud' },
  };
}

async function expectCloudError(promise, code) {
  try {
    await promise;
    assert.fail(`expected ${code}`);
  } catch (error) {
    assert.ok(error instanceof CloudError);
    assert.strictEqual(error.code, code);
  }
}

async function run() {
  // sucesso usuário existente
  {
    const result = await exchangeSession(
      {
        params: {
          idToken: 'firebase-id-token',
          appVersion: '1.0.0',
          platform: 'ios',
          firebaseUid: 'attacker-uid',
          salonId: 'other-salon',
        },
      },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async (token) => {
            assert.strictEqual(token, 'firebase-id-token');
            return {
              uid: 'real-uid-123456',
              email: 'a@example.com',
              emailVerified: true,
              disabled: false,
              issuedAt: null,
              expiresAt: null,
            };
          },
        },
        parseUserService: {
          setParse() {},
          findOrCreateFromFirebaseIdentity: async (identity) => {
            assert.strictEqual(identity.uid, 'real-uid-123456');
            return {
              user: { id: 'parse-1' },
              isNewUser: false,
            };
          },
        },
        sessionService: {
          setParse() {},
          createSessionForUser: async (user) => {
            assert.strictEqual(user.id, 'parse-1');
            return {
              sessionToken: 'r:abc',
              parseUserId: 'parse-1',
              expiresAt: null,
            };
          },
        },
      },
    );

    assert.strictEqual(result.sessionToken, 'r:abc');
    assert.strictEqual(result.parseUserId, 'parse-1');
    assert.strictEqual(result.firebaseUid, 'real-uid-123456');
    assert.strictEqual(result.email, 'a@example.com');
    assert.strictEqual(result.securityMode, 'permissive');
    assert.strictEqual(result.isNewUser, false);
    assert.ok(!Object.prototype.hasOwnProperty.call(result, 'password'));
    assert.ok(!JSON.stringify(result).includes('attacker-uid'));
  }

  // sucesso usuário novo
  {
    const result = await exchangeSession(
      { params: { idToken: 'tok' } },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => ({
            uid: 'new-uid-000001',
            email: 'n@example.com',
            emailVerified: true,
            disabled: false,
          }),
        },
        parseUserService: {
          setParse() {},
          findOrCreateFromFirebaseIdentity: async () => ({
            user: { id: 'parse-new' },
            isNewUser: true,
          }),
        },
        sessionService: {
          setParse() {},
          createSessionForUser: async () => ({
            sessionToken: 'r:new',
            parseUserId: 'parse-new',
            expiresAt: '2030-01-01T00:00:00.000Z',
          }),
        },
      },
    );

    assert.strictEqual(result.isNewUser, true);
    assert.strictEqual(result.expiresAt, '2030-01-01T00:00:00.000Z');
  }

  // token ausente
  await expectCloudError(
    exchangeSession({ params: {} }, { loadConfig: baseConfig }),
    ErrorCodes.VALIDATION,
  );

  // token inválido
  await expectCloudError(
    exchangeSession(
      { params: { idToken: 'bad' } },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => {
            throw new CloudError(
              ErrorCodes.UNAUTHORIZED,
              'Invalid or expired authentication token.',
              { statusCode: 401 },
            );
          },
        },
      },
    ),
    ErrorCodes.UNAUTHORIZED,
  );

  // email não verificado
  await expectCloudError(
    exchangeSession(
      { params: { idToken: 'tok' } },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => ({
            uid: 'uid-unverified',
            email: 'u@example.com',
            emailVerified: false,
            disabled: false,
          }),
        },
      },
    ),
    ErrorCodes.EMAIL_UNVERIFIED,
  );

  // erro temporário
  await expectCloudError(
    exchangeSession(
      { params: { idToken: 'tok' } },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => ({
            uid: 'uid-temp',
            email: 't@example.com',
            emailVerified: true,
            disabled: false,
          }),
        },
        parseUserService: {
          setParse() {},
          findOrCreateFromFirebaseIdentity: async () => {
            throw new CloudError(
              ErrorCodes.TEMPORARY,
              'Unable to prepare user account.',
              { statusCode: 503 },
            );
          },
        },
      },
    ),
    ErrorCodes.TEMPORARY,
  );

  // erro interno sanitizado
  try {
    await exchangeSession(
      { params: { idToken: 'tok' } },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => {
            throw new Error('secret stack with master-key-value');
          },
        },
      },
    );
    assert.fail('expected internal');
  } catch (error) {
    assert.strictEqual(error.code, ErrorCodes.INTERNAL);
    assert.ok(!String(error.message).includes('master-key-value'));
  }

  // campos não confiáveis ignorados (UID vem só do token)
  {
    let seenUid;
    await exchangeSession(
      {
        params: {
          idToken: 'tok',
          firebaseUid: 'spoofed',
          email: 'spoof@evil.com',
          parseUserId: 'spoof-parse',
          ownerId: 'spoof-owner',
        },
      },
      {
        loadConfig: baseConfig,
        firebaseAuthService: {
          verifyIdToken: async () => ({
            uid: 'trusted-uid-9999',
            email: 'trusted@example.com',
            emailVerified: true,
            disabled: false,
          }),
        },
        parseUserService: {
          setParse() {},
          findOrCreateFromFirebaseIdentity: async (identity) => {
            seenUid = identity.uid;
            assert.strictEqual(identity.email, 'trusted@example.com');
            return { user: { id: 'p1' }, isNewUser: false };
          },
        },
        sessionService: {
          setParse() {},
          createSessionForUser: async () => ({
            sessionToken: 'r:1',
            parseUserId: 'p1',
            expiresAt: null,
          }),
        },
      },
    );
    assert.strictEqual(seenUid, 'trusted-uid-9999');
  }
}

module.exports = { run };
