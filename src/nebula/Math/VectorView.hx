package nebula.math;

import nebula.math.Vector;

interface VectorViewOptions {
  var getX: () -> Int;
  var getY: () -> Int;
  var setX: (x: Int) -> Void;
  var setY: (y: Int) -> Void;
}
class VectorView extends Vector {
  private var _getX: () -> Int;
  private var _getY: () -> Int;
  private var _setX: (x: Int) -> Void;
  private var _setY: (y: Int) -> Void;
  public function new(options: VectorViewOptions) {
    super(0, 0);
    this._getX = options.getX;
    this._getY = options.getY;
    this._setX = options.setX;
    this._setY = options.setY;
  }
  public var x(get, set): Int;
  function get_x() {
    return (this._x = this._getX());
  }
  function set_x(val: Int) {
    this._setX(val);
    this._x = val;
  }

  public var y(get, set): Int;
  function get_y() {
    return (this._y = this._getY());
  }
  function set_y(val: Int) {
    this._setY(val);
    this._y = val;
  }
}
