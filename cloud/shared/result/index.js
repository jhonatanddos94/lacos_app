'use strict';

/**
 * Minimal Result helpers for future service layers.
 */
function ok(value) {
  return Object.freeze({ ok: true, value });
}

function err(error) {
  return Object.freeze({ ok: false, error });
}

module.exports = {
  ok,
  err,
};
