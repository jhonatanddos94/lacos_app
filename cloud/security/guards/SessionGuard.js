'use strict';

const { CloudError, ErrorCodes } = require('../../shared/errors');

/**
 * Skeleton: will validate Parse session / caller identity in later sprints.
 */
class SessionGuard {
  assert() {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'SessionGuard is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  SessionGuard,
};
