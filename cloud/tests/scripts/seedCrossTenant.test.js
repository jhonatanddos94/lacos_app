'use strict';

const assert = require('assert');
const {
  assertStagingEnv,
  PRODUCTION_APPLICATION_ID_DEFAULT,
} = require('../../scripts/assert-staging-env');
const {
  TENANTS,
  createParseClient,
  resolveSeedUsers,
  upsertWorkingHours,
  seedTenant,
  seedCrossTenants,
} = require('../staging/lib/cross_tenant_seed');

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
      assert.ok(!JSON.stringify(headers).includes('BEGIN'), 'must not leak secrets');
      calls.push({ method, url, body });
      const handler = handlers.shift();
      assert.ok(handler, `unexpected HTTP ${method} ${url}`);
      return handler({ method, url, body });
    },
  };
}

function jsonOk(body, status = 200) {
  return { status, body };
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
        assert.ok(String(error.message).includes('production'));
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
        assert.strictEqual(error.code, 'STAGING_GATE');
        assert.ok(String(error.message).includes('must not equal the production'));
      }
      assert.strictEqual(blocked, true);
    },
  );

  withEnv(
    {
      LACOS_ENV: 'staging',
      LACOS_STAGING_SEED: '1',
      LACOS_STAGING_PARSE_APPLICATION_ID: 'stgAppIdXXXXYYYY',
      LACOS_STAGING_PARSE_SERVER_URL: 'https://parseapi.back4app.com',
      LACOS_STAGING_PARSE_MASTER_KEY: 'master-test',
    },
    () => {
      const env = assertStagingEnv({
        requireClientKey: false,
        requireMasterKey: true,
      });
      assert.strictEqual(env.applicationId, 'stgAppIdXXXXYYYY');
      assert.strictEqual(env.masterKey, 'master-test');
    },
  );

  const missingUserHttp = createMemoryHttp([
    () => jsonOk({ results: [] }),
    () => jsonOk({ results: [{ objectId: 'user-b' }] }),
  ]);
  const missingClient = createParseClient({
    env: {
      applicationId: 'stg',
      serverURL: 'https://example.test',
      masterKey: 'mk',
    },
    http: missingUserHttp.http,
  });
  let missing = false;
  try {
    await resolveSeedUsers(missingClient);
  } catch (error) {
    missing = true;
    assert.strictEqual(error.code, 'SEED_USER_MISSING');
    assert.ok(String(error.message).includes('teste_a'));
  }
  assert.strictEqual(missing, true);

  const collisionHttp = createMemoryHttp([
    () => jsonOk({ results: [{ objectId: 'same-user' }] }),
    () => jsonOk({ results: [{ objectId: 'same-user' }] }),
  ]);
  const collisionClient = createParseClient({
    env: {
      applicationId: 'stg',
      serverURL: 'https://example.test',
      masterKey: 'mk',
    },
    http: collisionHttp.http,
  });
  let collision = false;
  try {
    await resolveSeedUsers(collisionClient);
  } catch (error) {
    collision = true;
    assert.strictEqual(error.code, 'SEED_USER_COLLISION');
  }
  assert.strictEqual(collision, true);

  const weekdayHandlers = [];
  for (let weekday = 1; weekday <= 7; weekday += 1) {
    weekdayHandlers.push(() => jsonOk({ results: [] }));
    weekdayHandlers.push(() =>
      jsonOk({ objectId: `hours-${weekday}` }, 201),
    );
  }
  const createHours = createMemoryHttp(weekdayHandlers);
  const createdHours = await upsertWorkingHours(
    createParseClient({
      env: {
        applicationId: 'stg',
        serverURL: 'https://example.test',
        masterKey: 'mk',
      },
      http: createHours.http,
    }),
    { salonId: 'salon-a', professionalId: 'pro-a' },
  );
  assert.strictEqual(createdHours.count, 7);
  assert.strictEqual(createdHours.createdCount, 7);
  assert.strictEqual(createHours.calls.filter((call) => call.method === 'POST').length, 7);

  const upsertHandlers = [];
  for (let weekday = 1; weekday <= 7; weekday += 1) {
    upsertHandlers.push(() =>
      jsonOk({ results: [{ objectId: `hours-${weekday}` }] }),
    );
    upsertHandlers.push(() => jsonOk({ updatedAt: '2030-01-01T00:00:00.000Z' }));
  }
  const updateHours = createMemoryHttp(upsertHandlers);
  const updatedHours = await upsertWorkingHours(
    createParseClient({
      env: {
        applicationId: 'stg',
        serverURL: 'https://example.test',
        masterKey: 'mk',
      },
      http: updateHours.http,
    }),
    { salonId: 'salon-a', professionalId: 'pro-a' },
  );
  assert.strictEqual(updatedHours.count, 7);
  assert.strictEqual(updatedHours.createdCount, 0);
  assert.strictEqual(updateHours.calls.filter((call) => call.method === 'POST').length, 0);
  assert.strictEqual(updateHours.calls.filter((call) => call.method === 'PUT').length, 7);

  const firstSeedHttp = createMemoryHttp([
    () => jsonOk({ results: [] }),
    () => jsonOk({ objectId: 'salon-a' }, 201),
    () => jsonOk({ results: [] }),
    () => jsonOk({ objectId: 'pro-a' }, 201),
    () => jsonOk({ results: [] }),
    () => jsonOk({ objectId: 'client-a' }, 201),
    () => jsonOk({ results: [] }),
    () => jsonOk({ objectId: 'service-a' }, 201),
    () => jsonOk({ results: [] }),
    () => jsonOk({ objectId: 'appt-a' }, 201),
    ...Array.from({ length: 7 }, (_, index) => [
      () => jsonOk({ results: [] }),
      () => jsonOk({ objectId: `hours-a-${index + 1}` }, 201),
    ]).flat(),
  ]);
  const firstSeed = await seedTenant(
    createParseClient({
      env: {
        applicationId: 'stg',
        serverURL: 'https://example.test',
        masterKey: 'mk',
      },
      http: firstSeedHttp.http,
    }),
    TENANTS.A,
    'user-a',
  );
  assert.strictEqual(firstSeed.created.salon, true);
  assert.strictEqual(firstSeed.workingHoursCount, 7);

  const secondSeedHttp = createMemoryHttp([
    () => jsonOk({ results: [{ objectId: 'salon-a' }] }),
    () => jsonOk({ results: [{ objectId: 'pro-a' }] }),
    () => jsonOk({ results: [{ objectId: 'client-a' }] }),
    () => jsonOk({ results: [{ objectId: 'service-a' }] }),
    () => jsonOk({ results: [{ objectId: 'appt-a' }] }),
    ...Array.from({ length: 7 }, (_, index) => [
      () => jsonOk({ results: [{ objectId: `hours-a-${index + 1}` }] }),
      () => jsonOk({ updatedAt: '2030-01-01T00:00:00.000Z' }),
    ]).flat(),
  ]);
  const secondSeed = await seedTenant(
    createParseClient({
      env: {
        applicationId: 'stg',
        serverURL: 'https://example.test',
        masterKey: 'mk',
      },
      http: secondSeedHttp.http,
    }),
    TENANTS.A,
    'user-a',
  );
  assert.strictEqual(secondSeed.salonId, 'salon-a');
  assert.strictEqual(secondSeed.created.salon, false);
  assert.strictEqual(secondSeed.created.appointment, false);
  assert.strictEqual(secondSeed.workingHoursCount, 7);
  assert.strictEqual(secondSeed.created.workingHours, 0);
  assert.strictEqual(
    secondSeedHttp.calls.filter((call) => call.method === 'POST').length,
    0,
  );

  let incomplete = false;
  try {
    await seedCrossTenants({
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
}

module.exports = { run };
