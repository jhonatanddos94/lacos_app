'use strict';

const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Skeleton: resolve user ↔ professional ↔ salon membership (later sprints).
 */
class MembershipService {
  async resolveActiveSalonIds(_user) {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'MembershipService.resolveActiveSalonIds is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  MembershipService,
};
