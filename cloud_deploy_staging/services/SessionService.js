'use strict';

const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Issues Parse sessions via the official REST endpoint:
 * POST /loginAs?userId=<objectId> with Master Key.
 *
 * Documented by Parse Platform REST Guide ("Logging in as a user").
 * Does not use password login or the legacy derived password.
 *
 * In Cloud Code, Application Id and Master Key come from the Parse runtime
 * (never from Flutter). expiresAt is returned only when present in the
 * /loginAs response (often omitted — see README limitations).
 */
class SessionService {
  /**
   * @param {object} [options]
   * @param {object} [options.Parse]
   * @param {Function} [options.httpRequest] async ({method,url,headers}) => {status, data}
   */
  constructor(options = {}) {
    this._Parse = options.Parse || null;
    this._httpRequest = options.httpRequest || null;
  }

  setParse(ParseGlobal) {
    this._Parse = ParseGlobal;
  }

  /**
   * @param {object} user Parse.User with id
   * @returns {Promise<{ sessionToken: string, parseUserId: string, expiresAt: string|null }>}
   */
  async createSessionForUser(user) {
    if (!user || !user.id) {
      throw new CloudError(
        ErrorCodes.VALIDATION,
        'Invalid user for session creation.',
        { statusCode: 400 },
      );
    }

    const Parse = this._requireParse();
    const httpRequest = this._resolveHttpRequest(Parse);

    if (!Parse.applicationId || !Parse.masterKey || !Parse.serverURL) {
      throw new CloudError(
        ErrorCodes.CONFIGURATION_ERROR,
        'Parse session issuer is not configured.',
        { statusCode: 500 },
      );
    }

    const baseUrl = String(Parse.serverURL).replace(/\/$/, '');
    const url = `${baseUrl}/loginAs?userId=${encodeURIComponent(user.id)}`;

    let response;
    try {
      response = await httpRequest({
        method: 'POST',
        url,
        headers: {
          'X-Parse-Application-Id': Parse.applicationId,
          'X-Parse-Master-Key': Parse.masterKey,
          'X-Parse-Revocable-Session': '1',
          'Content-Type': 'application/json',
        },
      });
    } catch (_error) {
      throw new CloudError(
        ErrorCodes.TEMPORARY,
        'Unable to create session.',
        { statusCode: 503 },
      );
    }

    const status = response.status || response.statusCode;
    const data = normalizeResponseData(response);

    if (status !== 200 || !data || typeof data.sessionToken !== 'string') {
      throw new CloudError(
        ErrorCodes.TEMPORARY,
        'Unable to create session.',
        { statusCode: 503 },
      );
    }

    return {
      sessionToken: data.sessionToken,
      parseUserId: data.objectId || user.id,
      expiresAt: extractExpiresAt(data),
    };
  }

  async revokeSession(_sessionToken) {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'SessionService.revokeSession is not implemented yet',
      { statusCode: 501 },
    );
  }

  _requireParse() {
    if (!this._Parse) {
      throw new CloudError(
        ErrorCodes.CONFIGURATION_ERROR,
        'Parse runtime is not available.',
        { statusCode: 500 },
      );
    }
    return this._Parse;
  }

  _resolveHttpRequest(Parse) {
    if (this._httpRequest) {
      return this._httpRequest;
    }
    if (Parse.Cloud && typeof Parse.Cloud.httpRequest === 'function') {
      return (options) => Parse.Cloud.httpRequest(options);
    }
    throw new CloudError(
      ErrorCodes.CONFIGURATION_ERROR,
      'HTTP client is not available for session issuance.',
      { statusCode: 500 },
    );
  }
}

function normalizeResponseData(response) {
  if (!response) {
    return null;
  }
  if (response.data && typeof response.data === 'object') {
    return response.data;
  }
  if (typeof response.text === 'string' && response.text) {
    try {
      return JSON.parse(response.text);
    } catch (_error) {
      return null;
    }
  }
  return null;
}

function extractExpiresAt(data) {
  if (!data) {
    return null;
  }
  if (typeof data.expiresAt === 'string') {
    return data.expiresAt;
  }
  if (data.expiresAt && typeof data.expiresAt.iso === 'string') {
    return data.expiresAt.iso;
  }
  return null;
}

module.exports = {
  SessionService,
};
