package nebula.math;

import nebula.math.Matrix;
import nebula.math.Util;
import nebula.math.Vector;

class AffineMatrix {
  /**
   * |         |         |          |
   * | ------- | ------- | -------- |
   * | data[0] | data[2] | data[4]  |
   * | data[1] | data[3] | data[5]  |
   * |   0     |    0    |    1     |
   */
  public var data = new Float64Array(6);

  /**
   * Converts the current matrix into a DOMMatrix
   *
   * This is useful when working with the browser Canvas context
   * @returns {DOMMatrix} DOMMatrix
   */
  public function toDOMMatrix(): DOMMatrix {
    return new DOMMatrix([...this.data]);
  }

  public static function identity(): AffineMatrix {
    final mat = new AffineMatrix();
    mat.data[0] = 1;
    mat.data[1] = 0;

    mat.data[2] = 0;
    mat.data[3] = 1;

    mat.data[4] = 0;
    mat.data[5] = 0;
    return mat;
  }

  /**
   * Creates a brand new translation matrix at the specified 3d point
   * @param x
   * @param y
   */
  public static function translation(x: Int, y: Int): AffineMatrix {
    final mat = AffineMatrix.identity();
    mat.data[4] = x;
    mat.data[5] = y;
    return mat;
  }

  /**
   * Creates a brand new scaling matrix with the specified scaling factor
   * @param sx
   * @param sy
   */
  public static function scale(sx: Float, sy: Float): AffineMatrix {
    final mat = AffineMatrix.identity();
    mat.data[0] = sx;
    mat.data[3] = sy;
    mat._scale[0] = sx;
    mat._scale[1] = sy;
    return mat;
  }

  /**
   * Creates a brand new rotation matrix with the specified angle in radians
   * @param angle
   */
  public static function rotation(angle: Float): AffineMatrix {
    final mat = AffineMatrix.identity();
    mat.data[0] = Math.cos(angle);
    mat.data[1] = Math.sin(angle);
    mat.data[2] = -Math.sin(angle);
    mat.data[3] = Math.cos(angle);
    return mat;
  }

  public function setPosition(x: Int, y: Int) {
    this.data[4] = x;
    this.data[5] = y;
  }

  public function getPosition(): Vector {
    return vec(this.data[4], this.data[5]);
  }

  /**
   * Applies rotation to the current matrix mutating it
   * @param angle in Radians
   */
  function rotate(angle: Float) {
    final a11 = this.data[0];
    final a21 = this.data[1];

    final a12 = this.data[2];
    final a22 = this.data[3];

    final sine = Math.sin(angle);
    final cosine = Math.cos(angle);

    this.data[0] = cosine * a11 + sine * a12;
    this.data[1] = cosine * a21 + sine * a22;

    this.data[2] = cosine * a12 - sine * a11;
    this.data[3] = cosine * a22 - sine * a21;

    return this;
  }

  /**
   * Applies translation to the current matrix mutating it
   * @param x
   * @param y
   */
  function translate(x: Int, y: Int) {
    final a11 = this.data[0];
    final a21 = this.data[1];
    // const a31 = 0;

    final a12 = this.data[2];
    final a22 = this.data[3];
    // const a32 = 0;

    final a13 = this.data[4];
    final a23 = this.data[5];
    // const a33 = 1;

    // Doesn't change z
    this.data[4] = a11 * x + a12 * y + a13;
    this.data[5] = a21 * x + a22 * y + a23;

    return this;
  }

  /**
   * Applies scaling to the current matrix mutating it
   * @param x
   * @param y
   */
  function scale(x: Float, y: Float) {
    final a11 = this.data[0];
    final a21 = this.data[1];

    final a12 = this.data[2];
    final a22 = this.data[3];

    this.data[0] = a11 * x;
    this.data[1] = a21 * x;

    this.data[2] = a12 * y;
    this.data[3] = a22 * y;

    this._scale[0] = x;
    this._scale[1] = y;
    this._scaleSignX = sign(x);
    this._scaleSignY = sign(y);
    return this;
  }

  public function determinant() {
    return this.data[0] * this.data[3] - this.data[1] * this.data[2];
  }

