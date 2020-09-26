package core.math;

class Angle {
  /**
   * Wrap an angle.
   *
   * Wraps the angle to a value in the range of -PI to PI.
   */
  static public function wrap(angle:Float) {
    return CMath.wrap(angle, -Math.PI, Math.PI);
  }

  /**
   * Wrap an angle in degrees.
   *
   * Wraps the angle to a value in the range of -180 to 180.
   */
  static public function wrapDegrees(angle:Float) {
    return CMath.wrap(angle, -180, 180);
  }
}