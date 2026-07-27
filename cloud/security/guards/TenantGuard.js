'use strict';

const { CloudError, ErrorCodes } = require('../../shared/errors');

/**
 * Skeleton: will enforce salon tenancy in later sprints.
 */
class TenantGuard {
  assert() {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'TenantGuard is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  TenantGuard,
};
