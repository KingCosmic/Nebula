package core.math;

class CMath {
  /**
   * Wrap the given `value` between `min` and `max.
   */
  static public function wrap(value:Float, min:Float, max:Float) {
    var range = max - min;

    return (min + ((((value - min) % range) + range) % range));
  }

	/**
	 * Force a value within the boundaries by clamping it to the range `min`, `max`.
	 */
	public static function clamp(value, min, max) {
		return Math.max(min, Math.min(max, value));
	}
}