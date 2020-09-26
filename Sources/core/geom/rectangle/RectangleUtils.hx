package core.geom.rectangle;

class RectangleUtils {
	/**
	 * Checks if a given point is inside a Rectangle's bounds.
   */
  static public function contains(rect:Rectangle, x:Float, y:Float) {
		if (rect.width <= 0 || rect.height <= 0) {
			return false;
		}

		return (rect.x <= x && rect.x + rect.width >= x && rect.y <= y && rect.y + rect.height >= y);
  }
  
  /**
   * Determines whether the specified point is contained within the rectangular region defined by this Rectangle object.
   */
  static public function containsPoint(rect:Rectangle, x:Float, y:Float) {
    return contains(rect, x, y);
  }
}