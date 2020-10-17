package core.math;


 class RotateAround {
/**
 * Rotate a `point` around `x` and `y` to the given `angle`, at the same distance.
 *
 * In polar notation, this maps a point from (r, t) to (r, angle), vs. the origin (x, y).
 */
    static public function rotateAround(point:Dynamic, x:Float, y:Float, angle:Float) {
        if(!Reflect.hasField(point,"x")){return point;}//To-Do Dirty Check, Dynamic?
        var c = Math.cos(angle);
        var s = Math.sin(angle);

        var tx = point.x - x;
        var ty = point.y - y;

        point.x = tx * c - ty * s + x;
        point.y = tx * s + ty * c + y;
        return point;
        }
}