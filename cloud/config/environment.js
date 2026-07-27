'use strict';

/**
 * Reads process environment. Secrets must never be hardcoded.
 */
function readEnv(name, fallback = undefined) {
  const value = process.env[name];
  if (value === undefined || value === '') {
    return fallback;
  }
  return value;
}

const KNOWN_ENVIRONMENTS = Object.freeze(['development', 'staging', 'production']);

function resolveEnvironment() {
  const raw = readEnv('LACOS_ENV', 'development').toLowerCase();
  if (!KNOWN_ENVIRONMENTS.includes(raw)) {
    return 'development';
  }
  return raw;
}

module.exports = {
  readEnv,
  resolveEnvironment,
  KNOWN_ENVIRONMENTS,
};
