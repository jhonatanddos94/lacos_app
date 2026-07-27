'use strict';

const { readEnv } = require('./environment');
const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Loads Firebase Admin credentials from environment variables.
 *
 * Strategy (Back4App-friendly):
 * 1. FIREBASE_SERVICE_ACCOUNT_JSON — full service account JSON string
 * 2. FIREBASE_SERVICE_ACCOUNT_BASE64 — Base64 encoding of that JSON
 *
 * Prefer JSON string when the host preserves it; Base64 avoids escaping issues
 * with private_key newlines in some dashboards.
 *
 * Never commit real credentials. Application Default Credentials are not
 * assumed on Back4App Cloud Code.
 */
function loadFirebaseServiceAccount() {
  const asJson = readEnv('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (asJson) {
    return parseServiceAccountJson(asJson, 'FIREBASE_SERVICE_ACCOUNT_JSON');
  }

  const asBase64 = readEnv('FIREBASE_SERVICE_ACCOUNT_BASE64');
  if (asBase64) {
    let decoded;
    try {
      decoded = Buffer.from(asBase64, 'base64').toString('utf8');
    } catch (_error) {
      throw new CloudError(
        ErrorCodes.CONFIGURATION_ERROR,
        'Firebase Admin credentials are invalid.',
        { statusCode: 500 },
      );
    }
    return parseServiceAccountJson(decoded, 'FIREBASE_SERVICE_ACCOUNT_BASE64');
  }

  throw new CloudError(
    ErrorCodes.CONFIGURATION_ERROR,
    'Firebase Admin credentials are not configured.',
    { statusCode: 500 },
  );
}

function parseServiceAccountJson(raw, sourceName) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_error) {
    throw new CloudError(
      ErrorCodes.CONFIGURATION_ERROR,
      'Firebase Admin credentials are invalid.',
      { statusCode: 500, details: { source: sourceName } },
    );
  }

  if (
    !parsed ||
    typeof parsed !== 'object' ||
    typeof parsed.project_id !== 'string' ||
    typeof parsed.client_email !== 'string' ||
    typeof parsed.private_key !== 'string'
  ) {
    throw new CloudError(
      ErrorCodes.CONFIGURATION_ERROR,
      'Firebase Admin credentials are incomplete.',
      { statusCode: 500 },
    );
  }

  return parsed;
}

function resolveFirebaseProjectId(serviceAccount) {
  return readEnv('FIREBASE_PROJECT_ID', serviceAccount.project_id);
}

module.exports = {
  loadFirebaseServiceAccount,
  resolveFirebaseProjectId,
  parseServiceAccountJson,
};
