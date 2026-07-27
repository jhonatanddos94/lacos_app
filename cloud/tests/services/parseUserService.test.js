'use strict';

const assert = require('assert');
const { ParseUserService } = require('../../services/ParseUserService');
const { CloudError, ErrorCodes } = require('../../shared/errors');

function createUserStub({ id, username, firebaseUid, email }) {
  const data = {
    username,
    firebaseUid,
    email,
  };

  return {
    id,
    get(key) {
      return data[key];
    },
    set(key, value) {
      data[key] = value;
    },
    async save() {
      return this;
    },
    async signUp() {
      return this;
    },
  };
}

function createParseFake({ byFirebaseUid = null, byUsername = null } = {}) {
  const users = [];

  class FakeUser {
    constructor() {
      this.id = undefined;
      this._data = {};
    }

    get(key) {
      return this._data[key];
    }

    set(key, value) {
      this._data[key] = value;
    }

    async signUp() {
      if (users.some((u) => u.get('username') === this._data.username)) {
        const error = new Error('Account already exists for this username.');
        error.code = 202;
        throw error;
      }
      this.id = `new-${users.length + 1}`;
      users.push(this);
      return this;
    }

    async save() {
      return this;
    }
  }

  return {
    User: FakeUser,
    Query: class {
      constructor() {
        this._field = null;
        this._value = null;
      }

      equalTo(field, value) {
        this._field = field;
        this._value = value;
        return this;
      }

      async first() {
        if (this._field === 'firebaseUid') {
          return byFirebaseUid;
        }
        if (this._field === 'username') {
          return byUsername;
        }
        return null;
      }
    },
    _users: users,
  };
}

async function expectCloudError(promise, code) {
  try {
    await promise;
    assert.fail(`expected ${code}`);
  } catch (error) {
    assert.ok(error instanceof CloudError);
    assert.strictEqual(error.code, code);
  }
}

async function run() {
  const identity = {
    uid: 'firebase-uid-001',
    email: 'user@example.com',
  };

  // existente por firebaseUid
  {
    const existing = createUserStub({
      id: 'u1',
      username: 'firebase-uid-001',
      firebaseUid: 'firebase-uid-001',
      email: 'user@example.com',
    });
    const Parse = createParseFake({ byFirebaseUid: existing });
    const service = new ParseUserService({ Parse });
    const result = await service.findOrCreateFromFirebaseIdentity(identity);
    assert.strictEqual(result.isNewUser, false);
    assert.strictEqual(result.user.id, 'u1');
  }

  // legado por username (migra firebaseUid)
  {
    let saved = false;
    const legacy = createUserStub({
      id: 'u-legacy',
      username: 'firebase-uid-001',
      firebaseUid: undefined,
      email: 'old@example.com',
    });
    legacy.save = async function save() {
      saved = true;
      return this;
    };

    const Parse = createParseFake({ byUsername: legacy });
    const service = new ParseUserService({ Parse });
    const result = await service.findOrCreateFromFirebaseIdentity(identity);
    assert.strictEqual(result.isNewUser, false);
    assert.strictEqual(legacy.get('firebaseUid'), 'firebase-uid-001');
    assert.strictEqual(saved, true);
  }

  // usuário novo
  {
    const Parse = createParseFake();
    const service = new ParseUserService({
      Parse,
      generatePassword: () => 'random-password-not-logged',
    });
    const result = await service.findOrCreateFromFirebaseIdentity(identity);
    assert.strictEqual(result.isNewUser, true);
    assert.ok(result.user.id);
    assert.strictEqual(result.user.get('firebaseUid'), identity.uid);
    assert.strictEqual(result.user.get('username'), identity.uid);
    assert.ok(result.user.get('password'));
  }

  // conflito de vínculo
  {
    const a = createUserStub({
      id: 'a',
      username: 'other',
      firebaseUid: 'firebase-uid-001',
    });
    const b = createUserStub({
      id: 'b',
      username: 'firebase-uid-001',
      firebaseUid: undefined,
    });
    const Parse = createParseFake({ byFirebaseUid: a, byUsername: b });
    const service = new ParseUserService({ Parse });
    await expectCloudError(
      service.findOrCreateFromFirebaseIdentity(identity),
      ErrorCodes.CONFLICT,
    );
  }

  // concorrência (signUp 202 → reconsulta)
  {
    let queryCount = 0;
    const createdLater = createUserStub({
      id: 'u-race',
      username: 'firebase-uid-001',
      firebaseUid: 'firebase-uid-001',
      email: 'user@example.com',
    });

    class RacingUser {
      constructor() {
        this.id = undefined;
        this._data = {};
      }

      get(key) {
        return this._data[key];
      }

      set(key, value) {
        this._data[key] = value;
      }

      async signUp() {
        const error = new Error('already taken');
        error.code = 202;
        throw error;
      }
    }

    const Parse = {
      User: RacingUser,
      Query: class {
        equalTo(field, value) {
          this._field = field;
          this._value = value;
          return this;
        }

        async first() {
          queryCount += 1;
          // First pair of lookups: miss. After race: hit by username.
          if (queryCount <= 2) {
            return null;
          }
          if (this._field === 'username' || this._field === 'firebaseUid') {
            return createdLater;
          }
          return null;
        }
      },
    };

    const service = new ParseUserService({ Parse });
    const result = await service.findOrCreateFromFirebaseIdentity(identity);
    assert.strictEqual(result.isNewUser, false);
    assert.strictEqual(result.user.id, 'u-race');
  }

  // falha de persistência
  {
    const Parse = createParseFake();
    Parse.User = class {
      constructor() {
        this._data = {};
      }

      get(key) {
        return this._data[key];
      }

      set(key, value) {
        this._data[key] = value;
      }

      async signUp() {
        throw new Error('db down');
      }
    };

    const service = new ParseUserService({ Parse });
    await expectCloudError(
      service.findOrCreateFromFirebaseIdentity(identity),
      ErrorCodes.TEMPORARY,
    );
  }
}

module.exports = { run };
