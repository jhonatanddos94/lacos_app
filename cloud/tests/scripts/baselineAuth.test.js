'use strict';

const assert = require('assert');
const {
  assertStagingEnv,
  PRODUCTION_APPLICATION_ID_DEFAULT,
} = require('../../scripts/assert-staging-env');
const {
  AUTH_MODE_PARSE_LOGIN,
  AUTH_MODE_EXCHANGE_SESSION,
  resolveAuthMode,
  assertBaselineAuthEnv,
  collectSecrets,
  assertNoSecrets,
  formatAuthSummary,
  assertDistinctSessions,
  authenticateBaselineUsers,
} = require('../staging/lib/baseline_auth');

function restore(name, value) {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
}

function withEnv(overrides, fn) {
  const keys = Object.keys(overrides);
  const previous = {};
  keys.forEach((key) => {
    previous[key] = process.env[key];
    if (overrides[key] === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = overrides[key];
    }
  });
  try {
    return fn();
  } finally {
    keys.forEach((key) => restore(key, previous[key]));
  }
}

function createMemoryHttp(handlers) {
  const calls = [];
  return {
    calls,
    http: async ({ method, url, headers, body }) => {
      calls.push({ method, url, headers, body });
      const handler = handlers.shift();
      assert.ok(handler, `unexpected HTTP ${method} ${url}`);
      return handler({ method, url, headers, body });
    },
  };
}

