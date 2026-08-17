'use strict';

const { ping } = require('./ping');
const { health } = require('./health');
const { createExchangeSessionHandler } = require('./exchangeSession');

/**
 * Registers Cloud Functions on the Parse runtime.
 * @param {object} ParseGlobal - Parse SDK global provided by Cloud Code host
 */
function registerFunctions(ParseGlobal) {
  ParseGlobal.Cloud.define('ping', ping);
  ParseGlobal.Cloud.define('health', health);
  ParseGlobal.Cloud.define(
    'exchangeSession',
    createExchangeSessionHandler(() => ({ Parse: ParseGlobal })),
  );
}

module.exports = {
  registerFunctions,
  ping,
  health,
};
