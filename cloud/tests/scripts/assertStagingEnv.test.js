'use strict';

const assert = require('assert');
const {
  assertStagingEnv,
  PRODUCTION_APPLICATION_ID_DEFAULT,
} = require('../../scripts/assert-staging-env');

async function run() {
  const previous = {
    smoke: process.env.LACOS_STAGING_SMOKE,
    seed: process.env.LACOS_STAGING_SEED,
    appId: process.env.LACOS_STAGING_APPLICATION_ID,
    parseAppId: process.env.LACOS_STAGING_PARSE_APPLICATION_ID,
    server: process.env.LACOS_STAGING_SERVER_URL,
    parseServer: process.env.LACOS_STAGING_PARSE_SERVER_URL,
    client: process.env.LACOS_STAGING_CLIENT_KEY,
    master: process.env.LACOS_STAGING_MASTER_KEY,
    parseMaster: process.env.LACOS_STAGING_PARSE_MASTER_KEY,
    authMode: process.env.LACOS_STAGING_AUTH_MODE,
  };

  try {
    delete process.env.LACOS_STAGING_SMOKE;
    delete process.env.LACOS_STAGING_SEED;
    delete process.env.LACOS_STAGING_AUTH_MODE;
    delete process.env.LACOS_STAGING_APPLICATION_ID;
    delete process.env.LACOS_STAGING_PARSE_APPLICATION_ID;
    delete process.env.LACOS_STAGING_SERVER_URL;
    delete process.env.LACOS_STAGING_PARSE_SERVER_URL;
    delete process.env.LACOS_STAGING_CLIENT_KEY;
    delete process.env.LACOS_STAGING_MASTER_KEY;
    delete process.env.LACOS_STAGING_PARSE_MASTER_KEY;

    let blocked = false;
    try {
      assertStagingEnv();
    } catch (error) {
      blocked = true;
      assert.strictEqual(error.code, 'STAGING_GATE');
      assert.ok(String(error.message).includes('LACOS_STAGING_SMOKE=1'));
      assert.ok(String(error.message).includes('LACOS_STAGING_AUTH_MODE'));
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
    restore('LACOS_STAGING_SEED', previous.seed);
    restore('LACOS_STAGING_APPLICATION_ID', previous.appId);
    restore('LACOS_STAGING_PARSE_APPLICATION_ID', previous.parseAppId);
    restore('LACOS_STAGING_SERVER_URL', previous.server);
    restore('LACOS_STAGING_PARSE_SERVER_URL', previous.parseServer);
    restore('LACOS_STAGING_CLIENT_KEY', previous.client);
    restore('LACOS_STAGING_MASTER_KEY', previous.master);
    restore('LACOS_STAGING_PARSE_MASTER_KEY', previous.parseMaster);
    restore('LACOS_STAGING_AUTH_MODE', previous.authMode);
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
