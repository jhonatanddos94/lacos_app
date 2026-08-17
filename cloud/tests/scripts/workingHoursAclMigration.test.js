'use strict';

const assert = require('assert');
const {
  assertStagingEnv,
  PRODUCTION_APPLICATION_ID_DEFAULT,
} = require('../../scripts/assert-staging-env');
const {
  migrateWorkingHoursAcl,
  TARGET_CLP,
} = require('../staging/lib/working_hours_acl_migration');
const {
  buildOwnerOnlyAcl,
  isOwnerOnlyAcl,
} = require('../../security/workingHours/workingHoursTenancyPolicy');

function restore(name, value) {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
}

function withEnv(overrides, fn) {
  const keys = Object.keys(overrides);
  const previous = {};
  keys.forEach((key) => {
    previous[key] = process.env[key];
    if (overrides[key] === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = overrides[key];
    }
  });
  try {
    return fn();
  } finally {
    keys.forEach((key) => restore(key, previous[key]));
  }
}

function createMemoryHttp(handlers) {
  const calls = [];
  return {
    calls,
    http: async ({ method, url, headers, body }) => {
      calls.push({ method, url, headers, body });
      const handler = handlers.shift();
      assert.ok(handler, `unexpected HTTP ${method} ${url}`);
      return handler({ method, url, headers, body });
    },
  };
}

async function run() {
  withEnv(
    {
      LACOS_ENV: 'production',
      LACOS_STAGING_SEED: '1',
      LACOS_STAGING_APPLICATION_ID: 'stgAppIdXXXXYYYY',
      LACOS_STAGING_SERVER_URL: 'https://parseapi.back4app.com',
      LACOS_STAGING_MASTER_KEY: 'master-test',
    },
    () => {
      let blocked = false;
      try {
        assertStagingEnv({ requireClientKey: false, requireMasterKey: true });
      } catch (error) {
        blocked = true;
        assert.strictEqual(error.code, 'STAGING_GATE');
      }
      assert.strictEqual(blocked, true);
    },
  );

  withEnv(
    {
      LACOS_ENV: 'staging',
      LACOS_STAGING_SEED: '1',
      LACOS_STAGING_APPLICATION_ID: PRODUCTION_APPLICATION_ID_DEFAULT,
      LACOS_STAGING_SERVER_URL: 'https://parseapi.back4app.com',
      LACOS_STAGING_MASTER_KEY: 'master-test',
    },
    () => {
      let blocked = false;
      try {
        assertStagingEnv({ requireClientKey: false, requireMasterKey: true });
      } catch (error) {
        blocked = true;
        assert.ok(String(error.message).includes('must not equal the production'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  let incomplete = false;
  try {
    await migrateWorkingHoursAcl({
      env: { applicationId: 'stg', serverURL: 'https://example.test' },
      http: async () => {
        throw new Error('must not call network');
      },
    });
  } catch (error) {
    incomplete = true;
    assert.strictEqual(error.code, 'STAGING_GATE');
  }
  assert.strictEqual(incomplete, true);

  const ownerAcl = buildOwnerOnlyAcl('user-a');
  assert.strictEqual(isOwnerOnlyAcl(ownerAcl, 'user-a'), true);
  assert.strictEqual(
    isOwnerOnlyAcl({ '*': { read: true }, 'user-a': { read: true, write: true } }, 'user-a'),
    false,
  );

  const firstPass = createMemoryHttp([
    () => ({
      status: 200,
      body: {
        results: [
          {
            objectId: 'hours-1',
            salon: { objectId: 'salon-a' },
            ACL: { '*': { read: true, write: true } },
          },
          {
            objectId: 'hours-2',
            salon: { objectId: 'salon-a' },
            ACL: ownerAcl,
          },
        ],
      },
    }),
    () => ({
      status: 200,
      body: { objectId: 'salon-a', owner: { objectId: 'user-a' } },
    }),
    () => ({ status: 200, body: { updatedAt: '2030-01-01T00:00:00.000Z' } }),
    () => ({
      status: 200,
      body: { objectId: 'salon-a', owner: { objectId: 'user-a' } },
    }),
    () => ({
      status: 200,
      body: {
        classLevelPermissions: { find: { '*': true }, get: { '*': true } },
      },
    }),
    () => ({ status: 200, body: { updatedAt: '2030-01-01T00:00:00.000Z' } }),
    () => ({
      status: 200,
      body: { classLevelPermissions: TARGET_CLP },
    }),
  ]);

  const migrated = await migrateWorkingHoursAcl({
    env: {
      applicationId: 'stg',
      serverURL: 'https://example.test',
      masterKey: 'mk',
    },
    http: firstPass.http,
  });
  assert.strictEqual(migrated.total, 2);
  assert.strictEqual(migrated.updated, 1);
  assert.strictEqual(migrated.skipped, 1);
  assert.strictEqual(migrated.failed, 0);
  assert.strictEqual(
    firstPass.calls.filter((call) => call.method === 'PUT' && call.url.includes('/classes/')).length,
    1,
  );
  assert.deepStrictEqual(firstPass.calls[2].body.ACL, ownerAcl);
  assert.ok(firstPass.calls.some((call) => call.url.endsWith('/schemas/ProfessionalWorkingHours')));

  const ownerless = createMemoryHttp([
    () => ({
      status: 200,
      body: {
        results: [{ objectId: 'hours-x', salon: { objectId: 'salon-x' } }],
      },
    }),
    () => ({ status: 200, body: { objectId: 'salon-x' } }),
  ]);
  const closed = await migrateWorkingHoursAcl({
    env: {
      applicationId: 'stg',
      serverURL: 'https://example.test',
      masterKey: 'mk',
    },
    http: ownerless.http,
    applyClp: false,
  });
  assert.strictEqual(closed.failed, 1);
  assert.strictEqual(closed.updated, 0);
  assert.ok(closed.failures[0].reason.includes('owner'));

  const missingSalon = createMemoryHttp([
    () => ({
      status: 200,
      body: {
        results: [{ objectId: 'hours-y', salon: { objectId: 'salon-gone' } }],
      },
    }),
    () => ({ status: 404, body: { code: 101, error: 'not found' } }),
  ]);
  const orphans = await migrateWorkingHoursAcl({
    env: {
      applicationId: 'stg',
      serverURL: 'https://example.test',
      masterKey: 'mk',
    },
    http: missingSalon.http,
    applyClp: false,
  });
  assert.strictEqual(orphans.orphaned, 1);
  assert.strictEqual(orphans.failed, 0);
}

module.exports = { run };
