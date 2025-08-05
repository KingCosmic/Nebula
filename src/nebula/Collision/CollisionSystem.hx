package nebula.Collision;

import nebula.EntityComponentSystem;

import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.System;

import nebula.Events;

import nebula.Collision.SolverStrategy;
import nebula.Collision.Solver.ArcadeSolver;
import nebula.Collision.Solver.RealisticSolver;
import nebula.Collision.Solver.Solver;

import nebula.Collision.Colliders.Collider;
import nebula.Collision.Colliders.CompositeCollider;
import nebula.Collision.Detection.CollisionContact;

import nebula.Collision.ColliderComponent;

import nebula.Engine;
import nebula.Scene;

import nebula.Collision.Side;

import nebula.Graphics.Context.ExcaliburGraphicsContext;
import nebula.Collision.PhysicsWorld;
import nebula.Collision.Detection.CollisionProcessor;

import nebula.Collision.Colliders.SeparatingAxis;
import nebula.Collision.MotionSystem;
import nebula.Collision.Detection.Pair;

class CollisionSystem extends System {
  static priority = SystemPriority.Higher;

  public systemType = SystemType.Update;
  public query: Query<ComponentCtor<TransformComponent> | ComponentCtor<ColliderComponent>>;

  private _engine: Engine;
  private _configDirty = false;
  private _realisticSolver: RealisticSolver;
  private _arcadeSolver: ArcadeSolver;
  private _lastFrameContacts = new Map<String, CollisionContact>();
  private _currentFrameContacts = new Map<String, CollisionContact>();
  private _motionSystem: MotionSystem;
  private get _processor(): CollisionProcessor {
    return this._physics.collisionProcessor;
  }

  private _trackCollider: (c: Collider) => void;
  private _untrackCollider: (c: Collider) => void;

  public function new(
    world: World,
    private _physics: PhysicsWorld
  ) {
    super();
    this._arcadeSolver = new ArcadeSolver(_physics.config.arcade);
    this._realisticSolver = new RealisticSolver(_physics.config.realistic);
    this._physics.$configUpdate.subscribe(() => (this._configDirty = true));
    this._trackCollider = (c: Collider) => this._processor.track(c);
    this._untrackCollider = (c: Collider) => this._processor.untrack(c);
    this.query = world.query([TransformComponent, ColliderComponent]);
    this.query.entityAdded$.subscribe((e) => {
      final colliderComponent = e.get(ColliderComponent);
      colliderComponent.$colliderAdded.subscribe(this._trackCollider);
      colliderComponent.$colliderRemoved.subscribe(this._untrackCollider);
      final collider = colliderComponent.get();
      if (collider) {
        this._processor.track(collider);
      }
    });
    this.query.entityRemoved$.subscribe((e) => {
      final colliderComponent = e.get(ColliderComponent);
      final collider = colliderComponent.get();
      if (colliderComponent && collider) {
        this._processor.untrack(collider);
      }
    });
    this._motionSystem = world.get(MotionSystem) as MotionSystem;
  }

  initialize(world: World, scene: Scene) {
    this._engine = scene.engine;
  }

