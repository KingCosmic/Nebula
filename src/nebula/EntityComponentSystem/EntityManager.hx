package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.World;

import nebula.util.Util;

import nebula.Scene;

// Add/Remove entities and components

class EntityManager {
  public var entities: Array<Entity> = [];
  public var _entityIndex: Map<String, Entity> = new Map();
  private var _childAddedHandlerMap = new Map<Entity, (entity: Entity) -> Void>();
  private var _childRemovedHandlerMap = new Map<Entity, (entity: Entity) -> Void>();

  public function new(_world: World) {}

  /**
   * Runs the entity lifecycle
   * @param scene
   * @param elapsed
   */
  public function updateEntities(scene: Scene, elapsed: Float) {
    for (entity in this.entities) {
      entity.update(scene.engine, elapsed);
      if (!entity.isActive) {
        this.removeEntity(entity);
      }
    }
  }

  public function findEntitiesForRemoval() {
    for (entity in this.entities) {
      if (!entity.isActive) {
        this.removeEntity(entity);
      }
    }
  }

  private var _createChildAddedHandler = () -> (e: Entity) -> {
    this.addEntity(e);
  };

  private var _createChildRemovedHandler = () -> (e: Entity) -> {
    this.removeEntity(e, false);
  };

  /**
   * Adds an entity to be tracked by the EntityManager
   * @param entity
   */
  public function addEntity(entity: Entity) {
    entity.isActive = true;
    entity.scene = this._world.scene;
    if (entity && !this._entityIndex[entity.id]) {
      this._entityIndex[entity.id] = entity;
      this.entities.push(entity);
      this._world.queryManager.addEntity(entity);

      // if entity has children
      entity.children.forEach((c) -> {
        c.scene = entity.scene;
        this.addEntity(c);
      });
      final childAdded = this._createChildAddedHandler();
      this._childAddedHandlerMap.set(entity, childAdded);
      final childRemoved = this._createChildRemovedHandler();
      this._childRemovedHandlerMap.set(entity, childRemoved);
      entity.childrenAdded.subscribe(childAdded);
      entity.childrenRemoved.subscribe(childRemoved);
    }
  }

  public function removeEntity(id: Int, deferred = true): Void {
    final entity = this._entityIndex[id];
    if (entity && entity.isActive) {
      entity.isActive = false;
    }

    if (entity && deferred) {
      this._entitiesToRemove.push(entity);
      return;
    }

    this._entityIndex.delete(id);
    if (entity) {
      entity.scene = null;
      removeItemFromArray(entity, this.entities);
      this._world.queryManager.removeEntity(entity);

      // if entity has children
      entity.children.forEach((c) => {
        c.scene = null;
        this.removeEntity(c, deferred);
      });
      final childAddedHandler = this._childAddedHandlerMap.get(entity);
      if (childAddedHandler) {
        entity.childrenAdded.unsubscribe(childAddedHandler);
      }
      final childRemovedHandler = this._childRemovedHandlerMap.get(entity);
      if (childRemovedHandler) {
        entity.childrenRemoved.unsubscribe(childRemovedHandler);
      }

      // stats
      if (this._world?.scene?.engine) {
        this._world.scene.engine.stats.currFrame.actors.killed++;
      }
    }
  }

  private var _entitiesToRemove: Array<Entity> = [];
  public function processEntityRemovals(): Void {
    for (entity in this._entitiesToRemove) {
      if (entity.isActive) {
        continue;
      }
      this.removeEntity(entity, false);
    }
    this._entitiesToRemove.length = 0;
  }

  public function processComponentRemovals() {
    for (entity in this.entities) {
      entity.processComponentRemoval();
    }
  }

  public function getById(id: Int): Null<Entity> {
    return this._entityIndex[id];
  }

  public function getByName(name: String): Array<Entity> {
    return this.entities.filter((e) -> e.name == name);
  }

  public function clear() {
    var i = this.entities.length - 1;
    while (i >= 0) {
      this.removeEntity(this.entities[i]);
      i--;
    }
  }
}
