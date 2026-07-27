'use strict';

const { CloudError, ErrorCodes } = require('../shared/errors');

/**
 * Skeleton: Parse Role ensure / membership (T1.3.4).
 */
class RoleService {
  async ensureSalonRoles(_salonId) {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'RoleService.ensureSalonRoles is not implemented yet',
      { statusCode: 501 },
    );
  }

  async addUserToSalonRole(_user, _salonId, _roleKind) {
    throw new CloudError(
      ErrorCodes.NOT_IMPLEMENTED,
      'RoleService.addUserToSalonRole is not implemented yet',
      { statusCode: 501 },
    );
  }
}

module.exports = {
  RoleService,
};
