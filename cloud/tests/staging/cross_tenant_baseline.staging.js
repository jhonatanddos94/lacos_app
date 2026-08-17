'use strict';

/**
 * T1.S0 — REST cross-tenant baseline against STAGING ONLY.
 *
 * Refuses production Application ID via assertStagingEnv.
 * Never logs session tokens, ID tokens, keys, or passwords.
 *
 * Auth modes:
 *   LACOS_STAGING_AUTH_MODE=parse_login        (default preference)
 *     LACOS_STAGING_USER_A_USERNAME / PASSWORD
 *     LACOS_STAGING_USER_B_USERNAME / PASSWORD
 *   LACOS_STAGING_AUTH_MODE=exchange_session   (Firebase, optional)
 *     LACOS_STAGING_ID_TOKEN_A / B
 *
 * Always required:
 *   LACOS_STAGING_APPLICATION_ID  (≠ production)
 *   LACOS_STAGING_SERVER_URL
 *   LACOS_STAGING_CLIENT_KEY
 *
 * Master Key is NOT required. DELETE probes can wipe seed objects;
 * re-run `npm run seed:staging` afterwards.
 */

const fs = require('fs');
const path = require('path');

const { assertStagingEnv, maskId } = require('../../scripts/assert-staging-env');
const { TENANTS, parseDate } = require('./lib/cross_tenant_seed');
const { authenticateBaselineUsers } = require('./lib/baseline_auth');

const MANIFEST_PATH = path.join(__dirname, '.seed-manifest.json');

function loadSeedManifest() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
}

function tenantFromManifest(manifest, label) {
  const row = manifest[label];
  if (!row) {return null;}
  return {
    userId: row.userId,
    Salon: { objectId: row.salonId, status: 200 },
    Professional: { objectId: row.professionalId, status: 200 },
    Client: { objectId: row.clientId, status: 200 },
    Service: { objectId: row.serviceId, status: 200 },
    Appointment: { objectId: row.appointmentId, status: 200 },
    ProfessionalWorkingHours: {
      objectId: Array.isArray(row.workingHoursIds) ? row.workingHoursIds[0] : null,
      status: 200,
    },
  };
}

function firstObjectId(response) {
  if (response.objectId) {return response.objectId;}
  if (Array.isArray(response.results) && response.results[0]) {
    return response.results[0].objectId;
  }
  return null;
}

async function findOne(env, sessionToken, className, where) {
  const query = encodeURIComponent(JSON.stringify(where));
  return parseRequest(env, {
    method: 'GET',
    path: `/classes/${className}?where=${query}&limit=1`,
    sessionToken,
  });
}

async function locateOfficialTenant(env, sessionToken, spec) {
  const salon = await findOne(env, sessionToken, 'Salon', { name: spec.salonName });
  const salonId = firstObjectId(salon);
  if (!salonId) {return null;}

  const professional = await findOne(env, sessionToken, 'Professional', {
    salon: pointer('Salon', salonId),
    name: spec.professionalName,
  });
  const client = await findOne(env, sessionToken, 'Client', {
    salon: pointer('Salon', salonId),
    phone: spec.phone,
  });
  const service = await findOne(env, sessionToken, 'Service', {
    salon: pointer('Salon', salonId),
    name: spec.serviceName,
  });

  const professionalId = firstObjectId(professional);
  const clientId = firstObjectId(client);
  const serviceId = firstObjectId(service);
  if (!professionalId || !clientId || !serviceId) {return null;}

  const appointment = await findOne(env, sessionToken, 'Appointment', {
    salon: pointer('Salon', salonId),
    client: pointer('Client', clientId),
    startAt: parseDate(spec.startAt),
  });
  const hours = await findOne(env, sessionToken, 'ProfessionalWorkingHours', {
    salon: pointer('Salon', salonId),
    professional: pointer('Professional', professionalId),
    weekday: 1,
  });

  const appointmentId = firstObjectId(appointment);
  const hoursId = firstObjectId(hours);
  if (!appointmentId || !hoursId) {return null;}

  return {
    Salon: { objectId: salonId, status: salon.status },
    Professional: { objectId: professionalId, status: professional.status },
    Client: { objectId: clientId, status: client.status },
    Service: { objectId: serviceId, status: service.status },
    Appointment: { objectId: appointmentId, status: appointment.status },
    ProfessionalWorkingHours: { objectId: hoursId, status: hours.status },
  };
}

