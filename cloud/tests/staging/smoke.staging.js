'use strict';

/**
 * Remote staging smoke for exchangeSession.
 *
 * Refuses to run unless LACOS_STAGING_SMOKE=1 and a non-production
 * LACOS_STAGING_APPLICATION_ID is configured.
 *
 * Does not log tokens, keys, or passwords.
 */

const { assertStagingEnv, maskId } = require('../../scripts/assert-staging-env');

async function parseFunction(env, name, params) {
  const response = await fetch(`${env.serverURL}/functions/${name}`, {
    method: 'POST',
    headers: {
      'X-Parse-Application-Id': env.applicationId,
      'X-Parse-Client-Key': env.clientKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(params || {}),
  });

  const body = await response.json();
  return { status: response.status, body };
}

async function usersMe(env, sessionToken) {
  const response = await fetch(`${env.serverURL}/users/me`, {
    method: 'GET',
    headers: {
      'X-Parse-Application-Id': env.applicationId,
      'X-Parse-Client-Key': env.clientKey,
      'X-Parse-Session-Token': sessionToken,
    },
  });
  const body = await response.json();
  return { status: response.status, body };
}

function resultPayload(body) {
  return body && body.result !== undefined ? body.result : body;
}

async function main() {
  let env;
  try {
    env = assertStagingEnv();
  } catch (error) {
    console.error(error.message);
    process.exit(2);
  }

  console.log('Staging smoke starting');
  console.log(`applicationId=${maskId(env.applicationId)}`);
  console.log(`serverURL=${env.serverURL}`);

  const ping = await parseFunction(env, 'ping', {});
  if (ping.status !== 200 || resultPayload(ping.body).status !== 'ok') {
    console.error('FAIL ping');
    process.exit(1);
  }
  console.log('OK ping');

  const health = await parseFunction(env, 'health', {});
  const healthResult = resultPayload(health.body);
  if (
    health.status !== 200 ||
    healthResult.status !== 'ok' ||
    healthResult.environment !== 'staging' ||
    healthResult.securityMode !== 'permissive'
  ) {
    console.error('FAIL health (expect environment=staging, securityMode=permissive)');
    process.exit(1);
  }
  console.log('OK health');

  const idToken = process.env.LACOS_STAGING_ID_TOKEN_VERIFIED;
  if (!idToken) {
    console.log(
      'SKIP exchangeSession (set LACOS_STAGING_ID_TOKEN_VERIFIED to run full smoke)',
    );
    console.log('Foundation remote checks passed.');
    process.exit(0);
  }

  const exchange = await parseFunction(env, 'exchangeSession', {
    idToken,
    appVersion: 'staging-smoke',
    platform: 'node',
    requestId: `smoke-${Date.now()}`,
    firebaseUid: 'should-be-ignored',
    salonId: 'should-be-ignored',
  });

  const exchanged = resultPayload(exchange.body);
  if (exchange.status !== 200 || typeof exchanged.sessionToken !== 'string') {
    console.error('FAIL exchangeSession verified user');
    process.exit(1);
  }

  if (
    exchanged.password ||
    exchanged.masterKey ||
    exchanged.private_key ||
    exchanged.idToken
  ) {
    console.error('FAIL exchangeSession leaked sensitive fields');
    process.exit(1);
  }

  console.log(
    `OK exchangeSession parseUserId=${maskId(exchanged.parseUserId)} isNewUser=${exchanged.isNewUser}`,
  );

  const me = await usersMe(env, exchanged.sessionToken);
  if (me.status !== 200 || me.body.objectId !== exchanged.parseUserId) {
    console.error('FAIL sessionToken /users/me mismatch');
    process.exit(1);
  }
  console.log('OK session authenticates /users/me without Master Key');

  const unverified = process.env.LACOS_STAGING_ID_TOKEN_UNVERIFIED;
  if (unverified) {
    const negative = await parseFunction(env, 'exchangeSession', {
      idToken: unverified,
      requestId: `smoke-unverified-${Date.now()}`,
    });
    const errText = JSON.stringify(negative.body);
    if (!errText.includes('EMAIL_UNVERIFIED')) {
      console.error('FAIL expected EMAIL_UNVERIFIED');
      process.exit(1);
    }
    console.log('OK EMAIL_UNVERIFIED');
  } else {
    console.log('SKIP unverified user (LACOS_STAGING_ID_TOKEN_UNVERIFIED unset)');
  }

  const invalid = await parseFunction(env, 'exchangeSession', {
    idToken: 'not-a-real-token',
    requestId: `smoke-invalid-${Date.now()}`,
  });
  const invalidText = JSON.stringify(invalid.body);
  if (!invalidText.includes('UNAUTHORIZED') && !invalidText.includes('VALIDATION')) {
    console.error('FAIL expected UNAUTHORIZED for invalid token');
    process.exit(1);
  }
  console.log('OK invalid token rejected');

  console.log('Staging smoke completed');
}

main().catch((error) => {
  console.error('Staging smoke crashed');
  console.error(error && error.message ? error.message : error);
  process.exit(1);
});
