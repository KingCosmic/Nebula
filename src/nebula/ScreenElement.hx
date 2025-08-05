package nebula;

import nebula.Math.Vector;
import nebula.Engine;
import nebula.Actor;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.Collision.CollisionType;
import nebula.Math.CoordPlane;

/**
 * Type guard to detect a screen element
 */

/**
 * Helper {@apilink Actor} primitive for drawing UI's, optimized for UI drawing. Does
 * not participate in collisions. Drawn on top of all other actors.
 */
class ScreenElement extends Actor {
  private var _engine: Engine;

  public static function isScreenElement(actor: Actor) {
    return Std.isTypeOf(actor, ScreenElement);
  }

  public function new(?config: ActorArgs) {
    super(config);
    this.get(TransformComponent).coordPlane = CoordPlane.Screen;
    this.anchor = config?.anchor ?? vec(0, 0);
    this.body.collisionType = config?.collisionType ?? CollisionType.PreventCollision;
    this.pointer.useGraphicsBounds = true;
    this.pointer.useColliderShape = false;
    if (!config?.collider && config?.width > 0 && config?.height > 0) {
      this.collider.useBoxCollider(this.width, this.height, this.anchor);
    }
  }

  public function _initialize(engine: Engine) {
    this._engine = engine;
    super._initialize(engine);
  }

  public function contains(x: Int, y: Int, useWorld: Bool = true) {
    if (useWorld) {
      return super.contains(x, y);
    }

    final coords = this._engine.worldToScreenCoordinates(new Vector(x, y));
    return super.contains(coords.x, coords.y);
  }
}
