package nebula.Math;

import nebula.Math.Vector;

interface VectorViewOptions {
  getX: () => Int;
  getY: () => Int;
  setX: (x: Int) => Void;
  setY: (y: Int) => Void;
}
class VectorView extends Vector {
  private _getX: () => Int;
  private _getY: () => Int;
  private _setX: (x: Int) => Void;
  private _setY: (y: Int) => Void;
  public function new(options: VectorViewOptions) {
    super(0, 0);
    this._getX = options.getX;
    this._getY = options.getY;
    this._setX = options.setX;
    this._setY = options.setY;
  }
  public get x() {
    return (this._x = this._getX());
  }

  public set x(val) {
    this._setX(val);
    this._x = val;
  }

  public get y() {
    return (this._y = this._getY());
  }
  public set y(val) {
    this._setY(val);
    this._y = val;
  }
}
