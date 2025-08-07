package nebula.input;

/**
 * Turn on move and drag events for an {@apilink Actor}
 */

interface CapturePointerConfig {
  /**
   * Capture PointerMove events (may be expensive!)
   */
  var captureMoveEvents: Bool;

  /**
   * Capture PointerDrag events (may be expensive!)
   */
  var captureDragEvents: Bool;
}
