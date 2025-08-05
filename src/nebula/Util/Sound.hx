package nebula.Util;

import nebula.Util.Log;

/**
 * Whether or not the browser can play this file as HTML5 Audio
 */
function canPlayFile(file: String): Bool {
  try {
    final a = new Audio();
    final filetype = /.*\.([A-Za-z0-9]+)(?:(?:\?|\#).*)*$/;
    final type = file.match(filetype)[1];
    if (a.canPlayType('audio/' + type)) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    Logger.getInstance().warn('Cannot determine audio support, assuming no support for the Audio Tag', e);
    return false;
  }
}
