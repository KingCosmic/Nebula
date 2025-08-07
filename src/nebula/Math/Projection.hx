package nebula.math;

/**
 * A 1 dimensional projection on an axis, used to test overlaps
 */

class Projection {
  public function new(
    min: Int,
    max: Int
  ) {}

  public function overlaps(projection: Projection): Bool {
    return this.max > projection.min && projection.max > this.min;
  }

  public function getOverlap(projection: Projection): Int {
    if (this.overlaps(projection)) {
      if (this.max > projection.max) {
        return projection.max - this.min;
      } else {
        return this.max - projection.min;
      }
    }
    return 0;
  }
}
