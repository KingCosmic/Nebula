package nebula.entitycomponentsystem;

import nebula.Scene;
import nebula.util.Log;
import nebula.entitycomponentsystem.Component;
import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.EntityManager;
import nebula.entitycomponentsystem.Query;
import nebula.entitycomponentsystem.QueryManager;
import nebula.entitycomponentsystem.System;
import nebula.entitycomponentsystem.SystemManager;
import nebula.entitycomponentsystem.TagQuery;

/**
 * The World is a self-contained entity component system for a particular context.
 */
class World {
  private var _logger = Logger.getInstance();
  public var queryManager: QueryManager = new QueryManager(this);
  public var entityManager: EntityManager = new EntityManager(this);
  public var systemManager: SystemManager = new SystemManager(this);

  /**
   * The context type is passed to the system updates
   * @param scene
   */
  public function new(scene: Scene) {}

  /**
   * Query the ECS world for entities that match your components
   */
  function query(params: Array<Any>): Query<TKnownComponentCtors, TAnyComponentCtors> {
    return this.queryManager.createQuery(params);
  }

  function queryTags(requiredTags: Array<String>): TagQuery<TKnownTags> {
    return this.queryManager.createTagQuery(requiredTags);
  }

  /**
   * Update systems by type and time elapsed in milliseconds
   */
  function update(type: SystemType, elapsed: Int) {
    if (type == SystemType.Update) {
      this.entityManager.updateEntities(this.scene, elapsed);
    }
    this.systemManager.updateSystems(type, this.scene, elapsed);
    this.entityManager.findEntitiesForRemoval();
    this.entityManager.processComponentRemovals();
    this.entityManager.processEntityRemovals();
  }

  /**
   * Add an entity to the ECS world
   * @param entity
   */
  function add(entityOrSystem: Any) {
    if (Std.isOfType(entityOrSystem, Entity)) {
      this.entityManager.addEntity(entityOrSystem);
      return;
    }

    if (Std.isOfType(entityOrSystem, System) || isSystemConstructor(entityOrSystem)) {
      this.systemManager.addSystem(entityOrSystem);
      return;
    }

    this._logger.warn(
      'Could not add entity/system ${(entityOrSystem as any).constructor.name} to Excalibur!\n\n' +
        'If this looks like an Excalibur type, this can be caused by 2 versions of excalibur being included on the page.\n\n' +
        'Check your bundler settings to make sure this is not the case! Excalibur has ESM & UMD bundles be sure one 1 is loaded.'
    );
  }

  /**
   * Get a system out of the ECS world
   */
  function get(system: SystemCtor<System>) {
    return this.systemManager.get(system);
  }

  /**
   * Remove an entity from the ECS world
   * @param entity
   */
  function remove(entityOrSystem: Any, deferred = true) {
    if (Std.isOfType(entityOrSystem, Entity)) {
      this.entityManager.removeEntity(entityOrSystem, deferred);
      return;
    }

    if (Std.isOfType(entityOrSystem, System)) {
      this.systemManager.removeSystem(entityOrSystem);
      return;
    }

    this._logger.warn(
      'Could not remove entity/system ${(entityOrSystem as any).constructor.name} to Excalibur!\n\n' +
        'If this looks like an Excalibur type, this can be caused by 2 versions of excalibur being included on the page.\n\n' +
        'Check your bundler settings to make sure this is not the case! Excalibur has ESM & UMD bundles be sure one 1 is loaded.'
    );
  }

  public var entities(get, never): Array<Entity>;
  function get_entities() {
    return this.entityManager.entities;
  }

  function clearEntities() {
    this.entityManager.clear();
  }

  function clearSystems() {
    this.systemManager.clear();
  }
}
