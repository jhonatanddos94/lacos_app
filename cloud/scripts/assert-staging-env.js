'use strict';

/**
 * Hard gate: refuses to run against production or without explicit opt-in.
 * Does not print secret values.
 */

const PRODUCTION_APPLICATION_ID_DEFAULT =
  'gg8QDOwG2FI0lRFQ79cFDYxh61mRx2ECqGZSqhWb';

function maskId(value) {
  if (typeof value !== 'string' || value.length < 8) {
    return '[unset]';
  }
  return `${value.slice(0, 4)}…${value.slice(-4)}`;
}

function readStagingApplicationId() {
  return (
    process.env.LACOS_STAGING_APPLICATION_ID ||
    process.env.LACOS_STAGING_PARSE_APPLICATION_ID
  );
}

function readStagingServerUrl() {
  return (
    process.env.LACOS_STAGING_SERVER_URL ||
    process.env.LACOS_STAGING_PARSE_SERVER_URL
  );
}

function readStagingMasterKey() {
  return (
    process.env.LACOS_STAGING_MASTER_KEY ||
    process.env.LACOS_STAGING_PARSE_MASTER_KEY
  );
}

function assertStagingEnv(options = {}) {
  const requireClientKey = options.requireClientKey !== false;
  const requireMasterKey = options.requireMasterKey === true;
  const requireOptIn = options.requireOptIn !== false;
  const errors = [];

  const lacosEnv = String(process.env.LACOS_ENV || '').toLowerCase();
  if (lacosEnv === 'production') {
    errors.push('LACOS_ENV=production is not allowed for staging scripts.');
  }

  const authMode = String(process.env.LACOS_STAGING_AUTH_MODE || '')
    .trim()
    .toLowerCase();
  const hasAuthMode =
    authMode === 'parse_login' || authMode === 'exchange_session';

  if (
    requireOptIn &&
    process.env.LACOS_STAGING_SMOKE !== '1' &&
    process.env.LACOS_STAGING_SEED !== '1' &&
    !hasAuthMode
  ) {
    errors.push(
      'Set LACOS_STAGING_SMOKE=1, LACOS_STAGING_SEED=1, or LACOS_STAGING_AUTH_MODE=parse_login|exchange_session.',
    );
  }

  const stagingAppId = readStagingApplicationId();
  const productionAppId =
    process.env.LACOS_PRODUCTION_APPLICATION_ID ||
    PRODUCTION_APPLICATION_ID_DEFAULT;

  if (!stagingAppId) {
    errors.push(
      'LACOS_STAGING_APPLICATION_ID or LACOS_STAGING_PARSE_APPLICATION_ID is required.',
    );
  } else if (stagingAppId === productionAppId) {
    errors.push(
      'Staging Application ID must not equal the production Application ID.',
    );
  }

  const serverURL = readStagingServerUrl();
  if (!serverURL) {
    errors.push(
      'LACOS_STAGING_SERVER_URL or LACOS_STAGING_PARSE_SERVER_URL is required.',
    );
  }

  if (requireClientKey && !process.env.LACOS_STAGING_CLIENT_KEY) {
    errors.push('LACOS_STAGING_CLIENT_KEY is required for function calls.');
  }

  const masterKey = readStagingMasterKey();
  if (requireMasterKey && !masterKey) {
    errors.push(
      'LACOS_STAGING_MASTER_KEY or LACOS_STAGING_PARSE_MASTER_KEY is required.',
    );
  }

  if (errors.length > 0) {
    const message = [
      'Staging script aborted (safe default).',
      ...errors.map((line) => `- ${line}`),
      `Production Application ID (masked): ${maskId(productionAppId)}`,
      `Staging Application ID (masked): ${maskId(stagingAppId)}`,
      'See cloud/docs/staging-exchange-session-runbook.md',
    ].join('\n');

    const error = new Error(message);
    error.code = 'STAGING_GATE';
    throw error;
  }

  return {
    applicationId: stagingAppId,
    serverURL: String(serverURL).replace(/\/$/, ''),
    clientKey: process.env.LACOS_STAGING_CLIENT_KEY || null,
    masterKey: masterKey || null,
    productionApplicationId: productionAppId,
  };
}

module.exports = {
  assertStagingEnv,
  maskId,
  PRODUCTION_APPLICATION_ID_DEFAULT,
  readStagingApplicationId,
  readStagingServerUrl,
  readStagingMasterKey,
};
