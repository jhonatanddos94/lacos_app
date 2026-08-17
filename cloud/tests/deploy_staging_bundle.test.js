'use strict';

const assert = require('assert');
const {
  ERROR_CODES,
  isStagingEnv,
  pointerId,
  buildOwnerOnlyAcl,
  evaluateWorkingHoursBeforeSave,
  createWorkingHoursBeforeSave,
  registerCloudCode,
} = require('../deploy_staging_bundle/main');

const SALON_A = 'salon-a';
const SALON_B = 'salon-b';
const PRO_A = 'pro-a';
const PRO_B = 'pro-b';
const USER_A = 'user-a';
const USER_B = 'user-b';

function salons() {
  return {
    [SALON_A]: { objectId: SALON_A, ownerId: USER_A },
    [SALON_B]: { objectId: SALON_B, ownerId: USER_B },
  };
}

function professionals() {
  return {
    [PRO_A]: { objectId: PRO_A, salonId: SALON_A },
    [PRO_B]: { objectId: PRO_B, salonId: SALON_B },
  };
}

function fetchers() {
  const salonMap = salons();
  const proMap = professionals();
  return {
    fetchSalon: async (id) => salonMap[id] || null,
    fetchProfessional: async (id) => proMap[id] || null,
  };
}

async function expectDeny(input, code) {
  const decision = await evaluateWorkingHoursBeforeSave({
    ...fetchers(),
    ...input,
  });
  assert.strictEqual(decision.allow, false);
  assert.strictEqual(decision.code, code);
  assert.strictEqual(decision.acl, null);
}

function fakeParse() {
  class FakeAcl {
    constructor() {
      this.publicRead = true;
      this.publicWrite = true;
      this.users = {};
    }
    setPublicReadAccess(value) {
      this.publicRead = value;
    }
    setPublicWriteAccess(value) {
      this.publicWrite = value;
    }
    setReadAccess(id, value) {
      this.users[id] = Object.assign({}, this.users[id], { read: value });
    }
    setWriteAccess(id, value) {
      this.users[id] = Object.assign({}, this.users[id], { write: value });
    }
  }
  class FakeError extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  }
  FakeError.INVALID_SESSION_TOKEN = 209;
  FakeError.OPERATION_FORBIDDEN = 119;
  FakeError.VALIDATION_ERROR = 142;
  FakeError.OBJECT_NOT_FOUND = 101;
  FakeError.SCRIPT_FAILED = 141;

  const defined = { functions: {}, beforeSave: {} };
  return {
    defined,
    Parse: {
      ACL: FakeAcl,
      Error: FakeError,
      Cloud: {
        define(name, handler) {
          defined.functions[name] = handler;
        },
        beforeSave(className, handler) {
          defined.beforeSave[className] = handler;
        },
      },
    },
  };
}

async function run() {
  assert.strictEqual(isStagingEnv({ LACOS_ENV: 'staging' }), true);
  assert.strictEqual(isStagingEnv({ LACOS_ENV: 'production' }), false);
  assert.strictEqual(isStagingEnv({}), false);
  assert.strictEqual(pointerId({ objectId: 'abc' }), 'abc');

  await expectDeny(
    {
      userId: null,
      isMaster: false,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
    },
    ERROR_CODES.UNAUTHORIZED,
  );

  {
    const decision = await evaluateWorkingHoursBeforeSave({
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
      ...fetchers(),
    });
    assert.strictEqual(decision.allow, true);
    assert.strictEqual(decision.ownerId, USER_A);
    assert.deepStrictEqual(decision.acl, buildOwnerOnlyAcl(USER_A));
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(decision.acl, '*'),
      false,
    );
  }

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_B,
      submittedProfessionalId: PRO_B,
    },
    ERROR_CODES.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_B,
    },
    ERROR_CODES.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_B,
      submittedProfessionalId: PRO_A,
    },
    ERROR_CODES.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: false,
      submittedSalonId: SALON_B,
      submittedProfessionalId: PRO_A,
      originalSalonId: SALON_A,
      originalProfessionalId: PRO_A,
    },
    ERROR_CODES.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: false,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_B,
      originalSalonId: SALON_A,
      originalProfessionalId: PRO_A,
    },
    ERROR_CODES.FORBIDDEN,
  );

  {
    const ownerless = {
      fetchSalon: async () => ({ objectId: SALON_A, ownerId: null }),
      fetchProfessional: async () => ({ objectId: PRO_A, salonId: SALON_A }),
    };
    const decision = await evaluateWorkingHoursBeforeSave({
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
      ...ownerless,
    });
    assert.strictEqual(decision.allow, false);
    assert.strictEqual(decision.code, ERROR_CODES.FORBIDDEN);
  }

  {
    const decision = await evaluateWorkingHoursBeforeSave({
      userId: null,
      isMaster: true,
      isCreate: false,
      originalSalonId: SALON_A,
      originalProfessionalId: PRO_A,
      ...fetchers(),
    });
    assert.strictEqual(decision.allow, true);
    assert.strictEqual(decision.ownerId, USER_A);
  }

  {
    const { Parse } = fakeParse();
    let savedAcl = null;
    const fields = {
      salon: { objectId: SALON_A },
      professional: { objectId: PRO_A },
      ACL: { '*': { read: true, write: true } },
    };
    const handler = createWorkingHoursBeforeSave(Parse, fetchers());
    await handler({
      object: {
        isNew: () => true,
        get: (key) => fields[key],
        setACL: (acl) => {
          savedAcl = acl;
        },
      },
      original: null,
      user: { id: USER_A },
      master: false,
    });
    assert.ok(savedAcl);
    assert.strictEqual(savedAcl.publicRead, false);
    assert.strictEqual(savedAcl.publicWrite, false);
    assert.deepStrictEqual(savedAcl.users[USER_A], { read: true, write: true });
  }

  {
    const { Parse, defined } = fakeParse();
    const result = registerCloudCode(Parse, { LACOS_ENV: 'production' }, fetchers());
    assert.strictEqual(result.workingHoursBeforeSave, true);
    assert.ok(defined.functions.ping);
    assert.ok(defined.functions.health);
    assert.ok(defined.beforeSave.ProfessionalWorkingHours);
    const health = await defined.functions.health();
    assert.strictEqual(health.status, 'ok');
    assert.strictEqual(health.environment, 'staging-bundle');
    assert.strictEqual(health.workingHoursBeforeSave, true);
    assert.ok(!JSON.stringify(health).includes('Key'));
  }

  {
    const { Parse, defined } = fakeParse();
    const result = registerCloudCode(Parse, { LACOS_ENV: 'staging' }, fetchers());
    assert.strictEqual(result.workingHoursBeforeSave, true);
    assert.ok(defined.beforeSave.ProfessionalWorkingHours);
    const health = await defined.functions.health();
    assert.strictEqual(health.status, 'ok');
    assert.strictEqual(health.environment, 'staging-bundle');
    assert.strictEqual(health.workingHoursBeforeSave, true);
    const ping = await defined.functions.ping();
    assert.strictEqual(ping.status, 'ok');
  }
}

module.exports = { run };
