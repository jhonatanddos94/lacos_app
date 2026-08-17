'use strict';

const { loadConfig } = require('../config');
const { createLogger } = require('../shared/logging');

const logger = createLogger('functions.ping');

/**
 * Liveness probe for Cloud Code registration and deploy smoke tests.
 * No authentication and no business logic.
 *
 * @param {object} [_request] Parse Cloud request (unused)
 * @returns {Promise<object>}
 */
async function ping(_request) {
  const config = loadConfig();
  logger.info('ping');

  return {
    status: 'ok',
    service: config.constants.APP_NAME,
    apiContractVersion: config.constants.API_CONTRACT_VERSION,
    timestamp: new Date().toISOString(),
  };
}

module.exports = {
  ping,
};
