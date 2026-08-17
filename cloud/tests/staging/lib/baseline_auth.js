'use strict';

const { maskId } = require('../../../scripts/assert-staging-env');

const AUTH_MODE_PARSE_LOGIN = 'parse_login';
const AUTH_MODE_EXCHANGE_SESSION = 'exchange_session';

function resolveAuthMode(env = process.env) {
  const raw = String(env.LACOS_STAGING_AUTH_MODE || '')
    .trim()
    .toLowerCase();

  if (raw && raw !== AUTH_MODE_PARSE_LOGIN && raw !== AUTH_MODE_EXCHANGE_SESSION) {
    const error = new Error(
      'LACOS_STAGING_AUTH_MODE must be parse_login or exchange_session.',
    );
    error.code = 'STAGING_AUTH_MODE';
    throw error;
  }

  if (raw) {
    return raw;
  }

  const hasParseLogin =
    Boolean(env.LACOS_STAGING_USER_A_USERNAME) &&
    Boolean(env.LACOS_STAGING_USER_A_PASSWORD) &&
    Boolean(env.LACOS_STAGING_USER_B_USERNAME) &&
    Boolean(env.LACOS_STAGING_USER_B_PASSWORD);
  const hasExchangeSession =
    Boolean(env.LACOS_STAGING_ID_TOKEN_A) && Boolean(env.LACOS_STAGING_ID_TOKEN_B);

  if (hasParseLogin) {
    return AUTH_MODE_PARSE_LOGIN;
  }
  if (hasExchangeSession) {
    return AUTH_MODE_EXCHANGE_SESSION;
  }

  return AUTH_MODE_PARSE_LOGIN;
}

function assertBaselineAuthEnv(env = process.env) {
  const mode = resolveAuthMode(env);
  const errors = [];

  if (mode === AUTH_MODE_PARSE_LOGIN) {
    if (!env.LACOS_STAGING_USER_A_USERNAME) {
      errors.push('LACOS_STAGING_USER_A_USERNAME is required for parse_login.');
    }
    if (!env.LACOS_STAGING_USER_A_PASSWORD) {
      errors.push('LACOS_STAGING_USER_A_PASSWORD is required for parse_login.');
    }
    if (!env.LACOS_STAGING_USER_B_USERNAME) {
      errors.push('LACOS_STAGING_USER_B_USERNAME is required for parse_login.');
    }
    if (!env.LACOS_STAGING_USER_B_PASSWORD) {
      errors.push('LACOS_STAGING_USER_B_PASSWORD is required for parse_login.');
    }
  } else {
    if (!env.LACOS_STAGING_ID_TOKEN_A) {
      errors.push('LACOS_STAGING_ID_TOKEN_A is required for exchange_session.');
    }
    if (!env.LACOS_STAGING_ID_TOKEN_B) {
      errors.push('LACOS_STAGING_ID_TOKEN_B is required for exchange_session.');
    }
  }

  if (errors.length > 0) {
    const error = new Error(
      ['Baseline auth aborted.', ...errors.map((line) => `- ${line}`)].join('\n'),
    );
    error.code = 'STAGING_AUTH';
    throw error;
  }

  return { mode };
}

function collectSecrets(env = process.env, users = {}) {
  return [
    env.LACOS_STAGING_USER_A_PASSWORD,
    env.LACOS_STAGING_USER_B_PASSWORD,
    env.LACOS_STAGING_ID_TOKEN_A,
    env.LACOS_STAGING_ID_TOKEN_B,
    env.LACOS_STAGING_MASTER_KEY,
    env.LACOS_STAGING_PARSE_MASTER_KEY,
    env.LACOS_STAGING_CLIENT_KEY,
    users.userA && users.userA.sessionToken,
    users.userB && users.userB.sessionToken,
  ].filter((value) => typeof value === 'string' && value.length > 0);
}

function assertNoSecrets(text, secrets) {
  const haystack = String(text);
  for (const secret of secrets) {
    if (secret && haystack.includes(secret)) {
      const error = new Error('Refusing to log a secret value.');
      error.code = 'STAGING_SECRET_LEAK';
      throw error;
    }
  }
}

function formatAuthSummary({ mode, userA, userB }) {
  return [
    `authMode=${mode}`,
    `User A: ${maskId(userA.parseUserId)}`,
    `User B: ${maskId(userB.parseUserId)}`,
  ].join('\n');
}

