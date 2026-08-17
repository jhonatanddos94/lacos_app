'use strict';

/**
 * T1.S1 — REST proof for ProfessionalWorkingHours hardening (STAGING ONLY).
 * Does not change historical T1.S0 baseline criteria.
 *
 * Never logs passwords, session tokens, or keys.
 */

const fs = require('fs');
const path = require('path');

const { assertStagingEnv, maskId } = require('../../scripts/assert-staging-env');
const { pointer } = require('./lib/cross_tenant_seed');
const { authenticateBaselineUsers } = require('./lib/baseline_auth');

const MANIFEST_PATH = path.join(__dirname, '.seed-manifest.json');

function loadSeedManifest() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
}

function verdict(ok) {
  if (ok === true) {
    return 'SIM';
  }
  if (ok === false) {
    return 'NÃO';
  }
  return 'NÃO TESTADO';
}

async function parseRequest(env, { method, path: restPath, sessionToken, body }) {
  const headers = {
    'X-Parse-Application-Id': env.applicationId,
    'X-Parse-Client-Key': env.clientKey,
    'Content-Type': 'application/json',
  };
  if (sessionToken) {
    headers['X-Parse-Session-Token'] = sessionToken;
  }

  const response = await fetch(`${env.serverURL}${restPath}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  let parsed = {};
  try {
    parsed = await response.json();
  } catch (_) {
    parsed = {};
  }

  return {
    status: response.status,
    code: parsed.code,
    error: parsed.error,
    objectId: parsed.objectId,
    results: Array.isArray(parsed.results) ? parsed.results : undefined,
    count: Array.isArray(parsed.results) ? parsed.results.length : undefined,
    acl: parsed.ACL,
    weekday: parsed.weekday,
    endMinutes: parsed.endMinutes,
    salon: parsed.salon,
    professional: parsed.professional,
    owner: parsed.owner,
  };
}

async function baselineHttp({ method, url, headers, body }) {
  const response = await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  let parsed = {};
  try {
    parsed = await response.json();
  } catch (_) {
    parsed = {};
  }
  return { status: response.status, body: parsed };
}

function hoursBody({ salonId, professionalId, weekday, acl }) {
  const body = {
    weekday,
    isWorking: true,
    startMinutes: 540,
    endMinutes: 1080,
    salon: pointer('Salon', salonId),
    professional: pointer('Professional', professionalId),
  };
  if (acl) {
    body.ACL = acl;
  }
  return body;
}

function pointerObjectId(value) {
  if (!value) {
    return null;
  }
  if (typeof value === 'string') {
    return value;
  }
  return value.objectId || value.id || null;
}

function policyBlocked(response) {
  if (!response) {
    return true;
  }
  if (response.code === 119 || response.code === 101) {
    return true;
  }
  if (
    response.status === 400 ||
    response.status === 401 ||
    response.status === 403 ||
    response.status === 404
  ) {
    return true;
  }
  return false;
}

function hoursMatchesTenant(row, tenant) {
  if (!row || !tenant) {
    return false;
  }
  return (
    pointerObjectId(row.salon) === tenant.salonId &&
    pointerObjectId(row.professional) === tenant.professionalId
  );
}

function pickCanonicalHours(rows, manifestIds, tenant) {
  const list = Array.isArray(rows) ? rows.filter((row) => row && row.objectId) : [];
  const wanted = new Set(manifestIds || []);
  const inManifest = wanted.size
    ? list.filter((row) => wanted.has(row.objectId))
    : [];
  let pool = inManifest.length > 0 ? inManifest : [];
  if (tenant) {
    pool = pool.filter((row) => hoursMatchesTenant(row, tenant));
  }
  if (pool.length === 0) {
    return null;
  }
  return (
    pool.find((row) => row.weekday === 1) ||
    pool.slice().sort((left, right) => (left.weekday || 0) - (right.weekday || 0))[0]
  );
}

function wrote(response) {
  return response.status >= 200 && response.status < 300 && !response.code;
}

function mutated(before, after, field, expected) {
  if (!after || after.status !== 200) {
    return false;
  }
  if (expected !== undefined) {
    return after[field] === expected;
  }
  return before && after[field] !== before[field];
}

async function listHours(env, sessionToken, where) {
  const query = encodeURIComponent(JSON.stringify(where || {}));
  return parseRequest(env, {
    method: 'GET',
    path: `/classes/ProfessionalWorkingHours?where=${query}&limit=100`,
    sessionToken,
  });
}

async function getHours(env, sessionToken, objectId) {
  return parseRequest(env, {
    method: 'GET',
    path: `/classes/ProfessionalWorkingHours/${objectId}`,
    sessionToken,
  });
}

function printRow(title, row) {
  console.log(`\n## ${title}`);
  console.log(
    `| Find | Get | Update | Delete | Create foreign | HTTP Find/Get/Update/Delete/Create |`,
  );
  console.log('|---|---|---|---|---|---|');
  console.log(
    `| ${verdict(row.find)} | ${verdict(row.get)} | ${verdict(row.update)} | ${verdict(row.delete)} | ${verdict(row.create)} | ${row.findHttp}/${row.getHttp}/${row.updateHttp}/${row.deleteHttp}/${row.createHttp} |`,
  );
  console.log(
    `codes find=${row.findCode || 'n/a'} get=${row.getCode || 'n/a'} update=${row.updateCode || 'n/a'} delete=${row.deleteCode || 'n/a'} create=${row.createCode || 'n/a'}`,
  );
}

async function resolveCanonicalHours(env, session, tenant, label) {
  if (session.parseUserId !== tenant.userId) {
    const error = new Error('seed manifest tenant mapping inconsistent');
    error.code = 'SEED_MANIFEST_INCONSISTENT';
    throw error;
  }

  const salonGet = await parseRequest(env, {
    method: 'GET',
    path: `/classes/Salon/${tenant.salonId}`,
    sessionToken: session.sessionToken,
  });
  const salonOwnerId = pointerObjectId(salonGet.owner);
  if (salonGet.status !== 200 || salonOwnerId !== tenant.userId) {
    console.log(
      `DIAG ${label} Salon ${maskId(tenant.salonId)} owner=${maskId(salonOwnerId)} expected=${maskId(tenant.userId)} http=${salonGet.status}`,
    );
    const error = new Error('seed manifest tenant mapping inconsistent');
    error.code = 'SEED_MANIFEST_INCONSISTENT';
    throw error;
  }

  const manifestIds = tenant.workingHoursIds || [];
  const loaded = [];
  for (const objectId of manifestIds) {
    const row = await getHours(env, session.sessionToken, objectId);
    if (row.status !== 200 || row.objectId !== objectId) {
      console.log(
        `DIAG ${label} skip ${maskId(objectId)} not readable as own http=${row.status} code=${row.code || 'n/a'}`,
      );
      continue;
    }
    if (!hoursMatchesTenant(row, tenant)) {
      console.log(
        `DIAG ${label} skip ${maskId(objectId)} weekday=${row.weekday} salon=${maskId(pointerObjectId(row.salon))} professional=${maskId(pointerObjectId(row.professional))} expected salon=${maskId(tenant.salonId)} professional=${maskId(tenant.professionalId)}`,
      );
      continue;
    }
    loaded.push(row);
  }

  const picked = pickCanonicalHours(loaded, manifestIds, tenant);
  if (!picked) {
    const error = new Error('seed manifest tenant mapping inconsistent');
    error.code = 'SEED_MANIFEST_INCONSISTENT';
    throw error;
  }

  return { target: picked, salonOwnerId };
}

function printCanonicalWh(label, session, tenant, target, salonOwnerId) {
  console.log(`\nTENANT ${label} CANONICAL WH`);
  console.log(`user=${label} salon=${label} professional=${label} weekday=${target.weekday}`);
  console.log(`objectId=${maskId(target.objectId)}`);
  console.log(`userId=${maskId(session.parseUserId)}`);
  console.log(`salonId=${maskId(pointerObjectId(target.salon))}`);
  console.log(`professionalId=${maskId(pointerObjectId(target.professional))}`);
  console.log(`Salon.ownerId=${maskId(salonOwnerId)}`);
}

function printOwnUpdateTarget(label, session, tenant, target, salonOwnerId) {
  printCanonicalWh(label, session, tenant, target, salonOwnerId);
}

async function proveOwnTenant(env, session, tenant, label) {
  const find = await listHours(env, session.sessionToken, {
    salon: pointer('Salon', tenant.salonId),
    professional: pointer('Professional', tenant.professionalId),
  });
  const ownIds = (find.results || []).map((item) => item.objectId);
  const findOk = find.status === 200 && ownIds.length >= 7;

  const resolved = await resolveCanonicalHours(env, session, tenant, label);
  const target = resolved.target;
  const salonOwnerId = resolved.salonOwnerId;
  const sampleId = target && target.objectId;
  const get = sampleId
    ? await getHours(env, session.sessionToken, sampleId)
    : { status: 0 };
  const getOk = get.status === 200 && get.objectId === sampleId;
  const publicAcl = Boolean(get.acl && get.acl['*']);
  const ownerAcl = Boolean(
    get.acl && session.parseUserId && get.acl[session.parseUserId],
  );

  printOwnUpdateTarget(label, session, tenant, get.status === 200 ? get : target, salonOwnerId);

  const originalEnd = get.endMinutes;
  const nextEnd = originalEnd === 1079 ? 1080 : 1079;
  const update = sampleId
    ? await parseRequest(env, {
        method: 'PUT',
        path: `/classes/ProfessionalWorkingHours/${sampleId}`,
        sessionToken: session.sessionToken,
        body: {
          endMinutes: nextEnd,
          salon: pointer('Salon', tenant.salonId),
          professional: pointer('Professional', tenant.professionalId),
          weekday: get.weekday || 1,
        },
      })
    : { status: 0 };
  const afterUpdate = sampleId
    ? await getHours(env, session.sessionToken, sampleId)
    : { status: 0 };
  const updateOk = wrote(update) && mutated(get, afterUpdate, 'endMinutes', nextEnd);
  if (!updateOk) {
    console.log(
      `OWN UPDATE ${label} FAILED http=${update.status} code=${update.code || 'n/a'} reason=${update.error || 'n/a'}`,
    );
  }
  if (updateOk && sampleId && originalEnd !== undefined) {
    await parseRequest(env, {
      method: 'PUT',
      path: `/classes/ProfessionalWorkingHours/${sampleId}`,
      sessionToken: session.sessionToken,
      body: {
        endMinutes: originalEnd,
        salon: pointer('Salon', tenant.salonId),
        professional: pointer('Professional', tenant.professionalId),
        weekday: get.weekday || 1,
      },
    });
  }

  const created = await parseRequest(env, {
    method: 'POST',
    path: '/classes/ProfessionalWorkingHours',
    sessionToken: session.sessionToken,
    body: hoursBody({
      salonId: tenant.salonId,
      professionalId: tenant.professionalId,
      weekday: 7,
    }),
  });
  let createOk = false;
  let createHttp = created.status;
  let createCode = created.code;
  if (created.objectId) {
    const createdGet = await getHours(env, session.sessionToken, created.objectId);
    createOk = createdGet.status === 200;
    await parseRequest(env, {
      method: 'DELETE',
      path: `/classes/ProfessionalWorkingHours/${created.objectId}`,
      sessionToken: session.sessionToken,
    });
  } else if (created.status >= 400) {
    const weekdaySeven =
      pickCanonicalHours(
        (find.results || []).filter((item) => item.weekday === 7),
        tenant.workingHoursIds,
      ) || (find.results || []).find((item) => item.weekday === 7);
    if (weekdaySeven && weekdaySeven.objectId) {
      const deleted = await parseRequest(env, {
        method: 'DELETE',
        path: `/classes/ProfessionalWorkingHours/${weekdaySeven.objectId}`,
        sessionToken: session.sessionToken,
      });
      if (wrote(deleted)) {
        const recreated = await parseRequest(env, {
          method: 'POST',
          path: '/classes/ProfessionalWorkingHours',
          sessionToken: session.sessionToken,
          body: hoursBody({
            salonId: tenant.salonId,
            professionalId: tenant.professionalId,
            weekday: 7,
          }),
        });
        createHttp = recreated.status;
        createCode = recreated.code;
        createOk = Boolean(recreated.objectId);
      }
    }
  }

  return {
    find: findOk,
    get: getOk,
    update: updateOk,
    create: createOk,
    findCount: ownIds.length,
    publicAcl,
    ownerAcl,
    findHttp: find.status,
    getHttp: get.status,
    updateHttp: update.status,
    createHttp,
    findCode: find.code,
    getCode: get.code,
    updateCode: update.code,
    createCode,
  };
}

async function proveCrossTenant(env, attacker, victim, victimSession) {
  const victimIds = victim.workingHoursIds || [];
  const findAll = await listHours(env, attacker.sessionToken, {});
  const sawVictim = (findAll.results || []).some((item) =>
    victimIds.includes(item.objectId),
  );
  const findVictimSalon = await listHours(env, attacker.sessionToken, {
    salon: pointer('Salon', victim.salonId),
  });
  const foundBySalon = (findVictimSalon.results || []).some((item) =>
    victimIds.includes(item.objectId),
  );

  const targetId = victimIds[0];
  const get = targetId
    ? await getHours(env, attacker.sessionToken, targetId)
    : { status: 0 };

  const before = targetId
    ? await getHours(env, victimSession.sessionToken, targetId)
    : { status: 0 };
  const update = targetId
    ? await parseRequest(env, {
        method: 'PUT',
        path: `/classes/ProfessionalWorkingHours/${targetId}`,
        sessionToken: attacker.sessionToken,
        body: { endMinutes: 600 },
      })
    : { status: 0 };
  const after = targetId
    ? await getHours(env, victimSession.sessionToken, targetId)
    : { status: 0 };
  const updateMutated = mutated(before, after, 'endMinutes', 600);

  const create = await parseRequest(env, {
    method: 'POST',
    path: '/classes/ProfessionalWorkingHours',
    sessionToken: attacker.sessionToken,
    body: hoursBody({
      salonId: victim.salonId,
      professionalId: victim.professionalId,
      weekday: 1,
      acl: {
        [attacker.parseUserId]: { read: true, write: true },
        '*': { read: true, write: true },
      },
    }),
  });

  const del = targetId
    ? await parseRequest(env, {
        method: 'DELETE',
        path: `/classes/ProfessionalWorkingHours/${targetId}`,
        sessionToken: attacker.sessionToken,
      })
    : { status: 0 };

  return {
    find: sawVictim || foundBySalon,
    get: get.status === 200 && get.objectId === targetId,
    update: updateMutated,
    delete: wrote(del),
    create: Boolean(create.objectId),
    findHttp: findAll.status,
    getHttp: get.status,
    updateHttp: update.status,
    deleteHttp: del.status,
    createHttp: create.status,
    findCode: findAll.code,
    getCode: get.code,
    updateCode: update.code,
    deleteCode: del.code,
    createCode: create.code,
  };
}

async function provePointerTamper(env, attacker, own, victim) {
  const canonical = await resolveCanonicalHours(env, attacker, own, attacker.label);
  const ownId = canonical.target && canonical.target.objectId;
  const salonSwap = ownId
    ? await parseRequest(env, {
        method: 'PUT',
        path: `/classes/ProfessionalWorkingHours/${ownId}`,
        sessionToken: attacker.sessionToken,
        body: { salon: pointer('Salon', victim.salonId) },
      })
    : { status: 0 };
  const afterSalon = ownId
    ? await getHours(env, attacker.sessionToken, ownId)
    : { status: 0 };
  const salonChanged =
    pointerObjectId(afterSalon.salon) === victim.salonId;

  const professionalSwap = ownId
    ? await parseRequest(env, {
        method: 'PUT',
        path: `/classes/ProfessionalWorkingHours/${ownId}`,
        sessionToken: attacker.sessionToken,
        body: { professional: pointer('Professional', victim.professionalId) },
      })
    : { status: 0 };
  const afterPro = ownId
    ? await getHours(env, attacker.sessionToken, ownId)
    : { status: 0 };
  const professionalChanged =
    pointerObjectId(afterPro.professional) === victim.professionalId;
  const mixedAB = await parseRequest(env, {
    method: 'POST',
    path: '/classes/ProfessionalWorkingHours',
    sessionToken: attacker.sessionToken,
    body: hoursBody({
      salonId: own.salonId,
      professionalId: victim.professionalId,
      weekday: 3,
    }),
  });
  const mixedBA = await parseRequest(env, {
    method: 'POST',
    path: '/classes/ProfessionalWorkingHours',
    sessionToken: attacker.sessionToken,
    body: hoursBody({
      salonId: victim.salonId,
      professionalId: own.professionalId,
      weekday: 3,
    }),
  });

  return {
    salonSwapDenied: policyBlocked(salonSwap) || !salonChanged,
    professionalSwapDenied: policyBlocked(professionalSwap) || !professionalChanged,
    mixedABDenied: policyBlocked(mixedAB) || !mixedAB.objectId,
    mixedBADenied: policyBlocked(mixedBA) || !mixedBA.objectId,
    salonSwapHttp: salonSwap.status,
    salonSwapCode: salonSwap.code,
    professionalSwapHttp: professionalSwap.status,
    professionalSwapCode: professionalSwap.code,
    mixedABHttp: mixedAB.status,
    mixedABCode: mixedAB.code,
    mixedBAHttp: mixedBA.status,
    mixedBACode: mixedBA.code,
  };
}

async function main() {
  let env;
  try {
    env = assertStagingEnv();
  } catch (error) {
    console.error(error.message);
    process.exit(2);
  }

  let authenticated;
  try {
    authenticated = await authenticateBaselineUsers({
      env,
      http: baselineHttp,
    });
  } catch (error) {
    console.error(error.message);
    process.exit(error.code === 'STAGING_AUTH' ? 2 : 1);
  }

  const { userA, userB } = authenticated;
  const manifest = loadSeedManifest();
  if (!manifest || !manifest.A || !manifest.B) {
    console.error('Seed manifest missing. Run npm run seed:staging first.');
    process.exit(2);
  }

  console.log('T1.S1 WorkingHours secure proof starting');
  console.log(`applicationId=${maskId(env.applicationId)}`);
  console.log(authenticated.summary);
  console.log(
    `WorkingHours A: ${(manifest.A.workingHoursIds || []).length} B: ${(manifest.B.workingHoursIds || []).length}`,
  );

  if (
    (manifest.A.workingHoursIds || []).length !== 7 ||
    (manifest.B.workingHoursIds || []).length !== 7
  ) {
    console.error('Seed is not intact (expected 7 WorkingHours per tenant).');
    process.exit(1);
  }

  let canonicalA;
  let canonicalB;
  try {
    canonicalA = await resolveCanonicalHours(env, userA, manifest.A, 'A');
    canonicalB = await resolveCanonicalHours(env, userB, manifest.B, 'B');
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }

  printCanonicalWh('A', userA, manifest.A, canonicalA.target, canonicalA.salonOwnerId);
  printCanonicalWh('B', userB, manifest.B, canonicalB.target, canonicalB.salonOwnerId);

  const ownA = await proveOwnTenant(env, userA, manifest.A, 'A');
  const ownB = await proveOwnTenant(env, userB, manifest.B, 'B');
  const aToB = await proveCrossTenant(env, userA, manifest.B, userB);
  const bToA = await proveCrossTenant(env, userB, manifest.A, userA);
  const tamperA = await provePointerTamper(env, userA, manifest.A, manifest.B);
  const tamperB = await provePointerTamper(env, userB, manifest.B, manifest.A);

  console.log('\n## OWN TENANT A');
  console.log(
    `Find=${verdict(ownA.find)} (${ownA.findCount}) Get=${verdict(ownA.get)} Update=${verdict(ownA.update)} Create=${verdict(ownA.create)} ownerAcl=${ownA.ownerAcl} publicAcl=${ownA.publicAcl}`,
  );
  console.log('\n## OWN TENANT B');
  console.log(
    `Find=${verdict(ownB.find)} (${ownB.findCount}) Get=${verdict(ownB.get)} Update=${verdict(ownB.update)} Create=${verdict(ownB.create)} ownerAcl=${ownB.ownerAcl} publicAcl=${ownB.publicAcl}`,
  );

  printRow('CROSS-TENANT A → B', aToB);
  printRow('CROSS-TENANT B → A', bToA);

  console.log('\n## POINTER TAMPERING');
  console.log(
    `A salon→B ${verdict(!tamperA.salonSwapDenied)} denied=${tamperA.salonSwapDenied} http=${tamperA.salonSwapHttp} code=${tamperA.salonSwapCode || 'n/a'}`,
  );
  console.log(
    `A professional→B ${verdict(!tamperA.professionalSwapDenied)} denied=${tamperA.professionalSwapDenied} http=${tamperA.professionalSwapHttp} code=${tamperA.professionalSwapCode || 'n/a'}`,
  );
  console.log(
    `A SalonA+ProB create denied=${tamperA.mixedABDenied} http=${tamperA.mixedABHttp} code=${tamperA.mixedABCode || 'n/a'}`,
  );
  console.log(
    `A SalonB+ProA create denied=${tamperA.mixedBADenied} http=${tamperA.mixedBAHttp} code=${tamperA.mixedBACode || 'n/a'}`,
  );
  console.log(
    `B salon→A denied=${tamperB.salonSwapDenied} professional→A denied=${tamperB.professionalSwapDenied}`,
  );

  const approved =
    ownA.find &&
    ownA.get &&
    ownA.update &&
    ownA.create &&
    ownB.find &&
    ownB.get &&
    ownB.update &&
    ownB.create &&
    !aToB.find &&
    !aToB.get &&
    !aToB.update &&
    !aToB.delete &&
    !aToB.create &&
    !bToA.find &&
    !bToA.get &&
    !bToA.update &&
    !bToA.delete &&
    !bToA.create &&
    tamperA.salonSwapDenied &&
    tamperA.professionalSwapDenied &&
    tamperA.mixedABDenied &&
    tamperA.mixedBADenied &&
    tamperB.salonSwapDenied &&
    tamperB.professionalSwapDenied;

  console.log(`\nDECISÃO: ${approved ? 'APROVADA para replicar' : 'NÃO APROVADA'}`);
  console.log('T1.S1 WorkingHours secure proof completed (staging only).');
  process.exit(approved ? 0 : 1);
}

if (require.main === module) {
  main().catch((error) => {
    console.error('T1.S1 WorkingHours secure proof crashed');
    console.error(error && error.message ? error.message : error);
    process.exit(1);
  });
}

module.exports = {
  pickCanonicalHours,
  policyBlocked,
  pointerObjectId,
  hoursMatchesTenant,
};
