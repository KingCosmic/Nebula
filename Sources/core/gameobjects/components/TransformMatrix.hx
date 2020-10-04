package core.gameobjects.components;

import haxe.io.Float32Array;

typedef DecomposedMatrix = {
	translateX:Float,
	translateY:Float,
	scaleX:Float,
	scaleY:Float,
	rotation:Float
}

// TODO: finish adding other methods

/**
 * A Matrix used for display transformations for rendering.
 *
 * It is represented like so:
 *
 * ```
 * | a | c | tx |
 * | b | d | ty |
 * | 0 | 0 | 1  |
 * ```
 */
class TransformMatrix {
	// The matrix values.
	public var matrix:Float32Array;

	// The decomposed matrix.
	public var decomposedMatrix:DecomposedMatrix = {
		translateX: 0,
		translateY: 0,
		scaleX: 1,
		scaleY: 1,
		rotation: 0
	};

	// The Scale X value.
	public var a(get, set):Float;

	function get_a() {
		return matrix[0];
	}

	function set_a(value:Float) {
		matrix[0] = value;

		return matrix[0];
	}

	// The Skew Y value.
	public var b(get, set):Float;

	function get_b() {
		return matrix[1];
	}

	function set_b(value:Float) {
		matrix[1] = value;

		return matrix[1];
	}

	// The Skew X value.
	public var c(get, set):Float;

	function get_c() {
		return matrix[2];
	}

	function set_c(value:Float) {
		matrix[2] = value;

		return matrix[2];
	}

	// The Scale Y value.
	public var d(get, set):Float;

	function get_d() {
		return matrix[3];
	}

	function set_d(value:Float) {
		matrix[3] = value;

		return matrix[3];
	}

	// The Translate X value.
	public var e(get, set):Float;

	function get_e() {
		return matrix[4];
	}

	function set_e(value:Float) {
		matrix[4] = value;

		return matrix[4];
	}

	// The Translate Y value.
	public var f(get, set):Float;

	function get_f() {
		return matrix[5];
	}

	function set_f(value:Float) {
		matrix[5] = value;

		return matrix[5];
	}

	// The Translate X value.
	public var tx(get, set):Float;

	function get_tx() {
		return matrix[4];
	}

	function set_tx(value:Float) {
		matrix[4] = value;

		return matrix[4];
	}

	// The Translate Y value.
	public var ty(get, set):Float;

	function get_ty() {
		return matrix[5];
	}

	function set_ty(value:Float) {
		matrix[5] = value;

		return matrix[5];
	}

	// The rotation of the Matrix. Value is in radians.
	public var rotation(get, null):Float;

	function get_rotation() {
		return Math.acos(a / scaleX) * ((Math.atan(-c / a) < 0) ? -1 : 1);
	}

	// The rotation of the Matrix, normalized to be within the Phaser right-handed
	// clockwise rotation space. Value is in radians.
	public var rotationNormalized(get, null):Float;

	function get_rotationNormalized() {
		var a = matrix[0];
		var b = matrix[1];
		var c = matrix[2];
		var d = matrix[3];

		if (a > 0 || b > 0) {
			return (b > 0) ? Math.acos(a / scaleX) : -Math.acos(a / scaleX);
		} else if (c > 0 || d > 0) {
			return (Math.PI * 0.5) - ((d > 0) ? Math.acos(-c / scaleY) : -Math.acos(c / scaleY));
		} else {
			return 0;
		}
	}

	// The decomposed horizontal scale of the Matrix. This value is always positive.
	public var scaleX(get, null):Float;

	function get_scaleX() {
		return Math.sqrt((a * a) + (b * b));
	}

	// The decomposed vertical scale of the Matrix. This value is always positive.
	public var scaleY(get, null):Float;

	function get_scaleY() {
		return Math.sqrt((c * c) + (d * d));
	}

	public function new(?a:Float = 1, ?b:Float = 0, ?c:Float = 0, ?d:Float = 1, ?tx:Float = 0, ?ty:Float = 0) {
		matrix = Float32Array.fromArray([a, b, c, d, tx, ty, 0, 0, 1]);
	}

	// Reset the Matrix to an identity matrix.
	public function loadIdentity() {
		matrix[0] = 1;
		matrix[1] = 0;
		matrix[2] = 0;
		matrix[3] = 1;
		matrix[4] = 0;
		matrix[5] = 0;

		return this;
	}

	// Translate the Matrix
	public function translate(x:Float, y:Float) {
		matrix[4] = matrix[0] * x + matrix[2] * y + matrix[4];
		matrix[5] = matrix[1] * x + matrix[3] * y + matrix[5];

		return this;
	}

	// Scale the Matrix
	public function scale(x:Float, y:Float) {
		matrix[0] *= x;
		matrix[1] *= x;
		matrix[2] *= y;
		matrix[3] *= y;

		return this;
	}

	// Rotate the Matrix
	public function roate(angle:Float) {
		var sin = Math.sin(angle);
		var cos = Math.cos(angle);

		var a = matrix[0];
		var b = matrix[1];
		var c = matrix[2];
		var d = matrix[3];

		matrix[0] = a * cos + c * sin;
		matrix[1] = b * cos + d * sin;
		matrix[2] = a * -sin + c * cos;
		matrix[3] = b * -sin + d * cos;

		return this;
	}

	/**
	 * Multiply this Matrix by the given Matrix.
	 *
	 * If an `out` Matrix is given then the results will be stored in it.
	 * If it is not given, this matrix will be updated in place instead.
	 * Use an `out` Matrix if you do not wish to mutate this matrix.
	 */
	public function multiply(rhs:TransformMatrix, ?out:TransformMatrix) {
		var source = rhs.matrix;

		var localA = matrix[0];
		var localB = matrix[1];
		var localC = matrix[2];
		var localD = matrix[3];
		var localE = matrix[4];
		var localF = matrix[5];

		var sourceA = source[0];
		var sourceB = source[1];
		var sourceC = source[2];
		var sourceD = source[3];
		var sourceE = source[4];
		var sourceF = source[5];

		var destinationMatrix = (out == null) ? this : out;

		destinationMatrix.a = (sourceA * localA) + (sourceB * localC);
		destinationMatrix.b = (sourceA * localB) + (sourceB * localD);
		destinationMatrix.c = (sourceC * localA) + (sourceD * localC);
		destinationMatrix.d = (sourceC * localB) + (sourceD * localD);
		destinationMatrix.e = (sourceE * localA) + (sourceF * localC) + localE;
		destinationMatrix.f = (sourceF * localB) + (sourceF * localD) + localF;

		return destinationMatrix;
	}

	// Apply the identity, translate, rotate and scale operations on the Matrix.
	public function applyITRS(_x:Float, _y:Float, _rotation:Float, _scaleX:Float, _scaleY:Float) {
		var radianSin = Math.sin(_rotation);
		var radianCos = Math.cos(_rotation);

		// Translate
		matrix[4] = _x;
		matrix[5] = _y;

		// Rotate and Scale
		matrix[0] = radianCos * _scaleX;
		matrix[1] = radianSin * _scaleX;
		matrix[2] = -radianSin * scaleY;
		matrix[3] = radianCos * scaleY;

		return this;
	}

	// Destroys this Transform Matrix.
	public function destroy() {
		matrix = null;
		decomposedMatrix = null;
	}
}