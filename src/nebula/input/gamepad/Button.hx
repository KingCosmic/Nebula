package nebula.input.gamepad;

/**
 * Contains information about a specific button on a Gamepad.
 * Button objects are created automatically by the Gamepad as they are needed.
 */
class Button {
  /**
   * A reference to the Pad this Button belongs to.
   */
  public var pad:Pad;

  /**
	 * An event emitter to use to emit the button events.
   */
  public var events:EventEmitter;

  /**
   * The index of this button.
   */
  public var index:Int;

  /**
   * How pressed is this button? between 0 and 1.
   */
  public var value:Float = 0;

  /**
   * Can be set for analogue buttons to enable a 'pressure' threshold,
   * before a button is considered as being 'pressed'.
   */
  public var threshold:Float = 1;

  /**
   * Is this button pressed down or not?
   */
  public var pressed:Bool = false;

  public function new(_pad:Pad, _index:Int) {
    pad = _pad;
    index = _index;
  }

  /**
	 * Destroys this Button instance and releases external references it holds.
   */
  public function destroy() {
    pad = null;
    events = null;
  }
}
