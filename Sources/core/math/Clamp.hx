package core.math;

class Clamp{
/**
 * Force a value within the boundaries by clamping it to the range `min`, `max`.
 */
public static function clamp(value, min, max)
{
    return Math.max(min, Math.min(max, value));
}
}