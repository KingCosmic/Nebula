package nebula.Math;

import nebula.Interfaces.Clonable;
import nebula.Math.RotationType;
import nebula.Math.Util;

/**
 * A 2D vector on a plane.
 */

class Vector implements Clonable<Vector> {
  /**
   * Get or set the vector equals epsilon, by default 0.001 meaning vectors within that tolerance on x or y will be considered equal.
   */
  public static EQUALS_EPSILON = 0.001;
  /**
   * A (0, 0) vector
   */
  public static get Zero() {
    return new Vector(0, 0);
  }

  /**
   * A (1, 1) vector
   */
  public static get One() {
    return new Vector(1, 1);
  }

  /**
   * A (0.5, 0.5) vector
   */
  public static get Half() {
    return new Vector(0.5, 0.5);
  }

  /**
   * A unit vector pointing up (0, -1)
   */
  public static get Up() {
    return new Vector(0, -1);
  }

  /**
   * A unit vector pointing down (0, 1)
   */
  public static get Down() {
    return new Vector(0, 1);
  }

  /**
   * A unit vector pointing left (-1, 0)
   */
  public static get Left() {
    return new Vector(-1, 0);
  }
  /**
   * A unit vector pointing right (1, 0)
   */
  public static get Right() {
    return new Vector(1, 0);
  }

  /**
   * Returns a vector of unit length in the direction of the specified angle in Radians.
   * @param angle The angle to generate the vector
   */
  public static fromAngle(angle: Float) {
    return new Vector(Math.cos(angle), Math.sin(angle));
  }

  /**
   * Checks if vector is not null, undefined, or if any of its components are NaN or Infinity.
   */
  public static isValid(vec: Vector) {
    if (vec === null || vec === undefined) {
      return false;
    }
    if (isNaN(vec.x) || isNaN(vec.y)) {
      return false;
    }

    if (vec.x === Infinity || vec.y === Infinity || vec.x === -Infinity || vec.y === -Infinity) {
      return false;
    }

    return true;
  }

  /**
   * Calculates distance between two Vectors
   * @param vec1
   * @param vec2
   */
  public static distance(vec1: Vector, vec2: Vector) {
    return Math.sqrt(Math.pow(vec1.x - vec2.x, 2) + Math.pow(vec1.y - vec2.y, 2));
  }

  public static min(vec1: Vector, vec2: Vector) {
    return new Vector(Math.min(vec1.x, vec2.x), Math.min(vec1.y, vec2.y));
  }

  public static max(vec1: Vector, vec2: Vector) {
    return new Vector(Math.max(vec1.x, vec2.x), Math.max(vec1.y, vec2.y));
  }

  /**
   * @param x  X component of the Vector
   * @param y  Y component of the Vector
   */
  public function new(x: Int, y: Int) {
    this._x = x;
    this._y = y;
  }

  protected _x = 0;
  /**
   * Get the x component of the vector
   */
  public get x(): Int {
    return this._x;
  }

  /**
   * Set the x component, THIS MUTATES the current vector. It is usually better to create a new vector.
   * @warning **Be very careful setting components on shared vectors, mutating shared vectors can cause hard to find bugs**
   */
  public set x(val: Int) {
    this._x = val;
  }

  protected _y = 0;
  /**
   * Get the y component of the vector
   */
  public get y(): Int {
    return this._y;
  }

  /**
   * Set the y component, THIS MUTATES the current vector. It is usually better to create a new vector.
   * @warning **Be very careful setting components on shared vectors, mutating shared vectors can cause hard to find bugs**
   */
  public set y(val: Int) {
    this._y = val;
  }

  /**
   * Sets the x and y components at once, THIS MUTATES the current vector. It is usually better to create a new vector.
   * @warning **Be very careful using this, mutating vectors can cause hard to find bugs**
   */
  setTo(x: Int, y: Int) {
    (this.x as Int) = x;
    (this.y as Int) = y;
  }

  /**
   * Compares this point against another and tests for equality
   * @param vector The other point to compare to
   * @param tolerance Amount of euclidean distance off we are willing to tolerate
   */
  public equals(vector: Vector, tolerance: Float = Vector.EQUALS_EPSILON): Bool {
    return Math.abs(this.x - vector.x) <= tolerance && Math.abs(this.y - vector.y) <= tolerance;
  }

