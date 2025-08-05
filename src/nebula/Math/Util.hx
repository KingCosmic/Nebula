package nebula.Math;

import nebula.Math.Random;

/**
 * Two PI constant
 */
final TwoPI: Float = Math.PI * 2;

/**
 * Returns the fractional part of a number
 * @param x
 */
function frac(x: Int): Int {
  if (x >= 0) {
    return x - Math.floor(x);
  } else {
    return x - Math.ceil(x);
  }
}

/**
 * Returns the sign of a number, if 0 returns 0
 */
function sign(val: Float): Int {
  if (val === 0) {
    return 0;
  }
  return val < 0 ? -1 : 1;
}

/**
 * Clamps a value between a min and max inclusive
 */
function clamp(val: Float, min: Int, max: Int) {
  return Math.min(Math.max(min, val), max);
}

/**
 * Approximately equals
 */
function approximatelyEqual(val1: Float, val2: Float, tolerance: Float) {
  // https://dev.to/alldanielscott/how-to-compare-numbers-correctly-in-javascript-1l4i
  return Math.abs(val1 - val2) < tolerance;
}

/**
 * Convert an angle to be the equivalent in the range [0, 2PI)
 */
export function canonicalizeAngle(angle: Float): Float {
  var tmpAngle = angle;
  if (angle >= TwoPI) {
    while (tmpAngle >= TwoPI) {
      tmpAngle -= TwoPI;
    }
  }

  if (angle < 0) {
    while (tmpAngle < 0) {
      tmpAngle += TwoPI;
    }
  }
  return tmpAngle;
}

/**
 * Convert radians to degrees
 */
function toDegrees(radians: Float): Float {
  return (180 / Math.PI) * radians;
}

/**
 * Convert degrees to radians
 */
function toRadians(degrees: Float): Float {
  return (degrees / 180) * Math.PI;
}

/**
 * Generate a range of numbers
 * For example: range(0, 5) -> [0, 1, 2, 3, 4, 5]
 * @param from inclusive
 * @param to inclusive
 */
final range = (from: Int, to: Int) => Array.from(new Array(to - from + 1), (_x, i) => i + from);

/**
 * Find a random floating point number in range
 */
function randomInRange(min: Float, max: Float, random: Random = new Random()): Float {
  return random ? random.floating(min, max) : min + Math.random() * (max - min);
}

/**
 * Find a random integer in a range
 */
function randomIntInRange(min: Float, max: Float, random: Random = new Random()): Float {
  return random ? random.integer(min, max) : Math.round(randomInRange(min, max));
}
