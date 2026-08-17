'use strict';

const { loadConfig } = require('../config');
const { createLogger } = require('../shared/logging');
const {
  CloudError,
  ErrorCodes,
  isCloudError,
  toClientErrorBody,
} = require('../shared/errors');
const { assertObject } = require('../shared/validation');
const { maskUid } = require('../shared/utils');
const { FirebaseAuthService } = require('../services/FirebaseAuthService');
const { ParseUserService } = require('../services/ParseUserService');
const { SessionService } = require('../services/SessionService');

const logger = createLogger('functions.exchangeSession');

/**
 * Exchanges a Firebase ID Token for a Parse sessionToken.
 * Injectable deps for unit tests.
 *
 * @param {object} request Parse Cloud request
 * @param {object} [deps]
 */
async function exchangeSession(request, deps = {}) {
  const startedAt = Date.now();
  const config = deps.loadConfig ? deps.loadConfig() : loadConfig();
  const params = normalizeParams(request);

  const requestId =
    typeof params.requestId === 'string' && params.requestId.trim()
      ? params.requestId.trim()
      : undefined;
  const appVersion =
    typeof params.appVersion === 'string' ? params.appVersion : undefined;
  const platform =
    typeof params.platform === 'string' ? params.platform : undefined;

  const logBase = {
    functionName: 'exchangeSession',
    requestId,
    appVersion,
    platform,
  };

  try {
    const idToken = validateIdToken(params.idToken, config.constants.MAX_ID_TOKEN_LENGTH);

    const firebaseAuthService =
      deps.firebaseAuthService || new FirebaseAuthService();
    const parseUserService =
      deps.parseUserService || new ParseUserService({ Parse: deps.Parse });
    const sessionService =
      deps.sessionService || new SessionService({ Parse: deps.Parse });

    if (deps.Parse) {
      parseUserService.setParse(deps.Parse);
      sessionService.setParse(deps.Parse);
    } else if (global.Parse) {
      parseUserService.setParse(global.Parse);
      sessionService.setParse(global.Parse);
    }

    const identity = await firebaseAuthService.verifyIdToken(idToken);

    if (!identity.emailVerified) {
      throw new CloudError(
        ErrorCodes.EMAIL_UNVERIFIED,
        'Email address must be verified before continuing.',
        { statusCode: 403 },
      );
    }

    const { user, isNewUser } =
      await parseUserService.findOrCreateFromFirebaseIdentity(identity);

    const session = await sessionService.createSessionForUser(user);

    const result = {
      sessionToken: session.sessionToken,
      parseUserId: session.parseUserId || user.id,
      firebaseUid: identity.uid,
      email: identity.email,
      expiresAt: session.expiresAt,
      securityMode: config.featureFlags.securityMode,
      isNewUser,
    };

    logger.info('exchangeSession success', {
      ...logBase,
      result: 'success',
      durationMs: Date.now() - startedAt,
      uid: maskUid(identity.uid),
      isNewUser,
    });

    return result;
  } catch (error) {
    const clientBody = toClientErrorBody(error);
    logger.error('exchangeSession failed', {
      ...logBase,
      result: 'error',
      errorCode: clientBody.code,
      durationMs: Date.now() - startedAt,
    });

    if (isCloudError(error)) {
      throw error;
    }

    throw new CloudError(
      ErrorCodes.INTERNAL,
      'An unexpected error occurred.',
      { statusCode: 500 },
    );
  }
}

function normalizeParams(request) {
  if (!request || typeof request !== 'object') {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      'Invalid request.',
      { statusCode: 400 },
    );
  }

  const params = request.params;
  if (params === undefined || params === null) {
    return {};
  }

  return assertObject(params, 'params');
}

function validateIdToken(idToken, maxLength) {
  if (typeof idToken !== 'string') {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      'idToken is required.',
      { statusCode: 400 },
    );
  }

  const trimmed = idToken.trim();
  if (!trimmed) {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      'idToken is required.',
      { statusCode: 400 },
    );
  }

  if (trimmed.length > maxLength) {
    throw new CloudError(
      ErrorCodes.VALIDATION,
      'idToken is invalid.',
      { statusCode: 400 },
    );
  }

  return trimmed;
}

/**
 * Wraps handler for Parse.Cloud.define — maps CloudError to Parse.Error.
 */
function createExchangeSessionHandler(depsFactory) {
  return async function exchangeSessionCloudHandler(request) {
    const deps = typeof depsFactory === 'function' ? depsFactory() : {};
    const ParseGlobal = deps.Parse || global.Parse;
    try {
      return await exchangeSession(request, { ...deps, Parse: ParseGlobal });
    } catch (error) {
      throw mapToParseError(error, ParseGlobal);
    }
  };
}

function mapToParseError(error, ParseGlobal) {
  const body = toClientErrorBody(error);
  const statusCode = isCloudError(error) ? error.statusCode : 500;
  const message = JSON.stringify(body);

  if (ParseGlobal && ParseGlobal.Error) {
    return new ParseGlobal.Error(statusCode, message);
  }

  const fallback = new Error(message);
  fallback.code = body.code;
  fallback.statusCode = statusCode;
  return fallback;
}

module.exports = {
  exchangeSession,
  createExchangeSessionHandler,
  mapToParseError,
  validateIdToken,
};
