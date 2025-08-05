package nebula.Math;

import nebula.Math.Vector;

/**
 * Wraps a vector and watches for changes in the x/y, modifies the original vector.
 */
class WatchVector extends Vector {
  public function new(
    public original: Vector,
    public change: (x: Int, y: Int) => dynamic
  ) {
    super(original.x, original.y);
  }
  public get x() {
    return (this._x = this.original.x);
  }

  public set x(newX: Int) {
    if (newX !== this._x) {
      this.change(newX, this._y);
      this._x = this.original.x = newX;
    }
  }

  public get y() {
    return (this._y = this.original.y);
  }

  public set y(newY: Int) {
    if (newY !== this._y) {
      this.change(this._x, newY);
      this._y = this.original.y = newY;
    }
  }

  override setTo(x: Int, y: Int): Void {
    this.x = x;
    this.y = y;
  }
}
