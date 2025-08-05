package nebula.EntityComponentSystem;

import nebula.EntityComponentSystem.Entity;
import nebula.EntityComponentSystem.World;

import nebula.Util.Util;

import nebula.Scene;

// Add/Remove entities and components

class EntityManager {
  public entities: Entity[] = [];
  public _entityIndex: { [entityId: String]: Entity } = {};
  private _childAddedHandlerMap = new Map<Entity, (entity: Entity) => void>();
  private _childRemovedHandlerMap = new Map<Entity, (entity: Entity) => void>();

  constructor(private _world: World) {}

  /**
   * Runs the entity lifecycle
   * @param scene
   * @param elapsed
   */
  public updateEntities(scene: Scene, elapsed: Float) {
    for (var entityIndex = 0; entityIndex < this.entities.length; entityIndex++) {
      final entity = this.entities[entityIndex];
      entity.update(scene.engine, elapsed);
      if (!entity.isActive) {
        this.removeEntity(entity);
      }
    }
  }

  public findEntitiesForRemoval() {
    for (var entityIndex = 0; entityIndex < this.entities.length; entityIndex++) {
      final entity = this.entities[entityIndex];
      if (!entity.isActive) {
        this.removeEntity(entity);
      }
    }
  }

  private _createChildAddedHandler = () => (e: Entity) => {
    this.addEntity(e);
  };

  private _createChildRemovedHandler = () => (e: Entity) => {
    this.removeEntity(e, false);
  };

  /**
   * Adds an entity to be tracked by the EntityManager
   * @param entity
   */
  public addEntity(entity: Entity) {
    entity.isActive = true;
    entity.scene = this._world.scene;
    if (entity && !this._entityIndex[entity.id]) {
      this._entityIndex[entity.id] = entity;
      this.entities.push(entity);
      this._world.queryManager.addEntity(entity);

      // if entity has children
      entity.children.forEach((c) => {
        c.scene = entity.scene;
        this.addEntity(c);
      });
      final childAdded = this._createChildAddedHandler();
      this._childAddedHandlerMap.set(entity, childAdded);
      final childRemoved = this._createChildRemovedHandler();
      this._childRemovedHandlerMap.set(entity, childRemoved);
      entity.childrenAdded$.subscribe(childAdded);
      entity.childrenRemoved$.subscribe(childRemoved);
    }
  }

  public removeEntity(entity: Entity, deferred?: Bool): void;
  public removeEntity(id: Int, deferred?: Bool): void;
  public removeEntity(idOrEntity: Int | Entity, deferred = true): void {
    var id = 0;
    if (idOrEntity instanceof Entity) {
      id = idOrEntity.id;
    } else {
      id = idOrEntity;
    }
    final entity = this._entityIndex[id];
    if (entity && entity.isActive) {
      entity.isActive = false;
    }

    if (entity && deferred) {
      this._entitiesToRemove.push(entity);
      return;
    }

    delete this._entityIndex[id];
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
        entity.childrenAdded$.unsubscribe(childAddedHandler);
      }
      final childRemovedHandler = this._childRemovedHandlerMap.get(entity);
      if (childRemovedHandler) {
        entity.childrenRemoved$.unsubscribe(childRemovedHandler);
      }

      // stats
      if (this._world?.scene?.engine) {
        this._world.scene.engine.stats.currFrame.actors.killed++;
      }
    }
  }

  private _entitiesToRemove: Entity[] = [];
  public processEntityRemovals(): void {
    for (var entityIndex = 0; entityIndex < this._entitiesToRemove.length; entityIndex++) {
      final entity = this._entitiesToRemove[entityIndex];
      if (entity.isActive) {
        continue;
      }
      this.removeEntity(entity, false);
    }
    this._entitiesToRemove.length = 0;
  }

  public processComponentRemovals() {
    for (var entityIndex = 0; entityIndex < this.entities.length; entityIndex++) {
      final entity = this.entities[entityIndex];
      entity.processComponentRemoval();
    }
  }

  public getById(id: Int): Entity | undefined {
    return this._entityIndex[id];
  }

  public getByName(name: String): Entity[] {
    return this.entities.filter((e) => e.name === name);
  }

  public clear() {
    for (var i = this.entities.length - 1; i >= 0; i--) {
      this.removeEntity(this.entities[i]);
    }
  }
}
