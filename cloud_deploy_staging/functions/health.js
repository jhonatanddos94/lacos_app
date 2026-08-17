'use strict';

const { loadConfig } = require('../config');
const { createLogger } = require('../shared/logging');

const logger = createLogger('functions.health');

/**
 * Readiness-style health payload for ops checks.
 * Does not touch Firebase, Master Key, or business data.
 *
 * @param {object} [_request] Parse Cloud request (unused)
 * @returns {Promise<object>}
 */
async function health(_request) {
  const config = loadConfig();
  logger.info('health');

  return {
    status: config.constants.HEALTH_STATUS.OK,
    service: config.constants.APP_NAME,
    environment: config.environment,
    securityMode: config.featureFlags.securityMode,
    apiContractVersion: config.constants.API_CONTRACT_VERSION,
    timestamp: new Date().toISOString(),
    checks: {
      config: 'ok',
    },
  };
}

module.exports = {
  health,
};
