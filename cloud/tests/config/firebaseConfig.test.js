'use strict';

const assert = require('assert');
const {
  loadFirebaseServiceAccount,
  parseServiceAccountJson,
} = require('../../config/firebase');
const { CloudError, ErrorCodes } = require('../../shared/errors');

async function run() {
  const previousJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const previousB64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

  delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  delete process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

  try {
    try {
      loadFirebaseServiceAccount();
      assert.fail('expected configuration error');
    } catch (error) {
      assert.ok(error instanceof CloudError);
      assert.strictEqual(error.code, ErrorCodes.CONFIGURATION_ERROR);
    }

    const account = {
      project_id: 'p',
      client_email: 'a@b.c',
      private_key: 'k',
    };
    const parsed = parseServiceAccountJson(JSON.stringify(account), 'test');
    assert.strictEqual(parsed.project_id, 'p');

    process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 = Buffer.from(
      JSON.stringify(account),
    ).toString('base64');
    const loaded = loadFirebaseServiceAccount();
    assert.strictEqual(loaded.client_email, 'a@b.c');
  } finally {
    if (previousJson === undefined) {
      delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    } else {
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON = previousJson;
    }
    if (previousB64 === undefined) {
      delete process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    } else {
      process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 = previousB64;
    }
  }
}

module.exports = { run };
