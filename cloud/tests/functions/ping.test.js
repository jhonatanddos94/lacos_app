'use strict';

const assert = require('assert');
const { ping } = require('../../functions/ping');

async function run() {
  const result = await ping({});

  assert.strictEqual(result.status, 'ok');
  assert.strictEqual(result.service, 'lacos-cloud');
  assert.strictEqual(result.apiContractVersion, 1);
  assert.ok(typeof result.timestamp === 'string');
  assert.ok(Number.isFinite(Date.parse(result.timestamp)));
}

module.exports = { run };