function assertDistinctSessions(userA, userB) {
  if (!userA || !userB || !userA.parseUserId || !userB.parseUserId) {
    const error = new Error('Both staging users must resolve to a Parse objectId.');
    error.code = 'STAGING_USER_MISSING';
    throw error;
  }

  if (userA.parseUserId === userB.parseUserId) {
    const error = new Error(
      'User A and User B resolved to the same Parse _User. Aborting.',
    );
    error.code = 'STAGING_USER_COLLISION';
    throw error;
  }

  if (!userA.sessionToken || !userB.sessionToken) {
    const error = new Error('Both staging users must receive a sessionToken.');
    error.code = 'STAGING_SESSION_MISSING';
    throw error;
  }

  if (userA.sessionToken === userB.sessionToken) {
    const error = new Error(
      'User A and User B received the same sessionToken. Aborting.',
    );
    error.code = 'STAGING_SESSION_COLLISION';
    throw error;
  }
}

async function parseLogin(env, { username, password }, http) {
  const response = await http({
    method: 'POST',
    url: `${env.serverURL}/login`,
    headers: {
      'X-Parse-Application-Id': env.applicationId,
      'X-Parse-Client-Key': env.clientKey,
      'Content-Type': 'application/json',
    },
    body: { username, password },
  });

  const body = response.body || {};
  if (response.status >= 400 || !body.objectId || !body.sessionToken) {
    const error = new Error(
      `Parse /login failed status=${response.status} code=${body.code || 'n/a'}`,
    );
    error.code = 'STAGING_LOGIN';
    throw error;
  }

  return {
    parseUserId: body.objectId,
    sessionToken: body.sessionToken,
    username,
  };
}

async function exchangeSessionLogin(env, idToken, http, requestId) {
  const response = await http({
    method: 'POST',
    url: `${env.serverURL}/functions/exchangeSession`,
    headers: {
      'X-Parse-Application-Id': env.applicationId,
      'X-Parse-Client-Key': env.clientKey,
      'Content-Type': 'application/json',
    },
    body: {
      idToken,
      appVersion: 't1-s0',
      platform: 'node',
      requestId,
    },
  });

  const payload = (response.body && response.body.result) || {};
  if (
    response.status >= 400 ||
    typeof payload.sessionToken !== 'string' ||
    !payload.parseUserId
  ) {
    const error = new Error(
      `exchangeSession failed status=${response.status} code=${
        (response.body && response.body.code) || payload.code || 'n/a'
      }`,
    );
    error.code = 'STAGING_EXCHANGE';
    throw error;
  }

  return {
    parseUserId: payload.parseUserId,
    sessionToken: payload.sessionToken,
    isNewUser: payload.isNewUser === true,
  };
}

async function authenticateBaselineUsers({
  env,
  http,
  processEnv = process.env,
}) {
  const { mode } = assertBaselineAuthEnv(processEnv);
  let userA;
  let userB;

  if (mode === AUTH_MODE_PARSE_LOGIN) {
    userA = await parseLogin(
      env,
      {
        username: processEnv.LACOS_STAGING_USER_A_USERNAME,
        password: processEnv.LACOS_STAGING_USER_A_PASSWORD,
      },
      http,
    );
    userB = await parseLogin(
      env,
      {
        username: processEnv.LACOS_STAGING_USER_B_USERNAME,
        password: processEnv.LACOS_STAGING_USER_B_PASSWORD,
      },
      http,
    );
  } else {
    userA = await exchangeSessionLogin(
      env,
      processEnv.LACOS_STAGING_ID_TOKEN_A,
      http,
      `t1s0-a-${Date.now()}`,
    );
    userB = await exchangeSessionLogin(
      env,
      processEnv.LACOS_STAGING_ID_TOKEN_B,
      http,
      `t1s0-b-${Date.now()}`,
    );
  }

  userA.label = 'A';
  userB.label = 'B';
  assertDistinctSessions(userA, userB);

  const summary = formatAuthSummary({ mode, userA, userB });
  assertNoSecrets(summary, collectSecrets(processEnv, { userA, userB }));

  return { mode, userA, userB, summary };
}

module.exports = {
  AUTH_MODE_PARSE_LOGIN,
  AUTH_MODE_EXCHANGE_SESSION,
  resolveAuthMode,
  assertBaselineAuthEnv,
  collectSecrets,
  assertNoSecrets,
  formatAuthSummary,
  assertDistinctSessions,
  parseLogin,
  exchangeSessionLogin,
  authenticateBaselineUsers,
};
