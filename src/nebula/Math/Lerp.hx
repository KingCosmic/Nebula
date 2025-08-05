package nebula.Math;

import nebula.Math.RotationType;
import nebula.Math.Util;
import nebula.Math.Vector;

/**
 * Linear interpolation between `a` and `b`, at `time = 0` the value will be `a` at `time = 1` the value will be `b`
 * @param a
 * @param b
 * @param time
 */
function lerp(a: Int, b: Int, time: Int): Int {
  return (1 - time) * a + b * time;
}

/**
 * Linear interpolation between angles in radians
 * @param startAngle
 * @param endAngle
 * @param rotationType
 * @param time
 */
function lerpAngle(startAngle: Float, endAngle: Float, rotationType: RotationType, time: Int): Float {
  final shortestPathIsPositive = (startAngle - endAngle + TwoPI) % TwoPI >= Math.PI;
  final distance1 = Math.abs(endAngle - startAngle);
  final distance2 = TwoPI - distance1;
  var shortDistance = 0;
  var longDistance = 0;
  if (distance1 > distance2) {
    shortDistance = distance2;
    longDistance = distance1;
  } else {
    shortDistance = distance1;
    longDistance = distance2;
  }
  var distance = 0;
  var direction = 1;

  switch (rotationType) {
    case RotationType.ShortestPath:
      distance = shortDistance;
      direction = shortestPathIsPositive ? 1 : -1;
      break;
    case RotationType.LongestPath:
      distance = longDistance;
      direction = shortestPathIsPositive ? -1 : 1;
      break;
    case RotationType.Clockwise:
      direction = 1;
      distance = shortestPathIsPositive ? shortDistance : longDistance;
      break;
    case RotationType.CounterClockwise:
      direction = -1;
      distance = shortestPathIsPositive ? longDistance : shortDistance;
      break;
  }

  return startAngle + direction * (distance * time);
}

/**
 * Linear interpolation between `a` and `b`, at `time = 0` the value will be `a` at `time = 1` the value will be `b`
 * @param a
 * @param b
 * @param time
 */
function lerpVector(a: Vector, b: Vector, time: Int): Vector {
  return a.scale(1 - time).add(b.scale(time));
}

/**
 * Inverse of a linear interpolation, given a `value` in between `a` and `b` return how close to `a` or `b` the `value` is.
 *
 * Example: `a=1`, `b=5`, `value=4` will return `.75`
 * @param a
 * @param b
 * @param value
 */
function inverseLerp(a: Float, b: Float, value: Float): Float {
  return (value - a) / (b - a);
}

/**
 * Inverse of a linear interpolation, given a `value` in between `a` and `b` return how close to `a` or `b` the `value` is.
 *
 * **Warning** assumes that the `value` vector is co-linear with vector `a` and `b`
 *
 * Example: `a=1`, `b=5`, `value=4` will return `.75`
 * @param a
 * @param b
 * @param value
 */
function inverseLerpVector(a: Vector, b: Vector, value: Vector): Float {
  final numerator = value.sub(a);
  final denominator = b.sub(a);
  final x = numerator.x / denominator.x;
  final y = numerator.y / denominator.y;
  return Math.min(x, y);
}

/**
 * Remaps a value from a source domain to a destination
 * @param minSource
 * @param maxSource
 * @param minDestination
 * @param maxDestination
 * @param value
 */
function remap(minSource: Float, maxSource: Float, minDestination: Float, maxDestination: Float, value: Float): Float {
  final time = inverseLerp(minSource, maxSource, value);
  return lerp(minDestination, maxDestination, time);
}

/**
 * Remaps a value from a source domain to a destination
 *
 * **Warning** assumes that the `value` vector is co-linear with vector `minSource` and `maxSource`
 * @param minSource
 * @param maxSource
 * @param minDestination
 * @param maxDestination
 * @param value
 */
function remapVector(minSource: Vector, maxSource: Vector, minDestination: Vector, maxDestination: Vector, value: Vector): Vector {
  final time = inverseLerpVector(minSource, maxSource, value);
  return lerpVector(minDestination, maxDestination, time);
}
