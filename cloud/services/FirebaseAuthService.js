'use strict';

const admin = require('firebase-admin');

const {
  loadFirebaseServiceAccount,
  resolveFirebaseProjectId,
} = require('../config/firebase');
const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Verifies Firebase ID Tokens using Firebase Admin SDK.
 * Credentials come only from environment variables.
 */
class FirebaseAuthService {
  /**
   * @param {object} [options]
   * @param {typeof admin} [options.adminSdk]
   * @param {() => object} [options.loadCredentials]
   * @param {(account: object) => string} [options.resolveProjectId]
   */
  constructor(options = {}) {
    this._admin = options.adminSdk || admin;
    this._loadCredentials = options.loadCredentials || loadFirebaseServiceAccount;
    this._resolveProjectId = options.resolveProjectId || resolveFirebaseProjectId;
    this._initialized = false;
  }

  /**
   * Initializes Firebase Admin once per process.
   */
  ensureInitialized() {
    if (this._initialized) {
      return this._admin.app();
    }

    if (this._admin.apps && this._admin.apps.length > 0) {
      this._initialized = true;
      return this._admin.app();
    }

    const serviceAccount = this._loadCredentials();
    const projectId = this._resolveProjectId(serviceAccount);

    this._admin.initializeApp({
      credential: this._admin.credential.cert(serviceAccount),
      projectId,
    });

    this._initialized = true;
    return this._admin.app();
  }

  /**
   * @param {string} idToken
   * @returns {Promise<{
   *   uid: string,
   *   email: string|null,
   *   emailVerified: boolean,
   *   disabled: boolean|null,
   *   issuedAt: string|null,
   *   expiresAt: string|null,
   * }>}
   */
  async verifyIdToken(idToken) {
    if (typeof idToken !== 'string' || idToken.trim() === '') {
      throw new CloudError(
        ErrorCodes.UNAUTHORIZED,
        'Invalid or expired authentication token.',
        { statusCode: 401 },
      );
    }

    this.ensureInitialized();

    let decoded;
    try {
      decoded = await this._admin.auth().verifyIdToken(idToken, true);
    } catch (error) {
      throw this._mapVerifyError(error);
    }

    let disabled = null;
    try {
      const record = await this._admin.auth().getUser(decoded.uid);
      disabled = Boolean(record.disabled);
    } catch (error) {
      if (error && error.code === 'auth/user-not-found') {
        throw new CloudError(
          ErrorCodes.UNAUTHORIZED,
          'Invalid or expired authentication token.',
          { statusCode: 401 },
        );
      }
      throw new CloudError(
        ErrorCodes.TEMPORARY,
        'Authentication provider temporarily unavailable.',
        { statusCode: 503 },
      );
    }

    if (disabled) {
      throw new CloudError(
        ErrorCodes.UNAUTHORIZED,
        'Invalid or expired authentication token.',
        { statusCode: 401 },
      );
    }

    return {
      uid: decoded.uid,
      email: typeof decoded.email === 'string' ? decoded.email : null,
      emailVerified: Boolean(decoded.email_verified),
      disabled,
      issuedAt: decoded.iat
        ? new Date(decoded.iat * 1000).toISOString()
        : null,
      expiresAt: decoded.exp
        ? new Date(decoded.exp * 1000).toISOString()
        : null,
    };
  }

  _mapVerifyError(error) {
    const code = error && error.code;

    if (
      code === 'auth/id-token-expired' ||
      code === 'auth/argument-error' ||
      code === 'auth/id-token-revoked' ||
      code === 'auth/invalid-id-token' ||
      code === 'auth/user-disabled'
    ) {
      return new CloudError(
        ErrorCodes.UNAUTHORIZED,
        'Invalid or expired authentication token.',
        { statusCode: 401 },
      );
    }

    if (
      code === 'app/invalid-credential' ||
      code === 'app/invalid-app-options'
    ) {
      return new CloudError(
        ErrorCodes.CONFIGURATION_ERROR,
        'Firebase Admin credentials are not configured.',
        { statusCode: 500 },
      );
    }

    return new CloudError(
      ErrorCodes.TEMPORARY,
      'Authentication provider temporarily unavailable.',
      { statusCode: 503 },
    );
  }
}

module.exports = {
  FirebaseAuthService,
};