const CLASSES = Object.freeze([
  'Salon',
  'Professional',
  'Client',
  'Service',
  'Appointment',
  'ProfessionalWorkingHours',
]);

function pointer(className, objectId) {
  return { __type: 'Pointer', className, objectId };
}

function userPointer(objectId) {
  return { __type: 'Pointer', className: '_User', objectId };
}

async function parseRequest(env, { method, path, sessionToken, body }) {
  const headers = {
    'X-Parse-Application-Id': env.applicationId,
    'X-Parse-Client-Key': env.clientKey,
    'Content-Type': 'application/json',
  };
  if (sessionToken) {
    headers['X-Parse-Session-Token'] = sessionToken;
  }

  const response = await fetch(`${env.serverURL}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  let parsed;
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
    result: parsed.result,
    results: Array.isArray(parsed.results) ? parsed.results : undefined,
    count: Array.isArray(parsed.results) ? parsed.results.length : undefined,
    acl: parsed.ACL,
    owner: parsed.owner,
    salon: parsed.salon,
    professional: parsed.professional,
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

async function createObject(env, sessionToken, className, fields) {
  return parseRequest(env, {
    method: 'POST',
    path: `/classes/${className}`,
    sessionToken,
    body: fields,
  });
}

async function seedTenant(env, session, label) {
  const now = new Date();
  const startAt = new Date(now.getTime() + 48 * 60 * 60 * 1000);
  const endAt = new Date(startAt.getTime() + 60 * 60 * 1000);

  const salon = await createObject(env, session.sessionToken, 'Salon', {
    name: `Salon ${label} T1S0`,
    responsibleName: `Owner ${label}`,
    isActive: true,
    owner: userPointer(session.parseUserId),
  });

  if (!salon.objectId) {
    throw new Error(`seed Salon ${label} failed status=${salon.status} code=${salon.code}`);
  }

  const professional = await createObject(env, session.sessionToken, 'Professional', {
    name: `Professional ${label}`,
    isActive: true,
    salon: pointer('Salon', salon.objectId),
  });

  const client = await createObject(env, session.sessionToken, 'Client', {
    name: `Client ${label}`,
    phone: label === 'A' ? '11970000001' : '11970000002',
    isActive: true,
    isFavorite: false,
    clientSince: { __type: 'Date', iso: now.toISOString() },
    salon: pointer('Salon', salon.objectId),
    owner: userPointer(session.parseUserId),
  });

  const service = await createObject(env, session.sessionToken, 'Service', {
    name: `Service ${label}`,
    durationMinutes: 60,
    isActive: true,
    salon: pointer('Salon', salon.objectId),
    owner: userPointer(session.parseUserId),
  });

  const appointment = await createObject(env, session.sessionToken, 'Appointment', {
    startAt: { __type: 'Date', iso: startAt.toISOString() },
    endAt: { __type: 'Date', iso: endAt.toISOString() },
    status: 'pending',
    isActive: true,
    salon: pointer('Salon', salon.objectId),
    owner: userPointer(session.parseUserId),
    client: client.objectId ? pointer('Client', client.objectId) : undefined,
    professional: professional.objectId
      ? pointer('Professional', professional.objectId)
      : undefined,
  });

  const hours = await createObject(
    env,
    session.sessionToken,
    'ProfessionalWorkingHours',
    {
      weekday: 1,
      isWorking: true,
      startMinutes: 7 * 60,
      endMinutes: 20 * 60,
      salon: pointer('Salon', salon.objectId),
      professional: professional.objectId
        ? pointer('Professional', professional.objectId)
        : undefined,
    },
  );

  return {
    Salon: salon,
    Professional: professional,
    Client: client,
    Service: service,
    Appointment: appointment,
    ProfessionalWorkingHours: hours,
  };
}

function verdict(ok) {
  if (ok === true) {return 'SIM';}
  if (ok === false) {return 'NÃO';}
  return 'NÃO TESTADO';
}

function canRead(response, expectedId) {
  if (response.status === 200 && response.objectId === expectedId) {return true;}
  if (response.status === 200 && (response.count || 0) > 0) {
    return (response.results || []).some((item) => item.objectId === expectedId);
  }
  return false;
}

function canWrite(response) {
  return response.status >= 200 && response.status < 300 && !response.code;
}

async function attackClass(env, attacker, victim, className) {
  const victimId = victim[className] && victim[className].objectId;
  const victimSalonId = victim.Salon.objectId;

  const find = await parseRequest(env, {
    method: 'GET',
    path: `/classes/${className}?limit=100`,
    sessionToken: attacker.sessionToken,
  });
  const foundVictim = (find.results || []).some((item) => item.objectId === victimId);

  const get = victimId
    ? await parseRequest(env, {
        method: 'GET',
        path: `/classes/${className}/${victimId}`,
        sessionToken: attacker.sessionToken,
      })
    : { status: 0 };

  const update = victimId
    ? await parseRequest(env, {
        method: 'PUT',
        path: `/classes/${className}/${victimId}`,
        sessionToken: attacker.sessionToken,
        body: { t1s0Probe: `touched-by-${attacker.label}` },
      })
    : { status: 0 };

  const createForeign = await parseRequest(env, {
    method: 'POST',
    path: `/classes/${className}`,
    sessionToken: attacker.sessionToken,
    body: seedCreateBody(className, attacker, victimSalonId, victim),
  });

  const del = victimId
    ? await parseRequest(env, {
        method: 'DELETE',
        path: `/classes/${className}/${victimId}`,
        sessionToken: attacker.sessionToken,
      })
    : { status: 0 };

  return {
    className,
    find: {
      status: find.status,
      code: find.code,
      count: find.count,
      sawVictim: foundVictim,
    },
    get: {
      status: get.status,
      code: get.code,
      read: canRead(get, victimId),
    },
    update: {
      status: update.status,
      code: update.code,
      wrote: canWrite(update),
    },
    delete: {
      status: del.status,
      code: del.code,
      deleted: canWrite(del),
    },
    createForeign: {
      status: createForeign.status,
      code: createForeign.code,
      created: Boolean(createForeign.objectId),
    },
  };
}

function seedCreateBody(className, attacker, victimSalonId, victim) {
  const salon = pointer('Salon', victimSalonId);
  const owner = userPointer(attacker.parseUserId);

  switch (className) {
    case 'Salon':
      return {
        name: `Forged salon by ${attacker.label}`,
        responsibleName: attacker.label,
        isActive: true,
        owner: userPointer(victim.userId),
      };
    case 'Professional':
      return { name: `Forged pro ${attacker.label}`, isActive: true, salon };
    case 'Client':
      return {
        name: `Forged client ${attacker.label}`,
        phone: '11970000999',
        isActive: true,
        isFavorite: false,
        salon,
        owner,
      };
    case 'Service':
      return {
        name: `Forged service ${attacker.label}`,
        durationMinutes: 30,
        isActive: true,
        salon,
        owner,
      };
    case 'Appointment':
      return {
        startAt: { __type: 'Date', iso: new Date(Date.now() + 86400000).toISOString() },
        endAt: { __type: 'Date', iso: new Date(Date.now() + 90000000).toISOString() },
        status: 'pending',
        isActive: true,
        salon,
        owner,
      };
    case 'ProfessionalWorkingHours':
      return {
        weekday: 2,
        isWorking: true,
        startMinutes: 600,
        endMinutes: 960,
        salon,
        professional: victim.Professional.objectId
          ? pointer('Professional', victim.Professional.objectId)
          : undefined,
      };
    default:
      return { salon };
  }
}

function printAttack(direction, rows) {
  console.log(`\n## ${direction}`);
  console.log(
    '| Classe | Find B | Get B | Update B | Delete B | Create→Salon B | HTTP Find/Get/Update/Delete/Create |',
  );
  console.log('|---|---|---|---|---|---|---|');
  for (const row of rows) {
    console.log(
      `| ${row.className} | ${verdict(row.find.sawVictim)} | ${verdict(row.get.read)} | ${verdict(row.update.wrote)} | ${verdict(row.delete.deleted)} | ${verdict(row.createForeign.created)} | ${row.find.status}/${row.get.status}/${row.update.status}/${row.delete.status}/${row.createForeign.status} |`,
    );
  }
}

function printOwnership(label, seeded) {
  console.log(`\n## Ownership seed ${label}`);
  for (const className of CLASSES) {
    const created = seeded[className];
    console.log(
      `- ${className}: objectId=${created.objectId ? maskId(created.objectId) : 'FAILED'} status=${created.status} code=${created.code || 'n/a'}`,
    );
  }
}

async function inspectAcl(env, sessionToken, className, objectId) {
  if (!objectId) {return null;}
  return parseRequest(env, {
    method: 'GET',
    path: `/classes/${className}/${objectId}`,
    sessionToken,
  });
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

  console.log('T1.S0 REST baseline starting');
  console.log(`applicationId=${maskId(env.applicationId)}`);
  console.log(`serverURL=${env.serverURL}`);
  console.log(authenticated.summary);
  console.log(
    'WARN DELETE probes may remove staging seed objects. Re-run: npm run seed:staging',
  );

  const manifest = loadSeedManifest();
  let seedA = manifest ? tenantFromManifest(manifest, 'A') : null;
  let seedB = manifest ? tenantFromManifest(manifest, 'B') : null;

  if (seedA && seedB) {
    console.log('OK using seed manifest from npm run seed:staging');
  } else {
    seedA = await locateOfficialTenant(env, userA.sessionToken, TENANTS.A);
    seedB = await locateOfficialTenant(env, userA.sessionToken, TENANTS.B);
    if (seedA && seedB) {
      console.log('OK located official seed tenants as user A (cross-tenant find)');
    } else {
      seedB = seedB || (await locateOfficialTenant(env, userB.sessionToken, TENANTS.B));
      seedA = seedA || (await locateOfficialTenant(env, userA.sessionToken, TENANTS.A));
    }
  }

  if (!seedA || !seedB) {
    console.log('WARN official seed not found; creating ephemeral tenants');
    seedA = await seedTenant(env, userA, 'A');
    seedB = await seedTenant(env, userB, 'B');
  }

  seedA.userId = seedA.userId || userA.parseUserId;
  seedB.userId = seedB.userId || userB.parseUserId;

  printOwnership('A', seedA);
  printOwnership('B', seedB);

  console.log('\n## ACL sample (GET after create, no secrets)');
  for (const className of CLASSES) {
    const sample = await inspectAcl(
      env,
      userA.sessionToken,
      className,
      seedA[className].objectId,
    );
    const acl = sample && sample.acl ? JSON.stringify(sample.acl) : 'n/a';
    const publicRead = sample && sample.acl && sample.acl['*'] && sample.acl['*'].read === true;
    const publicWrite = sample && sample.acl && sample.acl['*'] && sample.acl['*'].write === true;
    console.log(
      `- ${className}: ACL=${acl} publicR=${publicRead === true} publicW=${publicWrite === true} ownerPresent=${Boolean(sample && sample.owner)} salonPresent=${Boolean(sample && sample.salon)}`,
    );
  }

  const aToB = [];
  const bToA = [];
  for (const className of CLASSES) {
    aToB.push(await attackClass(env, userA, seedB, className));
    bToA.push(await attackClass(env, userB, seedA, className));
  }

  printAttack('CROSS-TENANT A → B', aToB);
  printAttack('CROSS-TENANT B → A', bToA);

  console.log('\nT1.S0 REST baseline completed (staging only).');
  console.log(
    'WARN if DELETE succeeded, restore fake tenants with: npm run seed:staging',
  );
}

main().catch((error) => {
  console.error('T1.S0 REST baseline crashed');
  console.error(error && error.message ? error.message : error);
  process.exit(1);
});
