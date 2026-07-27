'use strict';

const { CloudError, ErrorCodes } = require('../../shared/errors');

/**
 * Skeleton: will enforce Parse Role membership in later sprints.
 */
class RoleGuard {
  assert() {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'RoleGuard is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  RoleGuard,
};
