'use strict';

/**
 * T1.S1 STAGING-ONLY Cloud Code bundle.
 *
 * Autocontained deploy artifact for Back4App `lacos-staging`.
 * Does NOT replace cloud/main.js or production Cloud Code.
 * Does NOT include exchangeSession / firebase-admin.
 *
 * Registers always (this file is only deployed to lacos-staging):
 *   - ping
 *   - health
 *   - beforeSave('ProfessionalWorkingHours')
 *
 * Do not deploy this file to production.
 *
 * Master Key (request.master === true):
 *   allowed so ACL migration can write. Tenancy user-check is skipped;
 *   Salon.owner ACL is still applied. Fail closed if Salon.owner is missing.
 *
 * Policy is semantically equivalent to:
 *   cloud/security/workingHours/workingHoursTenancyPolicy.js
 *   cloud/triggers/beforeSave/professionalWorkingHours.js
 */

const ERROR_CODES = Object.freeze({
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  VALIDATION: 'VALIDATION',
  NOT_FOUND: 'NOT_FOUND',
});

function isStagingEnv(env) {
  return String((env && env.LACOS_ENV) || '') === 'staging';
}

function pointerId(value) {
  if (!value) {
    return null;
  }
  if (typeof value === 'string' && value.length > 0) {
    return value;
  }
  if (typeof value.objectId === 'string' && value.objectId.length > 0) {
    return value.objectId;
  }
  if (typeof value.id === 'string' && value.id.length > 0) {
    return value.id;
  }
  return null;
}

function deny(code, message) {
  return {
    allow: false,
    code,
    message,
    ownerId: null,
    acl: null,
  };
}

function buildOwnerOnlyAcl(ownerId) {
  return {
    [ownerId]: { read: true, write: true },
  };
}

function allow(ownerId) {
  return {
    allow: true,
    code: null,
    message: null,
    ownerId,
    acl: buildOwnerOnlyAcl(ownerId),
  };
}

async function evaluateWorkingHoursBeforeSave({
  userId,
  isMaster = false,
  isCreate,
  submittedSalonId,
  submittedProfessionalId,
  originalSalonId,
  originalProfessionalId,
  fetchSalon,
  fetchProfessional,
}) {
  if (!isMaster && !userId) {
    return deny(ERROR_CODES.UNAUTHORIZED, 'Authentication required.');
  }

  if (!isCreate) {
    if (
      submittedSalonId &&
      originalSalonId &&
      submittedSalonId !== originalSalonId
    ) {
      return deny(ERROR_CODES.FORBIDDEN, 'salon cannot be changed.');
    }
    if (
      submittedProfessionalId &&
      originalProfessionalId &&
      submittedProfessionalId !== originalProfessionalId
    ) {
      return deny(ERROR_CODES.FORBIDDEN, 'professional cannot be changed.');
    }
  }

  const salonId = isCreate
    ? submittedSalonId
    : originalSalonId || submittedSalonId;
  const professionalId = isCreate
    ? submittedProfessionalId
    : originalProfessionalId || submittedProfessionalId;

  if (!salonId || !professionalId) {
    return deny(
      ERROR_CODES.VALIDATION,
      'salon and professional are required.',
    );
  }

  const salon = await fetchSalon(salonId);
  if (!salon || !salon.objectId) {
    return deny(ERROR_CODES.NOT_FOUND, 'Salon not found.');
  }
  if (!salon.ownerId) {
    return deny(ERROR_CODES.FORBIDDEN, 'Salon owner is missing.');
  }

  const professional = await fetchProfessional(professionalId);
  if (!professional || !professional.objectId) {
    return deny(ERROR_CODES.NOT_FOUND, 'Professional not found.');
  }
  if (!professional.salonId || professional.salonId !== salon.objectId) {
    return deny(
      ERROR_CODES.FORBIDDEN,
      'professional does not belong to salon.',
    );
  }

  if (!isMaster && userId !== salon.ownerId) {
    return deny(ERROR_CODES.FORBIDDEN, 'User is not the salon owner.');
  }

  return allow(salon.ownerId);
}

