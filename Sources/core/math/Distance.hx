package core.math;

class Distance {
	// Calculate the distance between two sets of coordinates.
	static public function distanceBetween(x1:Float, y1:Float, x2:Float, y2:Float):Float {
		var dx = x1 - x2;
		var dy = y1 - y2;

		return Math.sqrt(dx * dx + dy * dy);
	}
}