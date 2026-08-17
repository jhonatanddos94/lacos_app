'use strict';

const assert = require('assert');
const { ErrorCodes } = require('../../shared/errors');
const {
  pointerId,
  buildOwnerOnlyAcl,
  isOwnerOnlyAcl,
  evaluateWorkingHoursBeforeSave,
} = require('../../security/workingHours/workingHoursTenancyPolicy');
const {
  createProfessionalWorkingHoursBeforeSave,
} = require('../../triggers/beforeSave/professionalWorkingHours');

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

async function run() {
  assert.strictEqual(pointerId({ objectId: 'abc' }), 'abc');
  assert.strictEqual(pointerId({ id: 'xyz' }), 'xyz');
  assert.strictEqual(pointerId('plain'), 'plain');
  assert.strictEqual(pointerId(null), null);

  await expectDeny(
    {
      userId: null,
      isMaster: false,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
    },
    ErrorCodes.UNAUTHORIZED,
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
    assert.strictEqual(Object.prototype.hasOwnProperty.call(decision.acl, '*'), false);
  }

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_B,
      submittedProfessionalId: PRO_B,
    },
    ErrorCodes.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_B,
    },
    ErrorCodes.FORBIDDEN,
  );

  await expectDeny(
    {
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_B,
      submittedProfessionalId: PRO_A,
    },
    ErrorCodes.FORBIDDEN,
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
    ErrorCodes.FORBIDDEN,
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
    ErrorCodes.FORBIDDEN,
  );

  {
    const decision = await evaluateWorkingHoursBeforeSave({
      userId: USER_A,
      isCreate: false,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
      originalSalonId: SALON_A,
      originalProfessionalId: PRO_A,
      ...fetchers(),
    });
    assert.strictEqual(decision.allow, true);
  }

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
    assert.strictEqual(decision.code, ErrorCodes.FORBIDDEN);
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
    const clientAcl = { '*': { read: true, write: true }, attacker: { read: true } };
    const decision = await evaluateWorkingHoursBeforeSave({
      userId: USER_A,
      isCreate: true,
      submittedSalonId: SALON_A,
      submittedProfessionalId: PRO_A,
      clientAcl,
      ...fetchers(),
    });
    assert.strictEqual(decision.allow, true);
    assert.deepStrictEqual(decision.acl, buildOwnerOnlyAcl(USER_A));
    assert.ok(!isOwnerOnlyAcl(clientAcl, USER_A));
  }

  {
    let savedAcl = null;
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
    const Parse = {
      ACL: FakeAcl,
      Error: Object.assign(FakeError, {
        INVALID_SESSION_TOKEN: 209,
        OPERATION_FORBIDDEN: 119,
        VALIDATION_ERROR: 142,
        OBJECT_NOT_FOUND: 101,
        SCRIPT_FAILED: 141,
      }),
    };

    const fields = {
      salon: { objectId: SALON_A },
      professional: { objectId: PRO_A },
      ACL: { '*': { read: true, write: true } },
    };
    const object = {
      isNew: () => true,
      get: (key) => fields[key],
      setACL: (acl) => {
        savedAcl = acl;
      },
    };

    const handler = createProfessionalWorkingHoursBeforeSave(Parse, {
      loadConfig: () => ({ environment: 'staging' }),
      fetchSalon: async () => ({ objectId: SALON_A, ownerId: USER_A }),
      fetchProfessional: async () => ({ objectId: PRO_A, salonId: SALON_A }),
    });

    await handler({
      object,
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
    let savedAcl = null;
    const Parse = {
      ACL: class {},
      Error: class ParseError extends Error {
        constructor(code, message) {
          super(message);
          this.code = code;
        }
      },
    };
    const handler = createProfessionalWorkingHoursBeforeSave(Parse, {
      loadConfig: () => ({ environment: 'production' }),
      fetchSalon: async () => {
        throw new Error('must not fetch in production');
      },
      fetchProfessional: async () => {
        throw new Error('must not fetch in production');
      },
    });
    await handler({
      object: {
        isNew: () => true,
        get: () => null,
        setACL: (acl) => {
          savedAcl = acl;
        },
      },
      user: null,
      master: false,
    });
    assert.strictEqual(savedAcl, null);
  }
}

module.exports = { run };
