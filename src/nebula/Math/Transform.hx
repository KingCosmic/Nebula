package nebula.math;

import nebula.math.AffineMatrix;
import nebula.math.Util;
import nebula.math.Vector;
import nebula.math.VectorView;
import nebula.math.WatchVector;

class Transform {
  private var _parent: Null<Transform> = null;

  public var parent(get, set): Null<Transform>;
  function get_parent() {
    return this._parent;
  }
  function set_parent(transform: Null<Transform>) {
    if (this._parent) {
      final index = this._parent._children.indexOf(this);
      if (index > -1) {
        this._parent._children.splice(index, 1);
      }
    }
    this._parent = transform;
    if (this._parent) {
      this._parent._children.push(this);
    }
    this.flagDirty();
  }

  public var children(get, never): Array<Transform>;
  function get_children(): Array<Transform> {
    return this._children;
  }
  private var _children: Array<Transform> = [];

  private var _pos: Vector = new WatchVector(vec(0, 0), () -> {
    this.flagDirty();
  });

  public var pos(get, set): Vector;
  function get_pos() {
    return this._pos;
  }
  function set_pos(v: Vector) {
    this._pos.x = v.x;
    this._pos.y = v.y;
  }

  public var globalPos(get, set): Vector;
  function get_globalPos() {
    return this._globalPos;
  }
  function set_globalPos(v: Vector) {
    var localPos = v.clone();
    if (this.parent) {
      localPos = this.parent.inverse.multiply(v);
    }
    if (!localPos.equals(this._pos)) {
      this._pos = localPos;
      this.flagDirty();
    }
  }
  private var _globalPos = new VectorView({
    getX: () -> this.matrix.data[4],
    getY: () -> this.matrix.data[5],
    setX: (x) -> {
      if (this.parent) {
        final newX = this.parent.inverse.multiply(vec(x, this.pos.y)).x;
        this.pos.x = newX;
      } else {
        this.pos.x = x;
      }
      if (x != this.matrix.data[4]) {
        this.flagDirty();
      }
    },
    setY: (y) -> {
      if (this.parent) {
        final newY = this.parent.inverse.multiply(vec(this.pos.x, y)).y;
        this.pos.y = newY;
      } else {
        this.pos.y = y;
      }
      if (y != this.matrix.data[5]) {
        this.flagDirty();
      }
    }
  });

  private var _rotation: Int = 0;
  public var rotation(get, set): Int;
  function get_rotation() {
    return this._rotation;
  }
  function set_rotation(rotation: Int) {
    final canonRotation = canonicalizeAngle(rotation);
    if (canonRotation != this._rotation) {
      this.flagDirty();
    }
    this._rotation = canonRotation;
  }

  public var globalRotation(get, set): Int;
  function get_globalRotation() {
    if (this.parent) {
      return this.matrix.getRotation();
    }
    return this.rotation;
  }
  function set_globalRotation(rotation: Int) {
    var inverseRotation = 0;
    if (this.parent) {
      inverseRotation = this.parent.globalRotation;
    }
    final canonRotation = canonicalizeAngle(rotation + inverseRotation);
    if (canonRotation != this._rotation) {
      this.flagDirty();
    }
    this._rotation = canonRotation;
  }

  private var _scale: Vector = new WatchVector(vec(1, 1), () -> {
    this.flagDirty();
  });
  public var scale(get, set): Vector;
  function get_scale() {
    return this._scale;
  }
  function set_scale(v: Vector) {
    this._scale.x = v.x;
    this._scale.y = v.y;
  }

  public var globalState(get, set): Vector;
  function get_globalScale() {
    return this._globalScale;
  }
  function set_globalScale(v: Vector) {
    var inverseScale = vec(1, 1);
    if (this.parent) {
      inverseScale = this.parent.globalScale;
    }
    this.scale = v.scale(vec(1 / inverseScale.x, 1 / inverseScale.y));
  }

  private var _globalScale = new VectorView({
    getX: () -> (this.parent ? this.matrix.getScaleX() : this.scale.x),
    getY: () -> (this.parent ? this.matrix.getScaleY() : this.scale.y),
    setX: (x) -> {
      if (this.parent) {
        final globalScaleX = this.parent.globalScale.x;
        this.scale.x = x / globalScaleX;
      } else {
        this.scale.x = x;
      }
    },
    setY: (y) -> {
      if (this.parent) {
        final globalScaleY = this.parent.globalScale.y;
        this.scale.y = y / globalScaleY;
      } else {
        this.scale.y = y;
      }
    }
  });