  /**
   * Return the affine inverse, optionally store it in a target matrix.
   *
   * It's recommended you call .reset() the target unless you know what you're doing
   * @param target
   */
  public function inverse(?target: AffineMatrix): AffineMatrix {
    // See http://negativeprobability.blogspot.com/2011/11/affine-transformations-and-their.html
    // See https://www.mathsisfun.com/algebra/matrix-inverse.html
    // Since we are actually only doing 2D transformations we can use this hack
    // We don't actually use the 3rd or 4th dimension

    final det = this.determinant();
    var inverseDet = det; // default to a zero matrix if we have a singular matrix
    if (det != 0) {
      inverseDet = 1 / det;
    }
    final a = this.data[0];
    final b = this.data[2];
    final c = this.data[1];
    final d = this.data[3];

    final m = target || AffineMatrix.identity();
    // inverts rotation and scale
    m.data[0] = d * inverseDet;
    m.data[1] = -c * inverseDet;
    m.data[2] = -b * inverseDet;
    m.data[3] = a * inverseDet;

    final tx = this.data[4];
    final ty = this.data[5];
    // invert translation
    // transform translation into the matrix basis created by rot/scale
    m.data[4] = -(tx * m.data[0] + ty * m.data[2]);
    m.data[5] = -(tx * m.data[1] + ty * m.data[3]);

    return m;
  }

  /**
   * Multiply the current matrix by another matrix producing a new matrix
   * @param matrix
   * @param dest
   */
  function multiply<T>(vectorOrMatrix: T, ?dest: T): T {

    if (Std.isTypeOf(vectorOrMatrix, Vector)) {
      final result: Vector = dest || new Vector(0, 0);
      final vector = vectorOrMatrix;
      // these shenanigans are to allow dest and vector to be the same instance
      final resultX = vector.x * this.data[0] + vector.y * this.data[2] + this.data[4];
      final resultY = vector.x * this.data[1] + vector.y * this.data[3] + this.data[5];

      result.x = resultX;
      result.y = resultY;
      return result;
    } else if (Std.isTypeOf(vectorOrMatrix, AffineMatrix)) {
      final result: AffineMatrix = dest || new AffineMatrix();
      final other = vectorOrMatrix;
      final a11 = this.data[0];
      final a21 = this.data[1];
      //  const a31 = 0;

      final a12 = this.data[2];
      final a22 = this.data[3];
      //  const a32 = 0;

      final a13 = this.data[4];
      final a23 = this.data[5];
      //  const a33 = 1;

      final b11 = other.data[0];
      final b21 = other.data[1];
      //  const b31 = 0;

      final b12 = other.data[2];
      final b22 = other.data[3];
      //  const b32 = 0;

      final b13 = other.data[4];
      final b23 = other.data[5];
      //  const b33 = 1;

      result.data[0] = a11 * b11 + a12 * b21; // + a13 * b31; // zero
      result.data[1] = a21 * b11 + a22 * b21; // + a23 * b31; // zero

      result.data[2] = a11 * b12 + a12 * b22; // + a13 * b32; // zero
      result.data[3] = a21 * b12 + a22 * b22; // + a23 * b32; // zero

      result.data[4] = a11 * b13 + a12 * b23 + a13; // * b33; // one
      result.data[5] = a21 * b13 + a22 * b23 + a23; // * b33; // one

      final signX = this._scaleSignX;
      final signY = this._scaleSignY;
      result._scaleSignX = signX * sign(result._scaleSignX);
      result._scaleSignY = signY * sign(result._scaleSignY);

      return result;
    }
  }

  /**
   * Packed array of length 8, that contains 4 vertices, with 2 components each
   * So: [x0, y0, x1, y1, x2, y2, x3, y3]
   * @param quad
   */
  function multiplyQuadInPlace(quad: Array<Int>) {
    final resultTopLeftX = quad[0] * this.data[0] + quad[1] * this.data[2] + this.data[4];
    final resultTopLeftY = quad[0] * this.data[1] + quad[1] * this.data[3] + this.data[5];
    quad[0] = resultTopLeftX;
    quad[1] = resultTopLeftY;

    final resultTopRightX = quad[2] * this.data[0] + quad[3] * this.data[2] + this.data[4];
    final resultTopRightY = quad[2] * this.data[1] + quad[3] * this.data[3] + this.data[5];
    quad[2] = resultTopRightX;
    quad[3] = resultTopRightY;

    final resultBottomLeftX = quad[4] * this.data[0] + quad[5] * this.data[2] + this.data[4];
    final resultBottomLeftY = quad[4] * this.data[1] + quad[5] * this.data[3] + this.data[5];
    quad[4] = resultBottomLeftX;
    quad[5] = resultBottomLeftY;

    final resultBottomRightX = quad[6] * this.data[0] + quad[7] * this.data[2] + this.data[4];
    final resultBottomRightY = quad[6] * this.data[1] + quad[7] * this.data[3] + this.data[5];
    quad[6] = resultBottomRightX;
    quad[7] = resultBottomRightY;
  }

