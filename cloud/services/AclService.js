'use strict';

const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Skeleton: object ACL helpers (T1.4).
 */
class AclService {
  async applySalonRoleAcl(_object, _salonId) {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'AclService.applySalonRoleAcl is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  AclService,
};
