'use strict';

const assert = require('assert');
const {
  pickCanonicalHours,
  policyBlocked,
  pointerObjectId,
  hoursMatchesTenant,
} = require('../staging/working_hours_secure.staging');

async function run() {
  const manifest = ['seed-1', 'seed-2'];
  const rows = [
    { objectId: 'residue-x', weekday: 1 },
    { objectId: 'seed-2', weekday: 2 },
    { objectId: 'seed-1', weekday: 1 },
    { objectId: 'residue-y', weekday: 1 },
  ];
  const picked = pickCanonicalHours(rows, manifest);
  assert.strictEqual(picked.objectId, 'seed-1');
  assert.strictEqual(picked.weekday, 1);

  assert.strictEqual(pickCanonicalHours(rows, []), null);
  assert.strictEqual(pickCanonicalHours(rows, null), null);

  const firstSeedWeekday2Only = pickCanonicalHours(
    [
      { objectId: 'residue-x', weekday: 1 },
      { objectId: 'seed-2', weekday: 2 },
    ],
    ['seed-2'],
  );
  assert.strictEqual(firstSeedWeekday2Only.objectId, 'seed-2');

  assert.strictEqual(policyBlocked({ status: 400, code: 119 }), true);
  assert.strictEqual(policyBlocked({ status: 200, code: 119 }), true);
  assert.strictEqual(policyBlocked({ status: 404, code: 101 }), true);
  assert.strictEqual(policyBlocked({ status: 200, code: undefined }), false);
  assert.strictEqual(pointerObjectId({ objectId: 'abc' }), 'abc');

  const tenantA = {
    salonId: 'salon-a',
    professionalId: 'pro-a',
  };
  const crossed = pickCanonicalHours(
    [
      {
        objectId: 'seed-1',
        weekday: 1,
        salon: { objectId: 'salon-b' },
        professional: { objectId: 'pro-b' },
      },
      {
        objectId: 'seed-2',
        weekday: 1,
        salon: { objectId: 'salon-a' },
        professional: { objectId: 'pro-a' },
      },
    ],
    ['seed-1', 'seed-2'],
    tenantA,
  );
  assert.strictEqual(crossed.objectId, 'seed-2');
  assert.strictEqual(
    hoursMatchesTenant(
      { salon: { objectId: 'salon-b' }, professional: { objectId: 'pro-b' } },
      tenantA,
    ),
    false,
  );
}

module.exports = { run };
