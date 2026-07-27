'use strict';

const crypto = require('crypto');

const { constants } = require('../config');
const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Maps Firebase identity to exactly one Parse _User.
 * Prefer `firebaseUid`; fall back to legacy username === Firebase UID.
 */
class ParseUserService {
  /**
   * @param {object} [options]
   * @param {object} [options.Parse] Parse SDK global
   * @param {() => string} [options.generatePassword]
   */
  constructor(options = {}) {
    this._Parse = options.Parse || null;
    this._generatePassword =
      options.generatePassword || defaultGeneratePassword;
  }

  setParse(ParseGlobal) {
    this._Parse = ParseGlobal;
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

  /**
   * @param {{ uid: string, email: string|null }} identity
   * @returns {Promise<{ user: object, isNewUser: boolean }>}
   */
  async findOrCreateFromFirebaseIdentity(identity) {
    if (!identity || typeof identity.uid !== 'string' || !identity.uid) {
      throw new CloudError(
        ErrorCodes.VALIDATION,
        'Invalid Firebase identity.',
        { statusCode: 400 },
      );
    }

    const existing = await this._findLinkedUser(identity.uid);
    if (existing) {
      const migrated = await this._ensureFirebaseUidLink(existing, identity);
      return { user: migrated, isNewUser: false };
    }

    try {
      const created = await this._createUser(identity);
      return { user: created, isNewUser: true };
    } catch (error) {
      if (this._isUsernameTakenError(error)) {
        const raced = await this._findLinkedUser(identity.uid);
        if (raced) {
          const migrated = await this._ensureFirebaseUidLink(raced, identity);
          return { user: migrated, isNewUser: false };
        }
      }

      if (error instanceof CloudError) {
        throw error;
      }

      throw new CloudError(
        ErrorCodes.TEMPORARY,
        'Unable to prepare user account.',
        { statusCode: 503 },
      );
    }
  }

  async _findLinkedUser(firebaseUid) {
    const Parse = this._requireParse();
    const field = constants.FIREBASE_UID_FIELD;

    const byFirebaseUid = await new Parse.Query(Parse.User)
      .equalTo(field, firebaseUid)
      .first({ useMasterKey: true });

    const byUsername = await new Parse.Query(Parse.User)
      .equalTo('username', firebaseUid)
      .first({ useMasterKey: true });

    if (
      byFirebaseUid &&
      byUsername &&
      byFirebaseUid.id !== byUsername.id
    ) {
      throw new CloudError(
        ErrorCodes.CONFLICT,
        'User identity mapping is ambiguous.',
        { statusCode: 409 },
      );
    }

    return byFirebaseUid || byUsername || null;
  }

  async _ensureFirebaseUidLink(user, identity) {
    this._requireParse();
    const field = constants.FIREBASE_UID_FIELD;
    const currentLink = user.get(field);

    if (currentLink && currentLink !== identity.uid) {
      throw new CloudError(
        ErrorCodes.CONFLICT,
        'User identity mapping is ambiguous.',
        { statusCode: 409 },
      );
    }

    let dirty = false;

    if (!currentLink) {
      user.set(field, identity.uid);
      dirty = true;
    }

    if (identity.email && user.get('email') !== identity.email) {
      user.set('email', identity.email);
      dirty = true;
    }

    if (!dirty) {
      return user;
    }

    try {
      await user.save(null, { useMasterKey: true });
      return user;
    } catch (_error) {
      throw new CloudError(
        ErrorCodes.TEMPORARY,
        'Unable to prepare user account.',
        { statusCode: 503 },
      );
    }
  }

  async _createUser(identity) {
    const Parse = this._requireParse();
    const user = new Parse.User();
    const password = this._generatePassword();

    user.set('username', identity.uid);
    user.set(constants.FIREBASE_UID_FIELD, identity.uid);
    user.set('password', password);

    if (identity.email) {
      user.set('email', identity.email);
    }

    await user.signUp(null, { useMasterKey: true });
    return user;
  }

  _isUsernameTakenError(error) {
    if (!error) {
      return false;
    }
    if (error.code === 202 || error.code === 137) {
      return true;
    }
    const message = String(error.message || '').toLowerCase();
    return (
      message.includes('already taken') ||
      message.includes('already exists') ||
      message.includes('duplicate')
    );
  }
}

function defaultGeneratePassword() {
  return crypto.randomBytes(32).toString('base64url');
}

module.exports = {
  ParseUserService,
  defaultGeneratePassword,
};
