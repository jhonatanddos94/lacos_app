'use strict';

/**
 * Non-secret constants shared across Cloud Code modules.
 */
module.exports = Object.freeze({
  APP_NAME: 'lacos-cloud',
  API_CONTRACT_VERSION: 1,
  HEALTH_STATUS: Object.freeze({
    OK: 'ok',
    DEGRADED: 'degraded',
  }),
  /** Max accepted Firebase ID Token length (chars). */
  MAX_ID_TOKEN_LENGTH: 16 * 1024,
  /** Parse User field linking to Firebase UID. */
  FIREBASE_UID_FIELD: 'firebaseUid',
});
