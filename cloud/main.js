'use strict';

/**
 * Cloud Code entrypoint for Back4App / Parse Server.
 * Registers functions, triggers, and jobs. Contains no business logic.
 */

const { createLogger } = require('./shared/logging');
const { loadConfig } = require('./config');
const { registerFunctions } = require('./functions');
const { registerTriggers } = require('./triggers');
const { registerJobs } = require('./jobs');

const logger = createLogger('main');

function bootstrap(ParseGlobal) {
  if (!ParseGlobal || !ParseGlobal.Cloud) {
    throw new Error('Parse Cloud runtime is not available');
  }

  const config = loadConfig();
  logger.info('bootstrapping cloud code', {
    environment: config.environment,
    securityMode: config.featureFlags.securityMode,
  });

  registerFunctions(ParseGlobal);
  registerTriggers(ParseGlobal);
  registerJobs(ParseGlobal);

  logger.info('cloud code ready');
}

if (global.Parse && global.Parse.Cloud) {
  bootstrap(global.Parse);
}

module.exports = {
  bootstrap,
};
