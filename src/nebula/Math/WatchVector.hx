package nebula.math;

import nebula.math.Vector;

/**
 * Wraps a vector and watches for changes in the x/y, modifies the original vector.
 */
class WatchVector extends Vector {
  public function new(
    original: Vector,
    change: (x: Int, y: Int) -> Any
  ) {
    super(original.x, original.y);
  }

  public var x(get, set): Int;
  function get_x() {
    return (this._x = this.original.x);
  }
  function set_x(newX: Int) {
    if (newX != this._x) {
      this.change(newX, this._y);
      this._x = this.original.x = newX;
    }
  }

  public var y(get, set): Int;
  function get_y() {
    return (this._y = this.original.y);
  }
  function set_y(newY: Int) {
    if (newY != this._y) {
      this.change(this._x, newY);
      this._y = this.original.y = newY;
    }
  }

  override function setTo(x: Int, y: Int): Void {
    this.x = x;
    this.y = y;
  }
}
