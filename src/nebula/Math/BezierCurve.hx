package nebula.math;

import nebula.math.Lerp;
import nebula.math.Vector;

interface BezierCurveOptions {
  /**
   * [start, control1, control2, end]
   */
  var controlPoints: Array<Vector>;
  /**
   * Quality when sampling uniform points on the curve. Samples = 4 * quality;
   *
   * For bigger 'uniform' curves you may want to increase quality
   *
   * Default 4
   */
  var quality: Null<Int>;
}

/**
 * BezierCurve that supports cubic Bezier curves.
 */
class BezierCurve {
  // Thanks Freya! https://www.youtube.com/watch?v=aVwxzDHniEw
  private var _distLookup: Array<Int> = [];
  private var _controlPoints: Array<Vector>;
  private var _arcLength: Int;
  var quality: Int = 4;
  public function new(options: BezierCurveOptions) {
    if (options.controlPoints.length !== 4) {
      throw new Error('Only cubic bezier curves are supported');
    }
    this._controlPoints = [...options.controlPoints];
    this.quality = options.quality ?? this.quality;

    this._calculateLookup();
  }

  public var arcLength(get, never): Int;
  function get_arcLength(): Int {
    return this._arcLength;
  }

  public var controlPoints(get, set): Array<Vector>;
  function get_controlPoints() {
    return this._controlPoints;
  }
  function set_controlPoints(points: Array<Vector>) {
    this._controlPoints = [...points];
    this._calculateLookup();
  }

  function setControlPoint(index: Int, point: Vector) {
    this._controlPoints[index] = point;
    this._calculateLookup();
  }

  private function _calculateLookup() {
    var totalLength = 0;
    this._distLookup.length = 0;
    var prev = this.controlPoints[0];
    final n = this.controlPoints.length * this.quality;
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final pt = this.getPoint(t);
      final diff = prev.distance(pt);
      totalLength += diff;
      this._distLookup.push(totalLength);
      prev = pt;
    }
    this._arcLength = totalLength;
  }

  private function _getTimeGivenDistance(distance: Float): Int {
    final n = this._distLookup.length;
    final arcLength = this.arcLength;

    if (distance >= 0 && distance < arcLength) {
      for (var i = 0; i < n - 1; i++) {
        if (this._distLookup[i] <= distance && distance < this._distLookup[i + 1]) {
          return remap(this._distLookup[i], this._distLookup[i + 1], i / (n - 1), (i + 1) / (n - 1), distance);
        }
      }
    }
    return distance / arcLength;
  }

  /**
   * Get the point on the Bezier curve at a certain time
   * @param time Between 0-1
   */
  function getPoint(time: Float): Vector {
    final points = [...this.controlPoints];

    for (var r = 1; r < points.length; r++) {
      for (var i = 0; i < points.length - r; i++) {
        points[i] = lerpVector(points[i], points[i + 1], time);
      }
    }

    return points[0];
  }

  /**
   * Get the tangent of the Bezier curve at a certain time
   * @param time Between 0-1
   */
  function getTangent(time: Float): Vector {
    final timeSquared = time * time;
    final p0 = this.controlPoints[0];
    final p1 = this.controlPoints[1];
    final p2 = this.controlPoints[2];
    final p3 = this.controlPoints[3];

    // Derivative of Bernstein polynomial
    final pPrime = p0
      .scale(-3 * timeSquared + 6 * time - 3)
      .add(p1.scale(9 * timeSquared - 12 * time + 3).add(p2.scale(-9 * timeSquared + 6 * time).add(p3.scale(3 * timeSquared))));

    return pPrime.normalize();
  }

  /**
   * Get the tangent of the Bezier curve where the distance is uniformly distributed over time
   * @param time
   */
  function getUniformTangent(time: Float): Vector {
    final desiredDistance = time * this.arcLength;
    final uniformTime = this._getTimeGivenDistance(desiredDistance);
    return this.getTangent(uniformTime);
  }

  /**
   * Get the normal of the Bezier curve at a certain time
   * @param time Between 0-1
   */
  function getNormal(time: Float): Vector {
    return this.getTangent(time).normal();
  }

  /**
   * Get the normal of the Bezier curve where the distance is uniformly distributed over time
   * @param time
   */
  function getUniformNormal(time: Float): Vector {
    return this.getUniformTangent(time).normal();
  }

  /**
   * Points are spaced uniformly across the length of the curve over time
   * @param time
   */
  function getUniformPoint(time: Float): Vector {
    final desiredDistance = time * this.arcLength;
    final uniformTime = this._getTimeGivenDistance(desiredDistance);
    return this.getPoint(uniformTime);
  }

  function clone(): BezierCurve {
    return new BezierCurve({
      controlPoints: [...this.controlPoints],
      quality: this.quality
    });
  }
}
