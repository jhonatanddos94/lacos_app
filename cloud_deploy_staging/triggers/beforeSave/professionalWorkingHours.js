'use strict';

const { loadConfig } = require('../../config');
const { createLogger } = require('../../shared/logging');
const {
  pointerId,
  evaluateWorkingHoursBeforeSave,
} = require('../../security/workingHours/workingHoursTenancyPolicy');

const logger = createLogger('triggers.beforeSave.ProfessionalWorkingHours');

function parseErrorCode(Parse, code) {
  if (code === 'UNAUTHORIZED') {
    return Parse.Error.INVALID_SESSION_TOKEN || 209;
  }
  if (code === 'FORBIDDEN') {
    return Parse.Error.OPERATION_FORBIDDEN || 119;
  }
  if (code === 'VALIDATION') {
    return Parse.Error.VALIDATION_ERROR || 142;
  }
  if (code === 'NOT_FOUND') {
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

function createProfessionalWorkingHoursBeforeSave(Parse, deps = {}) {
  const fetchSalon = deps.fetchSalon || defaultFetchSalon(Parse);
  const fetchProfessional =
    deps.fetchProfessional || defaultFetchProfessional(Parse);
  const readConfig = deps.loadConfig || loadConfig;

  return async function professionalWorkingHoursBeforeSave(request) {
    const config = readConfig();
    if (config.environment === 'production') {
      logger.warn('skipped in production (T1.S1 staging-only)');
      return;
    }

    const object = request.object;
    const original = request.original;
    const isCreate = typeof object.isNew === 'function' ? object.isNew() : !object.id;
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
      logger.warn('rejected', {
        code: decision.code,
        isCreate,
        isMaster,
      });
      throw new Parse.Error(parseErrorCode(Parse, decision.code), decision.message);
    }

    applyOwnerOnlyAcl(Parse, object, decision.ownerId);
  };
}

module.exports = {
  createProfessionalWorkingHoursBeforeSave,
};
