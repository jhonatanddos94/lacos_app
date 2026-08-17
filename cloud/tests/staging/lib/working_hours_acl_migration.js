'use strict';

const {
  pointerId,
  buildOwnerOnlyAcl,
  isOwnerOnlyAcl,
} = require('../../../security/workingHours/workingHoursTenancyPolicy');

const CLASS_NAME = 'ProfessionalWorkingHours';

const TARGET_CLP = Object.freeze({
  find: { requiresAuthentication: true },
  get: { requiresAuthentication: true },
  create: { requiresAuthentication: true },
  update: { requiresAuthentication: true },
  delete: { requiresAuthentication: true },
  count: { requiresAuthentication: true },
  addField: {},
});

function summarizeClp(clp) {
  if (!clp || typeof clp !== 'object') {
    return { raw: null };
  }
  const ops = ['find', 'get', 'create', 'update', 'delete', 'addField', 'count'];
  const summary = {};
  ops.forEach((op) => {
    const value = clp[op] || {};
    summary[op] = {
      public: value['*'] === true,
      requiresAuthentication: value.requiresAuthentication === true,
      empty: Object.keys(value).length === 0,
    };
  });
  return summary;
}

function createMasterHttpClient({ env, http }) {
  async function request({ method, path, query, body }) {
    const url = new URL(`${env.serverURL}${path}`);
    if (query) {
      Object.entries(query).forEach(([key, value]) => {
        url.searchParams.set(
          key,
          typeof value === 'string' ? value : JSON.stringify(value),
        );
      });
    }
    return http({
      method,
      url: url.toString(),
      headers: {
        'X-Parse-Application-Id': env.applicationId,
        'X-Parse-Master-Key': env.masterKey,
        'Content-Type': 'application/json',
      },
      body,
    });
  }

  return { request };
}

async function migrateWorkingHoursAcl({ env, http, applyClp = true }) {
  if (!env || !env.masterKey || !env.applicationId || !env.serverURL) {
    const error = new Error('Staging migration env is incomplete.');
    error.code = 'STAGING_GATE';
    throw error;
  }

  const client = createMasterHttpClient({ env, http });
  const listed = await client.request({
    method: 'GET',
    path: `/classes/${CLASS_NAME}`,
    query: { limit: 1000 },
  });

  if (listed.status >= 400) {
    const error = new Error(
      `List ${CLASS_NAME} failed status=${listed.status}`,
    );
    error.code = 'MIGRATION_LIST';
    throw error;
  }

  const rows = Array.isArray(listed.body && listed.body.results)
    ? listed.body.results
    : [];

  const result = {
    total: rows.length,
    updated: 0,
    skipped: 0,
    failed: 0,
    orphaned: 0,
    failures: [],
    orphans: [],
  };

  for (const row of rows) {
    const salonId = pointerId(row.salon);
    if (!salonId) {
      result.failed += 1;
      result.failures.push({ objectId: row.objectId, reason: 'missing salon' });
      continue;
    }

    const salonResponse = await client.request({
      method: 'GET',
      path: `/classes/Salon/${salonId}`,
    });
    if (salonResponse.status >= 400) {
      result.orphaned += 1;
      result.orphans.push({
        objectId: row.objectId,
        reason: `salon status=${salonResponse.status}`,
      });
      continue;
    }
    const ownerId = pointerId(salonResponse.body && salonResponse.body.owner);
    if (!ownerId) {
      result.failed += 1;
      result.failures.push({
        objectId: row.objectId,
        reason: 'Salon owner missing',
      });
      continue;
    }

    const acl = buildOwnerOnlyAcl(ownerId);
    if (isOwnerOnlyAcl(row.ACL, ownerId)) {
      result.skipped += 1;
      continue;
    }

    const updated = await client.request({
      method: 'PUT',
      path: `/classes/${CLASS_NAME}/${row.objectId}`,
      body: { ACL: acl },
    });
    if (updated.status >= 400) {
      result.failed += 1;
      result.failures.push({
        objectId: row.objectId,
        reason: `ACL write status=${updated.status}`,
      });
      continue;
    }
    result.updated += 1;
  }

  let clpBefore = null;
  let clpAfter = null;
  if (applyClp) {
    const schema = await client.request({
      method: 'GET',
      path: `/schemas/${CLASS_NAME}`,
    });
    clpBefore = summarizeClp(
      schema.body && schema.body.classLevelPermissions,
    );

    const clpWrite = await client.request({
      method: 'PUT',
      path: `/schemas/${CLASS_NAME}`,
      body: { classLevelPermissions: TARGET_CLP },
    });
    if (clpWrite.status >= 400) {
      const error = new Error(
        `CLP update failed status=${clpWrite.status} code=${
          clpWrite.body && clpWrite.body.code
        }`,
      );
      error.code = 'MIGRATION_CLP';
      throw error;
    }

    const schemaAfter = await client.request({
      method: 'GET',
      path: `/schemas/${CLASS_NAME}`,
    });
    clpAfter = summarizeClp(
      schemaAfter.body && schemaAfter.body.classLevelPermissions,
    );
  }

  return {
    ...result,
    clpBefore,
    clpAfter,
    targetClp: TARGET_CLP,
  };
}

module.exports = {
  CLASS_NAME,
  TARGET_CLP,
  summarizeClp,
  migrateWorkingHoursAcl,
};