  private var _z: Int = 0;
  public var z(get, set): Int;
  function get_z() {
    return this._z;
  }
  function set_z(z: Int) {
    this._z = z;
    this.flagDirty();
  }

  public var globalZ(get, set): Int;
  function get_globalZ() {
    if (this.parent) {
      return this.z + this.parent.globalZ;
    }
    return this.z;
  }
  function set_globalZ(z: Int) {
    if (this.parent) {
      this.z = z - this.parent.globalZ;
    } else {
      this.z = z;
    }
  }

  private var _isDirty = false;
  private var _isInverseDirty = false;
  private var _matrix = AffineMatrix.identity();
  private var _inverse = AffineMatrix.identity();

  /**
   * Calculates and returns the matrix representation of this transform
   *
   * Avoid mutating the matrix to update the transform, it is not the source of truth.
   * Update the transform pos, rotation, scale.
   */
  public var matrix(get, never): AffineMatrix;
  function get_matrix(): AffineMatrix {
    if (this._isDirty) {
      if (this.parent == null) {
        this._calculateMatrix().clone(this._matrix);
      } else {
        this.parent.matrix.multiply(this._calculateMatrix()).clone(this._matrix);
      }
      this._isDirty = false;
    }
    return this._matrix;
  }

  /**
   * Calculates and returns the inverse matrix representation of this transform
   */
  public var inverse(get, never): AffineMatrix;
  function get_inverse(): AffineMatrix {
    if (this._isInverseDirty) {
      this.matrix.inverse(this._inverse);
      this._isInverseDirty = false;
    }
    return this._inverse;
  }

  private var _scratch = AffineMatrix.identity();
  private function _calculateMatrix(): AffineMatrix {
    this._scratch.data[0] = Math.cos(this._rotation);
    this._scratch.data[1] = Math.sin(this._rotation);
    this._scratch.data[2] = -Math.sin(this._rotation);
    this._scratch.data[3] = Math.cos(this.rotation);
    this._scratch.data[4] = this._pos.x;
    this._scratch.data[5] = this._pos.y;
    this._scratch.scale(this._scale.x, this._scale.y);
    return this._scratch;
  }

  public function flagDirty() {
    this._isDirty = true;
    this._isInverseDirty = true;
    for (i in 0...this._children.length) {
      this._children[i].flagDirty();
    }
  }

  public function apply(point: Vector): Vector {
    return this.matrix.multiply(point);
  }

  public function applyInverse(point: Vector): Vector {
    return this.inverse.multiply(point);
  }

  public function setTransform(pos: Vector, rotation: Int, scale: Vector) {
    this._pos.x = pos.x;
    this._pos.y = pos.y;
    this._rotation = canonicalizeAngle(rotation);
    this._scale.x = scale.x;
    this._scale.y = scale.y;
    this.flagDirty();
  }

  /**
   * Returns true if the transform has a negative x scale or y scale, but not both
   */
  public function isMirrored(): Bool {
    final signBitX = sign(this.scale.x) >>> 31;
    final signBitY = sign(this.scale.y) >>> 31;
    final mirrored = signBitX ^ signBitY;
    return !!mirrored;
  }

  /**
   * Clones the current transform
   * **Warning does not clone the parent**
   * @param dest
   */
  public function clone(?dest: Transform): Transform {
    final target = dest ?? new Transform();
    this._pos.clone(target._pos);
    target._z = this._z;
    target._rotation = this._rotation;
    this._scale.clone(target._scale);
    target.flagDirty();
    return target;
  }

  /**
   * Clones but keeps the same parent reference
   */
  public function cloneWithParent(?dest: Transform): Transform {
    final target = dest ?? new Transform();
    this._pos.clone(target._pos);
    target._z = this._z;
    target._rotation = this._rotation;
    this._scale.clone(target._scale);
    target.parent = this.parent;
    target.flagDirty();
    return target;
  }

  public function toString(): String {
    return this.matrix.toString();
  }
}
