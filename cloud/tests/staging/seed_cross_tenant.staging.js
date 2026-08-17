'use strict';

/**
 * T1.S0 — Idempotent staging seed for tenants teste_a / teste_b.
 * Master Key only. Aborts before any request if the staging gate fails.
 * Never logs secrets. Never talks to production.
 */

const fs = require('fs');
const path = require('path');

const { assertStagingEnv, maskId } = require('../../scripts/assert-staging-env');
const {
  seedCrossTenants,
  buildManifest,
} = require('./lib/cross_tenant_seed');

const MANIFEST_PATH = path.join(__dirname, '.seed-manifest.json');

async function defaultHttp({ method, url, headers, body }) {
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

function printTenant(label, tenant) {
  console.log(`USER ${label}:`);
  console.log(`userId ${maskId(tenant.userId)}`);
  console.log(`salonId ${maskId(tenant.salonId)}`);
  console.log(`professionalId ${maskId(tenant.professionalId)}`);
  console.log(`clientId ${maskId(tenant.clientId)}`);
  console.log(`serviceId ${maskId(tenant.serviceId)}`);
  console.log(`appointmentId ${maskId(tenant.appointmentId)}`);
}

async function main() {
  let env;
  try {
    env = assertStagingEnv({
      requireClientKey: false,
      requireMasterKey: true,
    });
  } catch (error) {
    console.error(error.message);
    process.exit(2);
  }

  if (!env.masterKey) {
    console.error('Staging Master Key is required. Aborting before any request.');
    process.exit(2);
  }

  console.log('T1.S0 seed starting');
  console.log(`applicationId=${maskId(env.applicationId)}`);
  console.log(`serverURL=${env.serverURL}`);

  const result = await seedCrossTenants({ env, http: defaultHttp });
  const manifest = buildManifest(result);

  fs.writeFileSync(MANIFEST_PATH, `${JSON.stringify(manifest, null, 2)}\n`);

  printTenant('A', result.A);
  console.log('');
  printTenant('B', result.B);
  console.log('');
  console.log(`WorkingHours A: ${result.A.workingHoursCount}`);
  console.log(`WorkingHours B: ${result.B.workingHoursCount}`);
  console.log('T1.S0 seed completed (staging only).');
}

main().catch((error) => {
  console.error('T1.S0 seed aborted');
  console.error(error && error.message ? error.message : error);
  process.exit(1);
});
