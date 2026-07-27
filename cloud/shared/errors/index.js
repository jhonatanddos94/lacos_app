'use strict';

/**
 * Stable error codes for Cloud Function contracts.
 * Handlers in later sprints should throw CloudError with these codes.
 */
const ErrorCodes = Object.freeze({
  INTERNAL: 'INTERNAL',
  VALIDATION: 'VALIDATION',
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  TEMPORARY: 'TEMPORARY',
  EMAIL_UNVERIFIED: 'EMAIL_UNVERIFIED',
  CONFIGURATION_ERROR: 'CONFIGURATION_ERROR',
  CONFLICT: 'CONFLICT',
  NOT_IMPLEMENTED: 'NOT_IMPLEMENTED',
});

class CloudError extends Error {
  constructor(code, message, { statusCode = 400, details = undefined } = {}) {
    super(message);
    this.name = 'CloudError';
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
  }
}

function isCloudError(error) {
  return error instanceof CloudError || (error && error.name === 'CloudError');
}

/**
 * Client-facing payload (no internal details).
 */
function toClientErrorBody(error) {
  if (isCloudError(error)) {
    return {
      code: error.code,
      message: error.message,
    };
  }

  return {
    code: ErrorCodes.INTERNAL,
    message: 'An unexpected error occurred.',
  };
}

module.exports = {
  ErrorCodes,
  CloudError,
  isCloudError,
  toClientErrorBody,
};
