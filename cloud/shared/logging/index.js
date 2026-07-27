'use strict';

/**
 * Structured logging without secrets (no tokens, passwords, or raw credentials).
 */
function createLogger(scope) {
  function write(level, message, fields = {}) {
    const entry = {
      level,
      scope,
      message,
      timestamp: new Date().toISOString(),
      ...fields,
    };
    const line = JSON.stringify(entry);
    if (level === 'error') {
      console.error(line);
      return;
    }
    if (level === 'warn') {
      console.warn(line);
      return;
    }
    console.log(line);
  }

  return {
    info: (message, fields) => write('info', message, fields),
    warn: (message, fields) => write('warn', message, fields),
    error: (message, fields) => write('error', message, fields),
  };
}

module.exports = {
  createLogger,
};