async function run() {
  withEnv(
    {
      LACOS_STAGING_AUTH_MODE: AUTH_MODE_PARSE_LOGIN,
      LACOS_STAGING_USER_A_USERNAME: undefined,
      LACOS_STAGING_USER_A_PASSWORD: undefined,
      LACOS_STAGING_USER_B_USERNAME: undefined,
      LACOS_STAGING_USER_B_PASSWORD: undefined,
      LACOS_STAGING_ID_TOKEN_A: undefined,
      LACOS_STAGING_ID_TOKEN_B: undefined,
    },
    () => {
      assert.strictEqual(resolveAuthMode(), AUTH_MODE_PARSE_LOGIN);
      let blocked = false;
      try {
        assertBaselineAuthEnv();
      } catch (error) {
        blocked = true;
        assert.strictEqual(error.code, 'STAGING_AUTH');
        assert.ok(String(error.message).includes('LACOS_STAGING_USER_A_USERNAME'));
        assert.ok(String(error.message).includes('LACOS_STAGING_USER_A_PASSWORD'));
        assert.ok(String(error.message).includes('LACOS_STAGING_USER_B_USERNAME'));
        assert.ok(String(error.message).includes('LACOS_STAGING_USER_B_PASSWORD'));
        assert.ok(!String(error.message).includes('LACOS_STAGING_ID_TOKEN_A'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  withEnv(
    {
      LACOS_STAGING_AUTH_MODE: AUTH_MODE_EXCHANGE_SESSION,
      LACOS_STAGING_ID_TOKEN_A: undefined,
      LACOS_STAGING_ID_TOKEN_B: undefined,
      LACOS_STAGING_USER_A_USERNAME: 'teste_a',
      LACOS_STAGING_USER_A_PASSWORD: 'secret-a',
      LACOS_STAGING_USER_B_USERNAME: 'teste_b',
      LACOS_STAGING_USER_B_PASSWORD: 'secret-b',
    },
    () => {
      assert.strictEqual(resolveAuthMode(), AUTH_MODE_EXCHANGE_SESSION);
      let blocked = false;
      try {
        assertBaselineAuthEnv();
      } catch (error) {
        blocked = true;
        assert.strictEqual(error.code, 'STAGING_AUTH');
        assert.ok(String(error.message).includes('LACOS_STAGING_ID_TOKEN_A'));
        assert.ok(String(error.message).includes('LACOS_STAGING_ID_TOKEN_B'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  withEnv(
    {
      LACOS_STAGING_AUTH_MODE: AUTH_MODE_PARSE_LOGIN,
      LACOS_STAGING_USER_A_USERNAME: 'teste_a',
      LACOS_STAGING_USER_A_PASSWORD: 'secret-a',
      LACOS_STAGING_USER_B_USERNAME: 'teste_b',
      LACOS_STAGING_USER_B_PASSWORD: 'secret-b',
      LACOS_STAGING_ID_TOKEN_A: undefined,
      LACOS_STAGING_ID_TOKEN_B: undefined,
    },
    () => {
      const auth = assertBaselineAuthEnv();
      assert.strictEqual(auth.mode, AUTH_MODE_PARSE_LOGIN);
    },
  );

  withEnv(
    {
      LACOS_ENV: 'production',
      LACOS_STAGING_AUTH_MODE: AUTH_MODE_PARSE_LOGIN,
      LACOS_STAGING_APPLICATION_ID: 'stgAppIdXXXXYYYY',
      LACOS_STAGING_SERVER_URL: 'https://parseapi.back4app.com',
      LACOS_STAGING_CLIENT_KEY: 'client-test',
      LACOS_STAGING_USER_A_USERNAME: 'teste_a',
      LACOS_STAGING_USER_A_PASSWORD: 'secret-a',
      LACOS_STAGING_USER_B_USERNAME: 'teste_b',
      LACOS_STAGING_USER_B_PASSWORD: 'secret-b',
    },
    () => {
      let blocked = false;
      try {
        assertStagingEnv();
      } catch (error) {
        blocked = true;
        assert.strictEqual(error.code, 'STAGING_GATE');
        assert.ok(String(error.message).includes('production'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  withEnv(
    {
      LACOS_ENV: 'staging',
      LACOS_STAGING_AUTH_MODE: AUTH_MODE_PARSE_LOGIN,
      LACOS_STAGING_APPLICATION_ID: PRODUCTION_APPLICATION_ID_DEFAULT,
      LACOS_STAGING_SERVER_URL: 'https://parseapi.back4app.com',
      LACOS_STAGING_CLIENT_KEY: 'client-test',
    },
    () => {
      let blocked = false;
      try {
        assertStagingEnv();
      } catch (error) {
        blocked = true;
        assert.ok(String(error.message).includes('must not equal the production'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  let sameUser = false;
  try {
    assertDistinctSessions(
      { parseUserId: 'same-user', sessionToken: 'token-aaaa-1111' },
      { parseUserId: 'same-user', sessionToken: 'token-bbbb-2222' },
    );
  } catch (error) {
    sameUser = true;
    assert.strictEqual(error.code, 'STAGING_USER_COLLISION');
  }
  assert.strictEqual(sameUser, true);

  let sameSession = false;
  try {
    assertDistinctSessions(
      { parseUserId: 'user-a', sessionToken: 'same-session-token' },
      { parseUserId: 'user-b', sessionToken: 'same-session-token' },
    );
  } catch (error) {
    sameSession = true;
    assert.strictEqual(error.code, 'STAGING_SESSION_COLLISION');
  }
  assert.strictEqual(sameSession, true);

  const loginHttp = createMemoryHttp([
    () => ({
      status: 200,
      body: {
        objectId: 'userAobjectIdXX',
        sessionToken: 'r:session-token-user-a-secret',
      },
    }),
    () => ({
      status: 200,
      body: {
        objectId: 'userBobjectIdYY',
        sessionToken: 'r:session-token-user-b-secret',
      },
    }),
  ]);

  const processEnv = {
    LACOS_STAGING_AUTH_MODE: AUTH_MODE_PARSE_LOGIN,
    LACOS_STAGING_USER_A_USERNAME: 'teste_a',
    LACOS_STAGING_USER_A_PASSWORD: 'super-secret-password-a',
    LACOS_STAGING_USER_B_USERNAME: 'teste_b',
    LACOS_STAGING_USER_B_PASSWORD: 'super-secret-password-b',
  };

  const authenticated = await authenticateBaselineUsers({
    env: {
      applicationId: 'stgAppIdXXXXYYYY',
      serverURL: 'https://example.test',
      clientKey: 'client-test',
    },
    http: loginHttp.http,
    processEnv,
  });

  assert.strictEqual(authenticated.mode, AUTH_MODE_PARSE_LOGIN);
  assert.strictEqual(authenticated.userA.parseUserId, 'userAobjectIdXX');
  assert.strictEqual(authenticated.userB.parseUserId, 'userBobjectIdYY');
  assert.ok(loginHttp.calls.every((call) => call.url.endsWith('/login')));
  assert.ok(
    loginHttp.calls.every((call) => !JSON.stringify(call.headers).includes('Master')),
  );

  const summary = formatAuthSummary(authenticated);
  const secrets = collectSecrets(processEnv, authenticated);
  assertNoSecrets(summary, secrets);
  assert.ok(!summary.includes('super-secret-password-a'));
  assert.ok(!summary.includes('super-secret-password-b'));
  assert.ok(!summary.includes('r:session-token-user-a-secret'));
  assert.ok(!summary.includes('r:session-token-user-b-secret'));
  assert.ok(summary.includes('User A:'));
  assert.ok(summary.includes('User B:'));

  let leaked = false;
  try {
    assertNoSecrets(
      'password=super-secret-password-a',
      collectSecrets(processEnv, authenticated),
    );
  } catch (error) {
    leaked = true;
    assert.strictEqual(error.code, 'STAGING_SECRET_LEAK');
  }
  assert.strictEqual(leaked, true);

  const collisionHttp = createMemoryHttp([
    () => ({
      status: 200,
      body: { objectId: 'same-user-id-xx', sessionToken: 'r:token-a-distinct' },
    }),
    () => ({
      status: 200,
      body: { objectId: 'same-user-id-xx', sessionToken: 'r:token-b-distinct' },
    }),
  ]);
  let loginCollision = false;
  try {
    await authenticateBaselineUsers({
      env: {
        applicationId: 'stgAppIdXXXXYYYY',
        serverURL: 'https://example.test',
        clientKey: 'client-test',
      },
      http: collisionHttp.http,
      processEnv,
    });
  } catch (error) {
    loginCollision = true;
    assert.strictEqual(error.code, 'STAGING_USER_COLLISION');
    assert.ok(!String(error.message).includes('super-secret-password-a'));
  }
  assert.strictEqual(loginCollision, true);

  const failedLogin = createMemoryHttp([
    () => ({ status: 401, body: { code: 101, error: 'invalid login' } }),
  ]);
  let loginFailed = false;
  try {
    await authenticateBaselineUsers({
      env: {
        applicationId: 'stgAppIdXXXXYYYY',
        serverURL: 'https://example.test',
        clientKey: 'client-test',
      },
      http: failedLogin.http,
      processEnv,
    });
  } catch (error) {
    loginFailed = true;
    assert.strictEqual(error.code, 'STAGING_LOGIN');
    assert.ok(!String(error.message).includes('super-secret-password-a'));
    assert.ok(!String(error.message).includes('super-secret-password-b'));
  }
  assert.strictEqual(loginFailed, true);
}

module.exports = { run };
