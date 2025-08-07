package nebula.input;

import nebula.Engine;
import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.World;
import nebula.entitycomponentsystem.Query;
import nebula.entitycomponentsystem.System;
import nebula.entitycomponentsystem.Priority;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.graphics.GraphicsComponent;
import nebula.Scene;
import nebula.input.PointerComponent;
import nebula.input.PointerEventReceiver;
import nebula.math.CoordPlane;
import nebula.collision.detection.SparseHashGrid;
import nebula.input.PointerEventsToObjectDispatcher;

/**
 * The PointerSystem is responsible for dispatching pointer events to entities
 * that need them.
 *
 * The PointerSystem can be optionally configured by the {@apilink PointerComponent}, by default Entities use
 * the {@apilink Collider}'s shape for pointer events.
 */
class PointerSystem extends System {
  static var priority = SystemPriority.Higher;

  public var systemType = SystemType.Update;

  private var _engine: Engine;
  private var _receivers: Array<PointerEventReceiver>;
  private var _engineReceiver: PointerEventReceiver;
  private var _graphicsHashGrid = new SparseHashGrid<GraphicsComponent>({ size: 100 });
  private var _graphics: Array<GraphicsComponent> = [];
  private var _entityToPointer = new Map<Entity, PointerComponent>();
  private var _pointerEventDispatcher = new PointerEventsToObjectDispatcher();

  var query: Query<Any>;

  public function new(world: World) {
    super();
    this.query = this.world.query([TransformComponent, PointerComponent]);

    this.query.entityAdded.subscribe((e) -> {
      final tx = e.get(TransformComponent);
      final pointer = e.get(PointerComponent);
      this._pointerEventDispatcher.addObject(
        e,
        (pos) -> {
          // If pointer bounds defined
          if (pointer && pointer.localBounds) {
            final pointerBounds = pointer.localBounds.transform(tx.get().matrix);
            return pointerBounds.contains(tx.coordPlane == CoordPlane.World ? pos.worldPos : pos.screenPos);
          }
          return false;
        },
        () -> e.isActive
      );
      this._entityToPointer.set(e, pointer);
      final maybeGfx = e.get(GraphicsComponent);
      if (maybeGfx) {
        this._graphics.push(maybeGfx);
        this._graphicsHashGrid.track(maybeGfx);
      }
      this._sortedTransforms.push(tx);
      this._sortedEntities.push(tx.owner);
      tx.zIndexChanged.subscribe(this._zIndexUpdate);
      this._zHasChanged = true;
    });

    this.query.entityRemoved.subscribe((e) -> {
      this._pointerEventDispatcher.removeObject(e);
      final tx = e.get(TransformComponent);
      this._entityToPointer.delete(e);
      final maybeGfx = e.get(GraphicsComponent);
      if (maybeGfx) {
        final index = this._graphics.indexOf(maybeGfx);
        if (index > -1) {
          this._graphics.splice(index, 1);
        }
        this._graphicsHashGrid.untrack(maybeGfx);
      }
      tx.zIndexChanged.unsubscribe(this._zIndexUpdate);
      final index = this._sortedTransforms.indexOf(tx);
      if (index > -1) {
        this._sortedTransforms.splice(index, 1);
        this._sortedEntities.splice(index, 1);
      }
    });
  }

  /**
   * Optionally override component configuration for all entities
   */
  public var overrideUseColliderShape = false;
  /**
   * Optionally override component configuration for all entities
   */
  public var overrideUseGraphicsBounds = false;

  private var _scene: Scene;

  public function initialize(world: World, scene: Scene): Void {
    this._engine = scene.engine;
    this._scene = scene;
  }

  private var _sortedTransforms: Array<TransformComponent> = [];
  private var _sortedEntities: Array<Entity> = [];

  private var _zHasChanged = false;
  private var _zIndexUpdate = () -> {
    this._zHasChanged = true;
  };

  public function preupdate(): Void {
    if (this._scene.camera.hasChanged()) {
      // if the camera has changed we want to force a transform update so pointers can be correctly calc'd
      this._scene.camera.updateTransform(this._scene.camera.pos);
    }

    // event receiver might change per frame
    this._receivers = [this._engine.input.pointers, this._scene.input.pointers];
    this._engineReceiver = this._engine.input.pointers;
    if (this._zHasChanged) {
      this._sortedTransforms.sort((a, b) -> {
        return b.z - a.z;
      });
      this._sortedEntities = this._sortedTransforms.map((t) -> t.owner);
      this._zHasChanged = false;
    }
  }

  public function update(): Void {
    // Update graphics
    this._graphicsHashGrid.update(this._graphics);

    // Locate all the pointer/entity mappings
    for (pointerId => pos in this._engineReceiver.currentFramePointerCoords) {
      final colliders = this._scene.physics.query(pos.worldPos);
      for (collider in colliders) {
        final maybePointer = this._entityToPointer.get(collider.owner);
        if (maybePointer && (maybePointer.useColliderShape || this.overrideUseColliderShape)) {
          this._pointerEventDispatcher.addPointerToObject(collider.owner, pointerId);
        }
      }

      final graphics = this._graphicsHashGrid.query(pos.worldPos);
      for (graphic in graphics) {
        final maybePointer = this._entityToPointer.get(graphic.owner);
        if (maybePointer && (maybePointer.useGraphicsBounds || this.overrideUseGraphicsBounds)) {
          this._pointerEventDispatcher.addPointerToObject(graphic.owner, pointerId);
        }
      }
    }

    this._pointerEventDispatcher.processPointerToObject(this._engineReceiver, this._sortedEntities);

    // Dispatch pointer events on entities
    this._pointerEventDispatcher.dispatchEvents(this._engineReceiver, this._sortedEntities);

    // Dispatch pointer events on top level pointers
    this._receivers.forEach((r) -> r.update());

    // Clear last frame's events
    this._pointerEventDispatcher.clear();

    this._receivers.forEach((r) -> r.clear());
  }
}
