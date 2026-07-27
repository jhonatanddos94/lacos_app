'use strict';

function maskUid(uid) {
  if (typeof uid !== 'string' || uid.length < 8) {
    return '[uid]';
  }
  return `${uid.slice(0, 4)}…${uid.slice(-4)}`;
}

module.exports = {
  isNonEmptyString: (value) => typeof value === 'string' && value.trim().length > 0,
  maskUid,
};
