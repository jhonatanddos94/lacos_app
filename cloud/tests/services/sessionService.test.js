'use strict';

const assert = require('assert');
const { SessionService } = require('../../services/SessionService');
const { CloudError, ErrorCodes } = require('../../shared/errors');

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
  // sessão emitida via /loginAs
  {
    let calledUrl;
    const httpRequest = async ({ url, headers }) => {
      calledUrl = url;
      assert.ok(headers['X-Parse-Master-Key']);
      assert.strictEqual(headers['X-Parse-Revocable-Session'], '1');
      return {
        status: 200,
        data: {
          objectId: 'u1',
          sessionToken: 'r:session-token-value',
          expiresAt: { iso: '2030-01-01T00:00:00.000Z' },
        },
      };
    };

    const service = new SessionService({
      Parse: {
        applicationId: 'app-id',
        masterKey: 'master-key',
        serverURL: 'https://parse.example/parse',
      },
      httpRequest,
    });

    const session = await service.createSessionForUser({ id: 'u1' });
    assert.strictEqual(session.sessionToken, 'r:session-token-value');
    assert.strictEqual(session.parseUserId, 'u1');
    assert.strictEqual(session.expiresAt, '2030-01-01T00:00:00.000Z');
    assert.ok(calledUrl.includes('/loginAs?userId=u1'));
    assert.ok(!JSON.stringify(session).includes('master-key'));
  }

  // falha de emissão
  {
    const service = new SessionService({
      Parse: {
        applicationId: 'app-id',
        masterKey: 'master-key',
        serverURL: 'https://parse.example/parse',
      },
      httpRequest: async () => ({ status: 500, data: { error: 'nope' } }),
    });

    await expectCloudError(
      service.createSessionForUser({ id: 'u1' }),
      ErrorCodes.TEMPORARY,
    );
  }

  // usuário inválido
  {
    const service = new SessionService({
      Parse: {
        applicationId: 'app-id',
        masterKey: 'master-key',
        serverURL: 'https://parse.example/parse',
      },
      httpRequest: async () => ({ status: 200, data: {} }),
    });

    await expectCloudError(
      service.createSessionForUser(null),
      ErrorCodes.VALIDATION,
    );
  }

  // nenhum dado sensível retornado
  {
    const service = new SessionService({
      Parse: {
        applicationId: 'app-id',
        masterKey: 'super-secret-master',
        serverURL: 'https://parse.example/parse',
      },
      httpRequest: async () => ({
        status: 200,
        data: { objectId: 'u1', sessionToken: 'r:tok' },
      }),
    });

    const session = await service.createSessionForUser({ id: 'u1' });
    const serialized = JSON.stringify(session);
    assert.ok(!serialized.includes('super-secret-master'));
    assert.ok(!serialized.includes('password'));
    assert.deepStrictEqual(Object.keys(session).sort(), [
      'expiresAt',
      'parseUserId',
      'sessionToken',
    ]);
  }
}

module.exports = { run };
