package nebula.input.gamepad;

import kha.math.Vector2;

/**
 * Contains information about a specific Gamepad Axis.
 * Axis objects are created automatically by the Gamepad as they are needed.
 */
class Joystick {
  /**
   * A reference to the Gamepad that this Axis belongs to.
   */
  public var pad:Pad;

  /**
	 * An event emitter to use to emit the axis events.
   */
  public var events:EventEmitter;

  /**
   * The Vector2 holding this Joysticks x and y axis values.
   */
  public var value:Vector2 = new Vector2();

  /**
   * The x axis value, between -1 and 1 with 0 being dead center.
   * Use the method `getX` to get a normalized value with the threshold applied.
   */
  public var x(get, set):Float;

  function get_x() {
    return value.x;
  }

  function set_x(v:Float) {
    value.x = v;

    return v;
  }

	/**
	 * The y axis value, between -1 and 1 with 0 being dead center.
	 * Use the method `getY` to get a normalized value with the threshold applied.
	 */
	public var y(get, set):Float;

	function get_y() {
		return value.y;
	}

	function set_y(v:Float) {
		value.y = v;

		return v;
  }

  /**
   * Movement tolerance threshold below which axis values are ignored in `getValue`.
   */
  public var threshold:Vector2 = new Vector2(0.1, 0.1);

  /**
   * Is this joystick pressed?
   */
  public var pressed:Bool = false;

  public function new(_pad:Pad) {
    
    pad = _pad;
    events = new EventEmitter();
  }

	/**
   * Applies the `threshold` value to the x axis and returns it.
   */
  public function getX() {
		return (Math.abs(x) < threshold.x) ? 0 : x;
  }

  /**
   * Applies the `threshold` value to the y axis and returns it.
   */
  public function getY() {
    return (Math.abs(y) < threshold.y) ? 0 : y;
  }

  /**
   * Destroys this Axis instance and releases external references it holds.
   */
  public function destroy() {
    pad = null;
    events = null;
  }
}