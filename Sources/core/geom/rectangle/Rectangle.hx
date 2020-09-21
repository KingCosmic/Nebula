package core.geom.rectangle;

// Encapsulates a 2D rectangle defined by its corner point in the top-left and its extends in x (width) and y (height)
class Rectangle {
  /**
   * The geometry constant type of this object: `GEOM_CONST.RECTANGLE`.
   * Used for fast type comparisons.
   */
  public var type:Int = 5;

  // The X coordinate of the top left corner of the Rectangle.
  public var x:Float = 0;

  // The Y coordinate of the top left corner of the Rectangle.
  public var y:Float = 0;

	// The width of the Rectangle, i.e. the distance between its left side (defined by `x`) and its right side.
  public var width:Float = 0;

  public var height:Float = 0;

  public function new(?_x:Float = 0, ?_y:Float = 0, ?_width:Float = 0, ?_height:Float = 0) {
    x = _x;
    y = _y;
    width = _width;
    height = _height;
  }

  // Sets the position, width, and height of the Rectangle.
  public function setTo(_x:Float, _y:Float, _width:Float, _height:Float) {
    x = _x;
    y = _y;
    width = _width;
    height = _height;

    return this;
  }

  // Resets the position, width, and height of the Rectangle to 0.
  public function setEmpty() {
    return setTo(0, 0, 0, 0);
  }

	public var centerX(get, set):Float;

	function get_centerX() {
		return x + (width / 2);
	}

	function set_centerX(value:Float) {
		x = value - (width / 2);
		return x;
  }


	public var centerY(get, set):Float;

	function get_centerY() {
		return y + (height / 2);
	}

	function set_centerY(value:Float) {
		y = value - (height / 2);
		return y;
	}
}