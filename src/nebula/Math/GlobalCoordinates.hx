package nebula.math;

import nebula.Engine;
import nebula.math.Vector;

class GlobalCoordinates {
  public static function fromPagePosition(pos: Vector, engine: Engine): GlobalCoordinates {
    final screenPos = engine.screen.pageToScreenCoordinates(pos);
    final worldPos = engine.screen.screenToWorldCoordinates(screenPos);

    return new GlobalCoordinates(worldPos, pagePos, screenPos);
  }

  public function new(
    worldPos: Vector,
    pagePos: Vector,
    screenPos: Vector
  ) {}
}
