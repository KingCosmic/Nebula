package nebula.math;

import nebula.math.AffineMatrix;
import nebula.math.Vector;

/**
 * A 2D line segment
 */

class LineSegment {
  /**
   * @param begin  The starting point of the line segment
   * @param end  The ending point of the line segment
   */
  public function new(
    begin: Vector,
    end: Vector
  ) {}

  function clone(?dest: LineSegment): LineSegment {
    final result = dest || new LineSegment(this.begin.clone(), this.end.clone());
    result.begin = this.begin.clone(result.begin);
    result.end = this.end.clone(result.end);
    return result;
  }

  function transform(matrix: AffineMatrix, ?dest: LineSegment): LineSegment {
    final result = dest || new LineSegment(Vector.Zero, Vector.Zero);
    result.begin = matrix.multiply(this.begin, result.begin);
    result.end = matrix.multiply(this.end, result.end);
    return result;
  }

  /**
   * Gets the raw slope (m) of the line. Will return (+/-)Infinity for vertical lines.
   */
  public var slope(get, never): Float;
  function get_slope() {
    return (this.end.y - this.begin.y) / (this.end.x - this.begin.x);
  }

  /**
   * Gets the Y-intercept (b) of the line. Will return (+/-)Infinity if there is no intercept.
   */
  public var intercept(get, never): Float;
  function get_intercept() {
    return this.begin.y - this.slope * this.begin.x;
  }

  private var _normal: Vector;
  /**
   * Gets the normal of the line
   */
  public function normal(): Vector {
    if (this._normal) {
      return this._normal;
    }
    return (this._normal = this.end.sub(this.begin).normal());
  }

  private var _dir: Vector;
  public function dir(): Vector {
    if (this._dir) {
      return this._dir;
    }
    return (this._dir = this.end.sub(this.begin));
  }

  public function getPoints(): Array<Vector> {
    return [this.begin, this.end];
  }

  private var _slope: Vector;
  /**
   * Returns the slope of the line in the form of a vector of length 1
   */
  public function getSlope(): Vector {
    if (this._slope) {
      return this._slope;
    }
    final begin = this.begin;
    final end = this.end;
    final distance = begin.distance(end);
    return (this._slope = end.sub(begin).scale(1 / distance));
  }

  /**
   * Returns the edge of the line as vector, the length of the vector is the length of the edge
   */
  public function getEdge(): Vector {
    final begin = this.begin;
    final end = this.end;
    return end.sub(begin);
  }

  /**
   * Returns the length of the line segment in pixels
   */
  public function getLength(): Int {
    final begin = this.begin;
    final end = this.end;
    final distance = begin.distance(end);
    return distance;
  }

  /**
   * Returns the midpoint of the edge
   */
  public var midpoint(get, never): Vector;
  function get_midpoint(): Vector {
    return this.begin.add(this.end).scale(0.5);
  }

  /**
   * Flips the direction of the line segment
   */
  public function flip(): LineSegment {
    return new LineSegment(this.end, this.begin);
  }

  /**
   * Tests if a given point is below the line, points in the normal direction above the line are considered above.
   * @param point
   */
  public function below(point: Vector): Bool {
    final above2 = (this.end.x - this.begin.x) * (point.y - this.begin.y) - (this.end.y - this.begin.y) * (point.x - this.begin.x);
    return above2 >= 0;
  }

  /**
   * Returns the clip point
   * @param sideVector Vector that traces the line
   * @param length Length to clip along side
   */
  public function clip(sideVector: Vector, length: Float, normalize = true): LineSegment {
    var dir = sideVector;
    if (normalize) {
      dir = dir.normalize();
    }

    final near = dir.dot(this.begin) - length;
    final far = dir.dot(this.end) - length;

    final results = [];
    if (near <= 0) {
      results.push(this.begin);
    }
    if (far <= 0) {
      results.push(this.end);
    }

    if (near * far < 0) {
      final clipTime = near / (near - far);
      results.push(this.begin.add(this.end.sub(this.begin).scale(clipTime)));
    }
    if (results.length != 2) {
      return null;
    }

    return new LineSegment(results[0], results[1]);
  }

  /**
   * Find the perpendicular distance from the line to a point
   * https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
   * @param point
   */
  public function distanceToPoint(point: Vector, signed: Bool = false) {
    final x0 = point.x;
    final y0 = point.y;

    final l = this.getLength();

    final dy = this.end.y - this.begin.y;
    final dx = this.end.x - this.begin.x;
    final distance = (dy * x0 - dx * y0 + this.end.x * this.begin.y - this.end.y * this.begin.x) / l;
    return signed ? distance : Math.abs(distance);
  }

  /**
   * Find the perpendicular line from the line to a point
   * https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
   * (a - p) - ((a - p) * n)n
   * a is a point on the line
   * p is the arbitrary point above the line
   * n is a unit vector in direction of the line
   * @param point
   */
  public function findVectorToPoint(point: Vector): Vector {
    final aMinusP = this.begin.sub(point);
    final n = this.getSlope();

    return aMinusP.sub(n.scale(aMinusP.dot(n)));
  }

  /**
   * Finds a point on the line given only an X or a Y value. Given an X value, the function returns
   * a new point with the calculated Y value and vice-versa.
   * @param x The known X value of the target point
   * @param y The known Y value of the target point
   * @returns A new point with the other calculated axis value
   */
  public function findPoint(?x: Int = null, ?y: Int = null): Vector {
    final m = this.slope;
    final b = this.intercept;

    if (x != null) {
      return new Vector(x, m * x + b);
    } else if (y != null) {
      return new Vector((y - b) / m, y);
    } else {
      throw new Error('You must provide an X or a Y value');
    }
  }

  /**
   * @see http://stackoverflow.com/a/11908158/109458
   */
  public function hasPoint(currPoint: Vector, ?threshold: Float = 0): Bool {
    final dxc = currPoint.x - this.begin.x;
    final dyc = currPoint.y - this.begin.y;

    final dx1 = this.end.x - this.begin.x;
    final dy1 = this.end.y - this.begin.y;

    final cross = dxc * dy1 - dyc * dx1;

    // check whether point lines on the line
    if (Math.abs(cross) > threshold) {
      return false;
    }

    // check whether point lies in-between start and end
    if (Math.abs(dx1) >= Math.abs(dy1)) {
      return dx1 > 0 ? this.begin.x <= currPoint.x && currPoint.x <= this.end.x : this.end.x <= currPoint.x && currPoint.x <= this.begin.x;
    } else {
      return dy1 > 0 ? this.begin.y <= currPoint.y && currPoint.y <= this.end.y : this.end.y <= currPoint.y && currPoint.y <= this.begin.y;
    }
  }
}
