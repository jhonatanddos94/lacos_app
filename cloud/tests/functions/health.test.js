'use strict';

const assert = require('assert');
const { health } = require('../../functions/health');

async function run() {
  const previousEnv = process.env.LACOS_ENV;
  const previousMode = process.env.LACOS_SECURITY_MODE;

  process.env.LACOS_ENV = 'staging';
  process.env.LACOS_SECURITY_MODE = 'permissive';

  try {
    const result = await health({});

    assert.strictEqual(result.status, 'ok');
    assert.strictEqual(result.service, 'lacos-cloud');
    assert.strictEqual(result.environment, 'staging');
    assert.strictEqual(result.securityMode, 'permissive');
    assert.strictEqual(result.apiContractVersion, 1);
    assert.deepStrictEqual(result.checks, { config: 'ok' });
    assert.ok(typeof result.timestamp === 'string');
  } finally {
    if (previousEnv === undefined) {
      delete process.env.LACOS_ENV;
    } else {
      process.env.LACOS_ENV = previousEnv;
    }

    if (previousMode === undefined) {
      delete process.env.LACOS_SECURITY_MODE;
    } else {
      process.env.LACOS_SECURITY_MODE = previousMode;
    }
  }
}

module.exports = { run };
