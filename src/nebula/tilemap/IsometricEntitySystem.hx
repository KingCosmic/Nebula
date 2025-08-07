package nebula.tilemap;

import nebula.entitycomponentsystem.System;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.tilemap.IsometricEntityComponent;
import nebula.entitycomponentsystem.Query;
import nebula.entitycomponentsystem.World;
import nebula.entitycomponentsystem.Priority;

class IsometricEntitySystem extends System {
  static var priority: Int = SystemPriority.Lower;

  public var systemType = SystemType.Update;
  var query: Query<Any>;
  public function new(world: World) {
    super();
    this.query = this.world.query([TransformComponent, IsometricEntityComponent]);
  }

  function update(): Void {
    var transform: TransformComponent;
    var iso: IsometricEntityComponent;
    for (entity in this.query.entities) {
      transform = entity.get(TransformComponent);
      iso = entity.get(IsometricEntityComponent);

      final maxZindexPerElevation = Math.max(iso.columns * iso.tileWidth, iso.rows * iso.tileHeight);

      final newZ = maxZindexPerElevation * iso.elevation + transform.pos.y;
      transform.z = newZ;
    }
  }
}
