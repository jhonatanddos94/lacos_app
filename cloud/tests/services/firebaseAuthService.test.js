'use strict';

const assert = require('assert');
const { FirebaseAuthService } = require('../../services/FirebaseAuthService');
const { CloudError, ErrorCodes } = require('../../shared/errors');

function createFakeAdmin({
  verifyImpl,
  getUserImpl,
  apps = [],
} = {}) {
  const authApi = {
    verifyIdToken: verifyImpl,
    getUser: getUserImpl,
  };

  return {
    apps,
    app: () => ({ name: '[DEFAULT]' }),
    initializeApp: () => {
      apps.push({});
      return { name: '[DEFAULT]' };
    },
    credential: {
      cert: (account) => ({ type: 'cert', account }),
    },
    auth: () => authApi,
  };
}

async function expectCloudError(promise, code) {
  try {
    await promise;
    assert.fail(`expected CloudError ${code}`);
  } catch (error) {
    assert.ok(error instanceof CloudError);
    assert.strictEqual(error.code, code);
  }
}

async function run() {
  const credentials = {
    project_id: 'app-lacos-test',
    client_email: 'svc@test.iam.gserviceaccount.com',
    private_key: 'fake',
  };

  // token válido
  {
    const adminSdk = createFakeAdmin({
      verifyImpl: async () => ({
        uid: 'uid-12345678',
        email: 'a@example.com',
        email_verified: true,
        iat: 1_700_000_000,
        exp: 1_700_003_600,
      }),
      getUserImpl: async () => ({ disabled: false }),
    });

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => credentials,
      resolveProjectId: () => 'app-lacos-test',
    });

    const identity = await service.verifyIdToken('valid.token');
    assert.strictEqual(identity.uid, 'uid-12345678');
    assert.strictEqual(identity.email, 'a@example.com');
    assert.strictEqual(identity.emailVerified, true);
    assert.strictEqual(identity.disabled, false);
    assert.ok(identity.issuedAt);
    assert.ok(identity.expiresAt);
  }

  // token inválido
  {
    const adminSdk = createFakeAdmin({
      verifyImpl: async () => {
        const error = new Error('bad');
        error.code = 'auth/invalid-id-token';
        throw error;
      },
      getUserImpl: async () => ({ disabled: false }),
    });

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => credentials,
    });

    await expectCloudError(
      service.verifyIdToken('bad.token'),
      ErrorCodes.UNAUTHORIZED,
    );
  }

  // token expirado
  {
    const adminSdk = createFakeAdmin({
      verifyImpl: async () => {
        const error = new Error('expired');
        error.code = 'auth/id-token-expired';
        throw error;
      },
      getUserImpl: async () => ({ disabled: false }),
    });

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => credentials,
    });

    await expectCloudError(
      service.verifyIdToken('expired.token'),
      ErrorCodes.UNAUTHORIZED,
    );
  }

  // email não verificado (identity still returned — gate is in exchangeSession)
  {
    const adminSdk = createFakeAdmin({
      verifyImpl: async () => ({
        uid: 'uid-abcdef12',
        email: 'u@example.com',
        email_verified: false,
        iat: 1,
        exp: 2,
      }),
      getUserImpl: async () => ({ disabled: false }),
    });

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => credentials,
    });

    const identity = await service.verifyIdToken('token');
    assert.strictEqual(identity.emailVerified, false);
  }

  // configuração ausente
  {
    const adminSdk = createFakeAdmin({
      verifyImpl: async () => ({}),
      getUserImpl: async () => ({ disabled: false }),
    });

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => {
        throw new CloudError(
          ErrorCodes.CONFIGURATION_ERROR,
          'Firebase Admin credentials are not configured.',
          { statusCode: 500 },
        );
      },
    });

    await expectCloudError(
      service.verifyIdToken('token'),
      ErrorCodes.CONFIGURATION_ERROR,
    );
  }

  // inicialização única
  {
    let initCount = 0;
    const apps = [];
    const adminSdk = {
      apps,
      app: () => ({ name: '[DEFAULT]' }),
      initializeApp: () => {
        initCount += 1;
        apps.push({});
        return { name: '[DEFAULT]' };
      },
      credential: {
        cert: () => ({}),
      },
      auth: () => ({
        verifyIdToken: async () => ({
          uid: 'uid-zzzzzzzz',
          email_verified: true,
        }),
        getUser: async () => ({ disabled: false }),
      }),
    };

    const service = new FirebaseAuthService({
      adminSdk,
      loadCredentials: () => credentials,
    });

    await service.verifyIdToken('t1');
    await service.verifyIdToken('t2');
    assert.strictEqual(initCount, 1);
  }
}

module.exports = { run };
