'use strict';

/**
 * T1.S1 — Staging-only ACL backfill + CLP for ProfessionalWorkingHours.
 * Master Key required. Aborts before any write if the staging gate fails.
 */

const { assertStagingEnv, maskId } = require('../../scripts/assert-staging-env');
const {
  migrateWorkingHoursAcl,
} = require('./lib/working_hours_acl_migration');

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

  console.log('T1.S1 WorkingHours ACL migration starting');
  console.log(`applicationId=${maskId(env.applicationId)}`);
  console.log(`serverURL=${env.serverURL}`);

  const result = await migrateWorkingHoursAcl({ env, http: defaultHttp });

  console.log(`total=${result.total}`);
  console.log(`updated=${result.updated}`);
  console.log(`skipped=${result.skipped}`);
  console.log(`orphaned=${result.orphaned}`);
  console.log(`failed=${result.failed}`);
  if (result.clpBefore) {
    console.log(`clpBefore=${JSON.stringify(result.clpBefore)}`);
  }
  if (result.clpAfter) {
    console.log(`clpAfter=${JSON.stringify(result.clpAfter)}`);
  }
  if (result.orphaned > 0) {
    result.orphans.forEach((item) => {
      console.log(
        `orphan objectId=${maskId(item.objectId)} reason=${item.reason}`,
      );
    });
  }
  if (result.failed > 0) {
    result.failures.forEach((item) => {
      console.error(
        `fail objectId=${maskId(item.objectId)} reason=${item.reason}`,
      );
    });
    process.exit(1);
  }
  console.log('T1.S1 WorkingHours ACL migration completed (staging only).');
}

main().catch((error) => {
  console.error('T1.S1 WorkingHours ACL migration aborted');
  console.error(error && error.message ? error.message : error);
  process.exit(1);
});
