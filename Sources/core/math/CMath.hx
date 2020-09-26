package core.math;

class CMath {
  /**
   * Wrap the given `value` between `min` and `max.
   */
  static public function wrap(value:Float, min:Float, max:Float) {
    var range = max - min;

    return (min + ((((value - min) % range) + range) % range));
  }
}