  function to4x4() {
    final mat = new Matrix();
    mat.data[0] = this.data[0];
    mat.data[1] = this.data[1];
    mat.data[2] = 0;
    mat.data[3] = 0;

    mat.data[4] = this.data[2];
    mat.data[5] = this.data[3];
    mat.data[6] = 0;
    mat.data[7] = 0;

    mat.data[8] = 0;
    mat.data[9] = 0;
    mat.data[10] = 1;
    mat.data[11] = 0;

    mat.data[12] = this.data[4];
    mat.data[13] = this.data[5];
    mat.data[14] = 0;
    mat.data[15] = 1;
    return mat;
  }

  public function setRotation(angle: Float) {
    final currentScale = this.getScale();
    final sine = Math.sin(angle);
    final cosine = Math.cos(angle);

    this.data[0] = cosine * currentScale.x;
    this.data[1] = sine * currentScale.y;
    this.data[2] = -sine * currentScale.x;
    this.data[3] = cosine * currentScale.y;
  }

  public function getRotation(): Float {
    final angle = Math.atan2(this.data[1] / this.getScaleY(), this.data[0] / this.getScaleX());
    return canonicalizeAngle(angle);
  }

  public function getScaleX(): Float {
    // absolute scale of the matrix (we lose sign so need to add it back)
    final xScaleSq = this.data[0] * this.data[0] + this.data[2] * this.data[2];
    if (xScaleSq == 1.0) {
      // usually there isn't scale so we can avoid a sqrt
      return this._scaleSignX;
    }
    return this._scaleSignX * Math.sqrt(xScaleSq);
  }

  public function getScaleY(): Float {
    // absolute scale of the matrix (we lose sign so need to add it back)
    final yScaleSq = this.data[1] * this.data[1] + this.data[3] * this.data[3];
    if (yScaleSq == 1.0) {
      // usually there isn't scale so we can avoid a sqrt
      return this._scaleSignY;
    }
    return this._scaleSignY * Math.sqrt(yScaleSq);
  }

  /**
   * Get the scale of the matrix
   */
  public function getScale(): Vector {
    return vec(this.getScaleX(), this.getScaleY());
  }

  private var _scale = new Float64Array([1, 1]);
  private var _scaleSignX = 1;
  public function setScaleX(val: Float) {
    if (val == this._scale[0]) {
      return;
    }
    this._scaleSignX = sign(val);
    // negative scale acts like a 180 rotation, so flip
    final xscale = vec(this.data[0] * this._scaleSignX, this.data[2] * this._scaleSignX).normalize();
    this.data[0] = xscale.x * val;
    this.data[2] = xscale.y * val;
    this._scale[0] = val;
  }

  private var _scaleSignY = 1;
  public function setScaleY(val: Float) {
    if (val == this._scale[1]) {
      return;
    }
    this._scaleSignY = sign(val);
    // negative scale acts like a 180 rotation, so flip
    final yscale = vec(this.data[1] * this._scaleSignY, this.data[3] * this._scaleSignY).normalize();
    this.data[1] = yscale.x * val;
    this.data[3] = yscale.y * val;
    this._scale[1] = val;
  }

  public function setScale(scale: Vector) {
    this.setScaleX(scale.x);
    this.setScaleY(scale.y);
  }

  public function isIdentity(): Bool {
    return this.data[0] == 1 && this.data[1] == 0 && this.data[2] == 0 && this.data[3] == 1 && this.data[4] == 0 && this.data[5] == 0;
  }

  /**
   * Resets the current matrix to the identity matrix, mutating it
   * @returns {AffineMatrix} Current matrix as identity
   */
  public function reset(): AffineMatrix {
    final mat = this;
    mat.data[0] = 1;
    mat.data[1] = 0;

    mat.data[2] = 0;
    mat.data[3] = 1;

    mat.data[4] = 0;
    mat.data[5] = 0;
    return mat;
  }

  /**
   * Creates a new Matrix with the same data as the current {@apilink AffineMatrix}
   */
  public function clone(?dest: AffineMatrix): AffineMatrix {
    final mat = dest || new AffineMatrix();
    mat.data[0] = this.data[0];
    mat.data[1] = this.data[1];
    mat.data[2] = this.data[2];
    mat.data[3] = this.data[3];
    mat.data[4] = this.data[4];
    mat.data[5] = this.data[5];
    mat._scaleSignX = this._scaleSignX;
    mat._scaleSignY = this._scaleSignY;
    return mat;
  }

  public function toString() {
    return '
      [${this.data[0]} ${this.data[2]} ${this.data[4]}]
      [${this.data[1]} ${this.data[3]} ${this.data[5]}]
      [0 0 1]
    ';
  }
}
