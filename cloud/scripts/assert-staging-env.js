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

function assertStagingEnv() {
  const errors = [];

  if (process.env.LACOS_STAGING_SMOKE !== '1') {
    errors.push(
      'Set LACOS_STAGING_SMOKE=1 to explicitly enable remote staging smoke.',
    );
  }

  const stagingAppId = process.env.LACOS_STAGING_APPLICATION_ID;
  const productionAppId =
    process.env.LACOS_PRODUCTION_APPLICATION_ID ||
    PRODUCTION_APPLICATION_ID_DEFAULT;

  if (!stagingAppId) {
    errors.push('LACOS_STAGING_APPLICATION_ID is required.');
  } else if (stagingAppId === productionAppId) {
    errors.push(
      'LACOS_STAGING_APPLICATION_ID must not equal the production Application ID.',
    );
  }

  if (!process.env.LACOS_STAGING_SERVER_URL) {
    errors.push('LACOS_STAGING_SERVER_URL is required.');
  }

  if (!process.env.LACOS_STAGING_CLIENT_KEY) {
    errors.push('LACOS_STAGING_CLIENT_KEY is required for function calls.');
  }

  if (errors.length > 0) {
    const message = [
      'Staging smoke aborted (safe default).',
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
    serverURL: String(process.env.LACOS_STAGING_SERVER_URL).replace(/\/$/, ''),
    clientKey: process.env.LACOS_STAGING_CLIENT_KEY,
    masterKey: process.env.LACOS_STAGING_MASTER_KEY || null,
    productionApplicationId: productionAppId,
  };
}

module.exports = {
  assertStagingEnv,
  maskId,
  PRODUCTION_APPLICATION_ID_DEFAULT,
};
