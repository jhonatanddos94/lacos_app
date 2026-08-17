'use strict';

const {
  createProfessionalWorkingHoursBeforeSave,
} = require('./beforeSave/professionalWorkingHours');

/**
 * Trigger registration hub.
 * T1.S1: ProfessionalWorkingHours beforeSave only.
 *
 * @param {object} ParseGlobal
 */
function registerTriggers(ParseGlobal) {
  ParseGlobal.Cloud.beforeSave(
    'ProfessionalWorkingHours',
    createProfessionalWorkingHoursBeforeSave(ParseGlobal),
  );
}

module.exports = {
  registerTriggers,
};
