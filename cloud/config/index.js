'use strict';

const { resolveEnvironment } = require('./environment');
const { resolveFeatureFlags } = require('./featureFlags');
const constants = require('./constants');
const firebaseConfig = require('./firebase');

function loadConfig() {
  return Object.freeze({
    environment: resolveEnvironment(),
    featureFlags: resolveFeatureFlags(),
    constants,
  });
}

module.exports = {
  loadConfig,
  resolveEnvironment,
  resolveFeatureFlags,
  constants,
  firebaseConfig,
};
