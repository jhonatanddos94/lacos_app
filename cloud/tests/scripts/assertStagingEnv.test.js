'use strict';

const assert = require('assert');
const {
  assertStagingEnv,
  PRODUCTION_APPLICATION_ID_DEFAULT,
} = require('../../scripts/assert-staging-env');

async function run() {
  const previous = {
    smoke: process.env.LACOS_STAGING_SMOKE,
    appId: process.env.LACOS_STAGING_APPLICATION_ID,
    server: process.env.LACOS_STAGING_SERVER_URL,
    client: process.env.LACOS_STAGING_CLIENT_KEY,
  };

  try {
    delete process.env.LACOS_STAGING_SMOKE;
    delete process.env.LACOS_STAGING_APPLICATION_ID;
    delete process.env.LACOS_STAGING_SERVER_URL;
    delete process.env.LACOS_STAGING_CLIENT_KEY;

    let blocked = false;
    try {
      assertStagingEnv();
    } catch (error) {
      blocked = true;
      assert.strictEqual(error.code, 'STAGING_GATE');
      assert.ok(String(error.message).includes('LACOS_STAGING_SMOKE=1'));
    }
    assert.strictEqual(blocked, true);

    process.env.LACOS_STAGING_SMOKE = '1';
    process.env.LACOS_STAGING_APPLICATION_ID = PRODUCTION_APPLICATION_ID_DEFAULT;
    process.env.LACOS_STAGING_SERVER_URL = 'https://parseapi.back4app.com';
    process.env.LACOS_STAGING_CLIENT_KEY = 'dummy';

    blocked = false;
    try {
      assertStagingEnv();
    } catch (error) {
      blocked = true;
      assert.ok(
        String(error.message).includes('must not equal the production'),
      );
    }
    assert.strictEqual(blocked, true);
  } finally {
    restore('LACOS_STAGING_SMOKE', previous.smoke);
    restore('LACOS_STAGING_APPLICATION_ID', previous.appId);
    restore('LACOS_STAGING_SERVER_URL', previous.server);
    restore('LACOS_STAGING_CLIENT_KEY', previous.client);
  }
}

function restore(name, value) {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
}

module.exports = { run };
