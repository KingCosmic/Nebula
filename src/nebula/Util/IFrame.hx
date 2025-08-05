package nebula.Util;

import nebula.Util.Log;

/**
 * Checks if excalibur is in a x-origin iframe
 */
function isCrossOriginIframe() {
  try {
    // Try and listen to events on top window frame if within an iframe.
    //
    // See https://github.com/excaliburjs/Excalibur/issues/1294
    //
    // Attempt to add an event listener, which triggers a DOMException on
    // cross-origin iframes
    final noop = () => {
      return;
    };
    window.top.addEventListener('blur', noop);
    window.top.removeEventListener('blur', noop);
  } catch {
    return true;
  }
  return false;
}

function isIframe() {
  return window !== window.top;
}

/**
 * Grabs the default global object for Excalibur
 */
function getDefaultGlobal(): GlobalEventHandlers {
  var global: GlobalEventHandlers;
  if (isCrossOriginIframe()) {
    global = window;
    Logger.getInstance().warn('Excalibur might be in a cross-origin iframe, in order to receive keyboard events it must be in focus');
  } else if (isIframe()) {
    global = window;
    Logger.getInstance().warn('Excalibur might be in a iframe, in order to receive keyboard events it must be in focus');
  } else if (window.top) {
    global = window.top;
  }

  return global;
}
