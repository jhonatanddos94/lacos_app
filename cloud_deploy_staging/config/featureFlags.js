'use strict';

const { readEnv } = require('./environment');

const SECURITY_MODES = Object.freeze({
  PERMISSIVE: 'permissive',
  ENFORCING: 'enforcing',
});

/**
 * Feature flags driven by environment variables.
 * Business rules are not evaluated here — only configuration resolution.
 */
function resolveFeatureFlags() {
  const securityMode = readEnv(
    'LACOS_SECURITY_MODE',
    SECURITY_MODES.PERMISSIVE,
  ).toLowerCase();

  return Object.freeze({
    securityMode:
      securityMode === SECURITY_MODES.ENFORCING
        ? SECURITY_MODES.ENFORCING
        : SECURITY_MODES.PERMISSIVE,
  });
}

module.exports = {
  SECURITY_MODES,
  resolveFeatureFlags,
};