function parseErrorCode(Parse, code) {
  if (code === ERROR_CODES.UNAUTHORIZED) {
    return Parse.Error.INVALID_SESSION_TOKEN || 209;
  }
  if (code === ERROR_CODES.FORBIDDEN) {
    return Parse.Error.OPERATION_FORBIDDEN || 119;
  }
  if (code === ERROR_CODES.VALIDATION) {
    return Parse.Error.VALIDATION_ERROR || 142;
  }
  if (code === ERROR_CODES.NOT_FOUND) {
    return Parse.Error.OBJECT_NOT_FOUND || 101;
  }
  return Parse.Error.SCRIPT_FAILED || 141;
}

function applyOwnerOnlyAcl(Parse, object, ownerId) {
  const acl = new Parse.ACL();
  acl.setPublicReadAccess(false);
  acl.setPublicWriteAccess(false);
  acl.setReadAccess(ownerId, true);
  acl.setWriteAccess(ownerId, true);
  object.setACL(acl);
}

function defaultFetchSalon(Parse) {
  return async function fetchSalon(salonId) {
    try {
      const query = new Parse.Query('Salon');
      const salon = await query.get(salonId, { useMasterKey: true });
      return {
        objectId: salon.id,
        ownerId: pointerId(salon.get('owner')),
      };
    } catch (_) {
      return null;
    }
  };
}

function defaultFetchProfessional(Parse) {
  return async function fetchProfessional(professionalId) {
    try {
      const query = new Parse.Query('Professional');
      const professional = await query.get(professionalId, {
        useMasterKey: true,
      });
      return {
        objectId: professional.id,
        salonId: pointerId(professional.get('salon')),
      };
    } catch (_) {
      return null;
    }
  };
}

function createWorkingHoursBeforeSave(Parse, deps = {}) {
  const fetchSalon = deps.fetchSalon || defaultFetchSalon(Parse);
  const fetchProfessional =
    deps.fetchProfessional || defaultFetchProfessional(Parse);

  return async function professionalWorkingHoursBeforeSave(request) {
    const object = request.object;
    const original = request.original;
    const isCreate =
      typeof object.isNew === 'function' ? object.isNew() : !object.id;
    const isMaster = request.master === true;
    const userId = request.user ? request.user.id : null;

    const decision = await evaluateWorkingHoursBeforeSave({
      userId,
      isMaster,
      isCreate,
      submittedSalonId: pointerId(object.get('salon')),
      submittedProfessionalId: pointerId(object.get('professional')),
      originalSalonId: original ? pointerId(original.get('salon')) : null,
      originalProfessionalId: original
        ? pointerId(original.get('professional'))
        : null,
      fetchSalon,
      fetchProfessional,
    });

    if (!decision.allow) {
      console.warn(
        JSON.stringify({
          level: 'warn',
          scope: 't1s1.bundle.ProfessionalWorkingHours',
          message: 'rejected',
          code: decision.code,
          isCreate,
          isMaster,
        }),
      );
      throw new Parse.Error(
        parseErrorCode(Parse, decision.code),
        decision.message,
      );
    }

    applyOwnerOnlyAcl(Parse, object, decision.ownerId);
  };
}

function registerCloudCode(Parse, _env = process.env, deps = {}) {
  Parse.Cloud.define('ping', async () => ({
    status: 'ok',
    service: 'lacos-cloud-staging-bundle',
  }));

  Parse.Cloud.define('health', async () => ({
    status: 'ok',
    environment: 'staging-bundle',
    workingHoursBeforeSave: true,
  }));

  Parse.Cloud.beforeSave(
    'ProfessionalWorkingHours',
    createWorkingHoursBeforeSave(Parse, deps),
  );

  console.log(
    '[T1.S1] STAGING BUNDLE loaded - ProfessionalWorkingHours beforeSave registered',
  );
  return { workingHoursBeforeSave: true };
}

if (typeof global !== 'undefined' && global.Parse && global.Parse.Cloud) {
  registerCloudCode(global.Parse, process.env);
}

module.exports = {
  ERROR_CODES,
  isStagingEnv,
  pointerId,
  buildOwnerOnlyAcl,
  evaluateWorkingHoursBeforeSave,
  createWorkingHoursBeforeSave,
  registerCloudCode,
};
