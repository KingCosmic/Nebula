package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.Entity;
import nebula.util.Observable;

import nebula.entitycomponentsystem.Component;

interface QueryParams {
  var components: Null<{
    var all: Null<Array<Any>>;
    var any: Null<Array<Any>>;
    var not: Null<Array<Any>>;
  }>;
  var tags: Null<{
    var all: Null<Array<String>>;
    var any: Null<Array<String>>;
    var not: Null<Array<String>>;
  }>;
}

/**
 * Represents query for entities that match a list of types that is cached and observable
 *
 * Queries can be strongly typed by supplying a type union in the optional type parameter
 * ```typescript
 * const queryAB = new ex.Query<ComponentTypeA | ComponentTypeB>(['A', 'B']);
 * ```
 */
class Query {
  public var id: String;

  public var entities: Array<QueryEntity> = [];

  /**
   * This fires right after the component is added
   */
  public var entityAdded = new Observable<QueryEntity>();
  /**
   * This fires right before the component is actually removed from the entity, it will still be available for cleanup purposes
   */
  public var entityRemoved = new Observable<QueryEntity>();

  public var filter = {
    components: {
      all: new Map<TAllComponentCtors, Bool>(),
      any: new Map<TAnyComponentCtors, Bool>(),
      not: new Map<ComponentCtor<Component>, Bool>()
    },
    tags: {
      all: new Map<String, Bool>(),
      any: new Map<String, Bool>(),
      not: new Map<String, Bool>()
    }
  };

  public function new(params: QueryParams) {
    this.filter.components.all = new Set(params.components?.all ?? []);
    this.filter.components.any = new Set(params.components?.any ?? []);
    this.filter.components.not = new Set(params.components?.not ?? []);
    this.filter.tags.all = new Set(params.tags?.all ?? []);
    this.filter.tags.any = new Set(params.tags?.any ?? []);
    this.filter.tags.not = new Set(params.tags?.not ?? []);

    this.id = Query.createId(params);
  }

  static function createId(params: QueryParams) {
    // TODO what happens if a user defines the same type name as a built in type
    // ! TODO this could be dangerous depending on the bundler's settings for names
    // Maybe some kind of hash function is better here?

    final anyComponents = params.components?.any ? 'any_${Query.hashComponents(new Set(params.components?.any))}' : '';
    final allComponents = params.components?.all ? 'all_${Query.hashComponents(new Set(params.components?.all))}' : '';
    final notComponents = params.components?.not ? 'not_${Query.hashComponents(new Set(params.components?.not))}' : '';

    final anyTags = params.tags?.any ? 'any_${Query.hashTags(new Set(params.tags?.any))}' : '';
    final allTags = params.tags?.all ? 'all_${Query.hashTags(new Set(params.tags?.all))}' : '';
    final notTags = params.tags?.not ? 'not_${Query.hashTags(new Set(params.tags?.not))}' : '';

    return [anyComponents, allComponents, notComponents, anyTags, allTags, notTags].filter(Bool).join('-');
  }

  static function hashTags(set: Map<String, Bool>) {
    return Array.from(set)
      .map((t) -> 't_${t}')
      .sort()
      .join('-');
  }

  static function hashComponents(set: Map<Component, Bool>) {
    return Array.from(set)
      .map((c) -> 'c_${c.name}')
      .sort()
      .join('-');
  }

  function matches(entity: Entity): Bool {
    // Components
    // check if entity has all components
    for (component in this.filter.components.all) {
      if (!entity.has(component)) {
        return false;
      }
    }

    // check if entity has any components
    if (this.filter.components.any.size > 0) {
      var found = false;
      for (component in this.filter.components.any) {
        if (entity.has(component)) {
          found = true;
          break;
        }
      }

      if (!found) {
        return false;
      }
    }

    // check if entity has none of the components
    for (component in this.filter.components.not) {
      if (entity.has(component)) {
        return false;
      }
    }

    // Tags
    // check if entity has all tags
    for (tag in this.filter.tags.all) {
      if (!entity.hasTag(tag)) {
        return false;
      }
    }

    // check if entity has any tags
    if (this.filter.tags.any.size > 0) {
      var found = false;
      for (tag in this.filter.tags.any) {
        if (entity.hasTag(tag)) {
          found = true;
          break;
        }
      }

      if (!found) {
        return false;
      }
    }

    // check if entity has none of the tags
    for (tag in this.filter.tags.not) {
      if (entity.hasTag(tag)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Potentially adds an entity to a query index, returns true if added, false if not
   * @param entity
   */
  function checkAndAdd(entity: Entity) {
    if (this.matches(entity) && !this.entities.includes(entity)) {
      this.entities.push(entity);
      this.entityAdded.notifyAll(entity);
      return true;
    }
    return false;
  }

  function removeEntity(entity: Entity) {
    final index = this.entities.indexOf(entity);
    if (index > -1) {
      this.entities.splice(index, 1);
      this.entityRemoved.notifyAll(entity);
    }
  }

  /**
   * Returns a list of entities that match the query
   * @param sort Optional sorting function to sort entities returned from the query
   */
  public function getEntities(?sort: (a: Entity, b: Entity) -> Int): Array<QueryEntity> {
    if (sort) {
      this.entities.sort(sort);
    }
    return this.entities;
  }
}
