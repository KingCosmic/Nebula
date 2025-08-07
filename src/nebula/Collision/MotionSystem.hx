package nebula.collision;

import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.Query;
import nebula.entitycomponentsystem.World;
import nebula.entitycomponentsystem.SystemPriority;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.System;
import nebula.collision.BodyComponent;
import nebula.collision.CollisionType;
import nebula.collision.Integrator;
import nebula.collision.PhysicsWorld;

class MotionSystem extends System {
  static var priority = SystemPriority.Higher;

  public var systemType = SystemType.Update;
  private var _physicsConfigDirty = false;
  var query: Query;
  public function new(
    world: World,
    physics: PhysicsWorld
  ) {
    super();
    physics.$configUpdate.subscribe(() -> (this._physicsConfigDirty = true));
    this.query = this.world.query([TransformComponent, MotionComponent]);
  }

  function update(elapsed: Int) {
    var transform: TransformComponent;
    var motion: MotionComponent;
    final entities = this.query.entities;
    final substep = this.physics.config.substep;

    for (i in 0...entities.length) {
      transform = entities[i].get(TransformComponent);
      motion = entities[i].get(MotionComponent);

      final optionalBody = entities[i].get(BodyComponent);
      if (this._physicsConfigDirty && optionalBody) {
        optionalBody.updatePhysicsConfig(this.physics.config.bodies);
      }

      if (optionalBody?.isSleeping) {
        continue;
      }

      final totalAcc = motion.acc.clone();
      if (optionalBody.collisionType == CollisionType.Active && optionalBody.useGravity) {
        totalAcc.addEqual(this.physics.config.gravity);
      }

      // capture old transform of this entity and all of its children so that
      // any transform properties that derived from their parents are properly captured
      if (!entities[i].parent) {
        this.captureOldTransformWithChildren(entities[i]);
      }

      // Update transform and motion based on Euler linear algebra
      EulerIntegrator.integrate(transform, motion, totalAcc, elapsed / substep);
    }
    this._physicsConfigDirty = false;
  }

  function captureOldTransformWithChildren(entity: Entity) {
    entity.get(BodyComponent)?.captureOldTransform();

    for (i in 0...entity.children.length) {
      this.captureOldTransformWithChildren(entity.children[i]);
    }
  }
}
