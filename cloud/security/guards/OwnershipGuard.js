'use strict';

const { CloudError, ErrorCodes } = require('../../shared/errors');

/**
 * Skeleton: will validate object ownership in later sprints.
 */
class OwnershipGuard {
  assert() {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'OwnershipGuard is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  OwnershipGuard,
};
