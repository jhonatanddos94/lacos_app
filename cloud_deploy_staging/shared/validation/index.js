'use strict';

const { CloudError, ErrorCodes } = require('../errors');

function assertPresent(value, fieldName) {
  if (value === undefined || value === null || value === '') {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      `Missing required field: ${fieldName}`,
      { statusCode: 400 },
    );
  }
  return value;
}

function assertObject(value, fieldName) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      `Field ${fieldName} must be an object`,
      { statusCode: 400 },
    );
  }
  return value;
}

module.exports = {
  assertPresent,
  assertObject,
};
