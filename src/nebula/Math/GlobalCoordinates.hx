package nebula.Math;

import nebula.Engine;
import nebula.Math.Vector;

class GlobalCoordinates {
  public static fromPagePosition(x: Int, y: Int, engine: Engine): GlobalCoordinates;
  public static fromPagePosition(pos: Vector, engine: Engine): GlobalCoordinates;
  public static fromPagePosition(xOrPos: Int | Vector, yOrEngine: Int | Engine, engineOrUndefined?: Engine): GlobalCoordinates {
    var pageX: Int;
    var pageY: Int;
    var pagePos: Vector;
    var engine: Engine;

    if (arguments.length === 3) {
      pageX = <Int>xOrPos;
      pageY = <Int>yOrEngine;
      pagePos = new Vector(pageX, pageY);
      engine = engineOrUndefined;
    } else {
      pagePos = <Vector>xOrPos;
      pageX = pagePos.x;
      pageY = pagePos.y;
      engine = <Engine>yOrEngine;
    }

    final screenPos = engine.screen.pageToScreenCoordinates(pagePos);
    final worldPos = engine.screen.screenToWorldCoordinates(screenPos);

    return new GlobalCoordinates(worldPos, pagePos, screenPos);
  }

  public function new(
    public worldPos: Vector,
    public pagePos: Vector,
    public screenPos: Vector
  ) {}
}