  update(elapsed: Float): void {
    if (!this._physics.config.enabled) {
      return;
    }

    // TODO do we need to do this every frame?
    // Collect up all the colliders and update them
    var colliders: Collider[] = [];
    for (var entityIndex = 0; entityIndex < this.query.entities.length; entityIndex++) {
      final entity = this.query.entities[entityIndex];
      final colliderComp = entity.get(ColliderComponent);
      final collider = colliderComp?.get();
      if (colliderComp && colliderComp.owner?.isActive && collider) {
        colliderComp.update();

        // Flatten composite colliders
        if (collider instanceof CompositeCollider) {
          final compositeColliders = collider.getColliders();
          if (!collider.compositeStrategy) {
            collider.compositeStrategy = this._physics.config.colliders.compositeStrategy;
          }
          colliders = colliders.concat(compositeColliders);
        } else {
          colliders.push(collider);
        }
      }
    }

    // Update the spatial partitioning data structures
    // TODO if collider invalid it will break the processor
    // TODO rename "update" to something more specific
    this._processor.update(colliders, elapsed);

    // Run broadphase on all colliders and locates potential collisions
    var pairs = this._processor.broadphase(colliders, elapsed);

    this._currentFrameContacts.clear();

    // Given possible pairs find actual contacts
    var contacts: CollisionContact[] = [];

    final solver: CollisionSolver = this.getSolver();

    // Solve, this resolves the position/velocity so entities aren't overlapping
    final substep = this._physics.config.substep;
    for (let step = 0; step < substep; step++) {
      if (step > 0) {
        // first step is run by the MotionSystem when configured, so skip
        this._motionSystem.update(elapsed);
      }
      // Re-use pairs from previous collision
      if (contacts.length) {
        pairs = contacts.map((c) => new Pair(c.colliderA, c.colliderB));
      }

      if (pairs.length) {
        contacts = this._processor.narrowphase(pairs, this._engine?.debug?.stats?.currFrame);
        contacts = solver.solve(contacts);

        // Record contacts for start/end
        for (final contact of contacts) {
          if (contact.isCanceled()) {
            continue;
          }
          // Process composite ids, things with the same composite id are treated as the same collider for start/end
          final index = contact.id.indexOf('|');
          if (index > 0) {
            final compositeId = contact.id.substring(index + 1);
            this._currentFrameContacts.set(compositeId, contact);
          } else {
            this._currentFrameContacts.set(contact.id, contact);
          }
        }
      }
    }

    // Emit contact start/end events
    this.runContactStartEnd();

    // reset the last frame cache
    this._lastFrameContacts.clear();

    // Keep track of collisions contacts that have started or ended
    this._lastFrameContacts = new Map(this._currentFrameContacts);

    // Process deferred collider removals
    for (final entity of this.query.entities) {
      final collider = entity.get(ColliderComponent);
      if (collider) {
        collider.processColliderRemoval();
      }
    }
  }

  postupdate(): void {
    SeparatingAxis.SeparationPool.done();
  }

  getSolver(): CollisionSolver {
    if (this._configDirty) {
      this._configDirty = false;
      this._arcadeSolver = new ArcadeSolver(this._physics.config.arcade);
      this._realisticSolver = new RealisticSolver(this._physics.config.realistic);
    }
    return this._physics.config.solver === SolverStrategy.Realistic ? this._realisticSolver : this._arcadeSolver;
  }

  debug(ex: ExcaliburGraphicsContext) {
    this._processor.debug(ex, 0);
  }

  public runContactStartEnd() {
    // If composite colliders are 'together' collisions may have a duplicate id because we want to treat those as a singular start/end
    for (final [id, c] of this._currentFrameContacts) {
      // find all new contacts
      if (!this._lastFrameContacts.has(id)) {
        final colliderA = c.colliderA;
        final colliderB = c.colliderB;
        final side = Side.fromDirection(c.mtv);
        final opposite = Side.getOpposite(side);
        colliderA.events.emit('collisionstart', new CollisionStartEvent(colliderA, colliderB, side, c));
        colliderA.events.emit('contactstart', new ContactStartEvent(colliderA, colliderB, side, c) as any);
        colliderB.events.emit('collisionstart', new CollisionStartEvent(colliderB, colliderA, opposite, c));
        colliderB.events.emit('contactstart', new ContactStartEvent(colliderB, colliderA, opposite, c) as any);
      }
    }

    // find all contacts that have ceased
    for (final [id, c] of this._lastFrameContacts) {
      if (!this._currentFrameContacts.has(id)) {
        final colliderA = c.colliderA;
        final colliderB = c.colliderB;
        final side = Side.fromDirection(c.mtv);
        final opposite = Side.getOpposite(side);
        colliderA.events.emit('collisionend', new CollisionEndEvent(colliderA, colliderB, side, c));
        colliderA.events.emit('contactend', new ContactEndEvent(colliderA, colliderB, side, c) as any);
        colliderB.events.emit('collisionend', new CollisionEndEvent(colliderB, colliderA, opposite, c));
        colliderB.events.emit('contactend', new ContactEndEvent(colliderB, colliderA, opposite, c) as any);
      }
    }
  }
}
