package core.math;

class MATH_CONST {

  // The value of PI * 2
  static public var PI2 = Math.PI * 2;

  // The value of PI * 0.5
  static public var TAU = Math.PI * 0.5;

  // An epsilon value (1.0e+6)
  static public var EPSILON = 1.0e+6;

  // For converting degrees to radians (PI / 180)
  static public var DEG_TO_RAD = Math.PI / 180;

  // For converting radians to degrees (180 / PI)
  static public var RAD_TO_DEG = 180 / Math.PI;

  /**
   * The minimum safe integer this browser supports.
   * We use a const for backward compatibility with Internet Explorer.
   */
  static public var MIN = -9007199254740991;
  
	/**
	 * The minimum safe integer this browser supports.
	 * We use a const for backward compatibility with Internet Explorer.
   */
	static public var MAX_SAFE_INTERGER = 9007199254740991;
}