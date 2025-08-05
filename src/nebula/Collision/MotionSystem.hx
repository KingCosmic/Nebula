package nebula.Collision;

import nebula.EntityComponentSystem.Entity;
import nebula.EntityComponentSystem.Query;
import nebula.EntityComponentSystem.World;
import nebula.EntityComponentSystem.SystemPriority;
import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.System;
import nebula.Collision.BodyComponent;
import nebula.Collision.CollisionType;
import nebula.Collision.Integrator;
import nebula.Collision.PhysicsWorld;

class MotionSystem extends System {
  static priority = SystemPriority.Higher;

  public systemType = SystemType.Update;
  private _physicsConfigDirty = false;
  query: Query<typeof TransformComponent | typeof MotionComponent>;
  public function new(
    public world: World,
    public physics: PhysicsWorld
  ) {
    super();
    physics.$configUpdate.subscribe(() => (this._physicsConfigDirty = true));
    this.query = this.world.query([TransformComponent, MotionComponent]);
  }

  update(elapsed: Float) {
    var transform: TransformComponent;
    var motion: MotionComponent;
    final entities = this.query.entities;
    final substep = this.physics.config.substep;

    for (var i = 0; i < entities.length; i++) {
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
      if (optionalBody?.collisionType === CollisionType.Active && optionalBody?.useGravity) {
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

  captureOldTransformWithChildren(entity: Entity) {
    entity.get(BodyComponent)?.captureOldTransform();

    for (var i = 0; i < entity.children.length; i++) {
      this.captureOldTransformWithChildren(entity.children[i]);
    }
  }
}
