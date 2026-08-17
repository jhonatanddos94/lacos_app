'use strict';

const { ErrorCodes } = require('../../shared/errors');

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

function allow(ownerId) {
  return {
    allow: true,
    code: null,
    message: null,
    ownerId,
    acl: buildOwnerOnlyAcl(ownerId),
  };
}

function buildOwnerOnlyAcl(ownerId) {
  return {
    [ownerId]: { read: true, write: true },
  };
}

function isOwnerOnlyAcl(acl, ownerId) {
  if (!acl || typeof acl !== 'object' || !ownerId) {
    return false;
  }
  if (Object.prototype.hasOwnProperty.call(acl, '*')) {
    return false;
  }
  const keys = Object.keys(acl);
  if (keys.length !== 1 || keys[0] !== ownerId) {
    return false;
  }
  return acl[ownerId].read === true && acl[ownerId].write === true;
}

/**
 * Server-side tenancy decision for ProfessionalWorkingHours.
 * Does not trust client pointers, client ACL, or client-supplied owner.
 */
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
    return deny(ErrorCodes.UNAUTHORIZED, 'Authentication required.');
  }

  if (!isCreate) {
    if (
      submittedSalonId &&
      originalSalonId &&
      submittedSalonId !== originalSalonId
    ) {
      return deny(ErrorCodes.FORBIDDEN, 'salon cannot be changed.');
    }
    if (
      submittedProfessionalId &&
      originalProfessionalId &&
      submittedProfessionalId !== originalProfessionalId
    ) {
      return deny(ErrorCodes.FORBIDDEN, 'professional cannot be changed.');
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
      ErrorCodes.VALIDATION,
      'salon and professional are required.',
    );
  }

  const salon = await fetchSalon(salonId);
  if (!salon || !salon.objectId) {
    return deny(ErrorCodes.NOT_FOUND, 'Salon not found.');
  }
  if (!salon.ownerId) {
    return deny(ErrorCodes.FORBIDDEN, 'Salon owner is missing.');
  }

  const professional = await fetchProfessional(professionalId);
  if (!professional || !professional.objectId) {
    return deny(ErrorCodes.NOT_FOUND, 'Professional not found.');
  }
  if (!professional.salonId || professional.salonId !== salon.objectId) {
    return deny(
      ErrorCodes.FORBIDDEN,
      'professional does not belong to salon.',
    );
  }

  if (!isMaster && userId !== salon.ownerId) {
    return deny(ErrorCodes.FORBIDDEN, 'User is not the salon owner.');
  }

  return allow(salon.ownerId);
}

module.exports = {
  pointerId,
  buildOwnerOnlyAcl,
  isOwnerOnlyAcl,
  evaluateWorkingHoursBeforeSave,
};