  /**
   * The distance to another vector. If no other Vector is specified, this will return the {@apilink magnitude}.
   * @param v  The other vector. Leave blank to use origin vector.
   */
  public distance(v?: Vector): Float {
    if (!v) {
      return Math.sqrt(this.x * this.x + this.y * this.y);
    }
    final deltaX = this.x - v.x;
    final deltaY = this.y - v.y;
    return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  public squareDistance(v?: Vector): Float {
    if (!v) {
      v = Vector.Zero;
    }
    final deltaX = this.x - v.x;
    final deltaY = this.y - v.y;
    return deltaX * deltaX + deltaY * deltaY;
  }

  /**
   * Clamps the current vector's magnitude mutating it
   * @param magnitude
   */
  public clampMagnitude(magnitude: Float): Vector {
    final size = this.magnitude;
    final newSize = clamp(size, 0, magnitude);
    this.magnitude = newSize;
    return this;
  }

  /**
   * The size (magnitude) of the Vector
   * @deprecated Will be removed in v1, use Vector.magnitude
   */
  public get size(): Float {
    return this.distance();
  }

  /**
   * Setting the size mutates the current vector
   * @warning Can be used to set the size of the vector, **be very careful using this, mutating vectors can cause hard to find bugs**
   * @deprecated Will be removed in v1, use Vector.magnitude
   */
  public set size(newLength: Float) {
    const v = this.normalize().scale(newLength);
    this.setTo(v.x, v.y);
  }

  /**
   * The magnitude (length) of the Vector
   */
  public get magnitude(): Float {
    return this.distance();
  }

  /**
   * Setting the size mutates the current vector
   * @warning Can be used to set the size of the vector, **be very careful using this, mutating vectors can cause hard to find bugs**
   */
  public set magnitude(newMagnitude: Float) {
    this.normalize().scale(newMagnitude, this);
  }

  /**
   * Normalizes a non-zero vector to have a magnitude of 1. Zero vectors return a new zero vector.
   */
  public normalize(): Vector {
    final distance = this.distance();
    if (distance === 0) {
      return Vector.Zero;
    }

    return new Vector(this.x / distance, this.y / distance);
  }

  /**
   * Returns the average (midpoint) between the current point and the specified
   */
  public average(vec: Vector): Vector {
    return this.add(vec).scale(0.5);
  }

  /**
   * Scales a vector's by a factor of size
   * @param size  The factor to scale the magnitude by
   * @param dest  Optionally provide a destination vector for the result
   */
  public scale(scale: Vector, dest?: Vector): Vector;
  public scale(size: Float, dest?: Vector): Vector;
  public scale(sizeOrScale: Float | Vector, dest?: Vector): Vector {
    final result = dest || new Vector(0, 0);
    if (sizeOrScale instanceof Vector) {
      result.x = this.x * sizeOrScale.x;
      result.y = this.y * sizeOrScale.y;
    } else {
      result.x = this.x * sizeOrScale;
      result.y = this.y * sizeOrScale;
    }
    return result;
  }

  /**
   * Adds one vector to another
   * @param v The vector to add
   * @param dest Optionally copy the result into a provided vector
   */
  public add(v: Vector, dest?: Vector): Vector {
    if (dest) {
      dest.x = this.x + v.x;
      dest.y = this.y + v.y;
      return dest;
    }
    return new Vector(this.x + v.x, this.y + v.y);
  }

  /**
   * Subtracts a vector from another, if you subtract vector `B.sub(A)` the resulting vector points from A -> B
   * @param v The vector to subtract
   */
  public sub(v: Vector, dest?: Vector): Vector {
    final result = dest || new Vector(0, 0);
    final x = this.x - v.x;
    final y = this.y - v.y;
    result.x = x;
    result.y = y;
    return result;
  }

  /**
   * Adds one vector to this one modifying the original
   * @param v The vector to add
   * @warning Be very careful using this, mutating vectors can cause hard to find bugs
   */
  public addEqual(v: Vector): Vector {
    this.setTo(this.x + v.x, this.y + v.y);
    return this;
  }

  /**
   * Subtracts a vector from this one modifying the original
   * @param v The vector to subtract
   * @warning Be very careful using this, mutating vectors can cause hard to find bugs
   */
  public subEqual(v: Vector): Vector {
    this.setTo(this.x - v.x, this.y - v.y);
    return this;
  }

  /**
   * Scales this vector by a factor of size and modifies the original
   * @warning Be very careful using this, mutating vectors can cause hard to find bugs
   */
  public scaleEqual(size: Float): Vector {
    this.setTo(this.x * size, this.y * size);
    return this;
  }

  /**
   * Performs a dot product with another vector
   * @param v  The vector to dot
   */
  public dot(v: Vector): Float {
    return this.x * v.x + this.y * v.y;
  }

  /**
   * Performs a 2D cross product with scalar. 2D cross products with a scalar return a vector.
   * @param v  The scalar to cross
   */
  public cross(v: Float): Vector;
  /**
   * Performs a 2D cross product with another vector. 2D cross products return a scalar value not a vector.
   * @param v  The vector to cross
   */
  public cross(v: Vector): Float;
  public cross(v: any): any {
    if (v instanceof Vector) {
      return this.x * v.y - this.y * v.x;
    } else if (typeof v === 'number') {
      return new Vector(v * this.y, -v * this.x);
    }
  }

  static cross(num: Float, vec: Vector): Vector {
    return new Vector(-num * vec.y, num * vec.x);
  }

  /**
   * Returns the perpendicular vector to this one
   */
  public perpendicular(): Vector {
    return new Vector(this.y, -this.x);
  }

  /**
   * Returns the normal vector to this one, same as the perpendicular of length 1
   */
  public normal(): Vector {
    return this.perpendicular().normalize();
  }

  /**
   * Negate the current vector
   */
  public negate(): Vector {
    return this.scale(-1);
  }

  /**
   * Returns the angle of this vector, in range [0, 2*PI)
   */
  public toAngle(): Float {
    return canonicalizeAngle(Math.atan2(this.y, this.x));
  }

  /**
   * Returns the difference in radians between the angle of this vector and given angle,
   * using the given rotation type.
   * @param angle in radians to which the vector has to be rotated, using {@apilink rotate}
   * @param rotationType what {@apilink RotationType} to use for the rotation
   * @returns the angle by which the vector needs to be rotated to match the given angle
   */
  public angleBetween(angle: Float, rotationType: RotationType): Float {
    final startAngleRadians = this.toAngle();
    final endAngleRadians = canonicalizeAngle(angle);
    var rotationClockwise = 0;
    var rotationAntiClockwise = 0;
    if (endAngleRadians > startAngleRadians) {
      rotationClockwise = endAngleRadians - startAngleRadians;
    } else {
      rotationClockwise = (TwoPI - startAngleRadians + endAngleRadians) % TwoPI;
    }
    rotationAntiClockwise = (rotationClockwise - TwoPI) % TwoPI;
    switch (rotationType) {
      case RotationType.ShortestPath:
        if (Math.abs(rotationClockwise) < Math.abs(rotationAntiClockwise)) {
          return rotationClockwise;
        } else {
          return rotationAntiClockwise;
        }
      case RotationType.LongestPath:
        if (Math.abs(rotationClockwise) > Math.abs(rotationAntiClockwise)) {
          return rotationClockwise;
        } else {
          return rotationAntiClockwise;
        }
      case RotationType.Clockwise:
        return rotationClockwise;
      case RotationType.CounterClockwise:
        return rotationAntiClockwise;
    }
  }

  /**
   * Rotates the current vector around a point by a certain angle in radians.
   * Positive angle means rotation clockwise.
   */
  public rotate(angle: Float, anchor?: Vector, dest?: Vector): Vector {
    final result = dest || new Vector(0, 0);
    if (!anchor) {
      anchor = new Vector(0, 0);
    }
    final sinAngle = Math.sin(angle);
    final cosAngle = Math.cos(angle);
    final x = cosAngle * (this.x - anchor.x) - sinAngle * (this.y - anchor.y) + anchor.x;
    final y = sinAngle * (this.x - anchor.x) + cosAngle * (this.y - anchor.y) + anchor.y;
    result.x = x;
    result.y = y;
    return result;
  }

  /**
   * Creates new vector that has the same values as the previous.
   */
  public clone(dest?: Vector): Vector {
    final v = dest ?? new Vector(0, 0);
    v.x = this.x;
    v.y = this.y;
    return v;
  }

  /**
   * Returns a string representation of the vector.
   */
  public toString(fixed?: Vector): String {
    if (fixed) {
      return `(${this.x.toFixed(fixed)}, ${this.y.toFixed(fixed)})`;
    }
    return `(${this.x}, ${this.y})`;
  }
}

/**
 * Shorthand for creating new Vectors - returns a new Vector instance with the
 * provided X and Y components.
 * @param x  X component of the Vector
 * @param y  Y component of the Vector
 */
function vec(x: Int, y: Int): Vector {
  return new Vector(x, y);
}
