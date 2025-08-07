package nebula.util;

import nebula.util.Log;

class IFrame {
  /**
   * Checks if excalibur is in a x-origin iframe
   */
  public static function isCrossOriginIframe() {
    try {
      // Try and listen to events on top window frame if within an iframe.
      //
      // See https://github.com/excaliburjs/Excalibur/issues/1294
      //
      // Attempt to add an event listener, which triggers a DOMException on
      // cross-origin iframes
      final noop = () -> {
        return;
      };
      window.top.addEventListener('blur', noop);
      window.top.removeEventListener('blur', noop);
    } catch (e: Any) {
      return true;
    }
    return false;
  }

  public static function isIframe() {
    return window != window.top;
  }

  /**
   * Grabs the default global object for Excalibur
   */
  public static function getDefaultGlobal(): GlobalEventHandlers {
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
}
