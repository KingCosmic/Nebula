package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.Query;
import nebula.entitycomponentsystem.Component;
import nebula.entitycomponentsystem.World;
import nebula.entitycomponentsystem.TagQuery;

/**
 * The query manager is responsible for updating all queries when entities/components change
 */
class QueryManager {
  private var _queries = new Map<String, Query>();
  private var _addComponentHandlers = new Map<Entity, (c: Component) -> Any>();
  private var _removeComponentHandlers = new Map<Entity, (c: Component) -> Any>();
  private var _componentToQueriesIndex = new Map<Any, Array<Query>>();

  private var _tagQueries = new Map<String, TagQuery<Any>>();
  private var _addTagHandlers = new Map<Entity, (tag: String) -> Any>();
  private var _removeTagHandlers = new Map<Entity, (tag: String) -> Any>();
  private var _tagToQueriesIndex = new Map<String, Array<TagQuery<Any>>>();

  public function new(_world: World) {}

  public function createQuery(
    params: QueryParams
  ): Query {
    final id = Query.createId(params);
    if (this._queries.has(id)) {
      // short circuit if query is already created
      return this._queries.get(id);
    }

    final query = new Query(params);

    this._queries.set(query.id, query);

    // index maintenance
    for (component in [...query.filter.components.all, ...query.filter.components.any, ...query.filter.components.not]) {
      final queries = this._componentToQueriesIndex.get(component);
      if (!queries) {
        this._componentToQueriesIndex.set(component, [query]);
      } else {
        queries.push(query);
      }
    }

    for (entity in this._world.entities) {
      this.addEntity(entity);
    }

    return query;
  }

  public function createTagQuery(requiredTags: Array<String>): TagQuery {
    final id = TagQuery.createId(requiredTags);
    if (this._tagQueries.has(id)) {
      // short circuit if query is already created
      return this._tagQueries.get(id);
    }

    final query = new TagQuery(requiredTags);

    this._tagQueries.set(query.id, query);

    // index maintenance
    for (tag in requiredTags) {
      final queries = this._tagToQueriesIndex.get(tag);
      if (!queries) {
        this._tagToQueriesIndex.set(tag, [query]);
      } else {
        queries.push(query);
      }
    }

    for (entity in this._world.entities) {
      this.addEntity(entity);
    }

    return query;
  }

  private var _createAddComponentHandler = (entity: Entity) -> (c: Component) -> {
    this.addComponent(entity, c);
  };

  private var _createRemoveComponentHandler = (entity: Entity) -> (c: Component) -> {
    this.removeComponent(entity, c);
  };

  private var _createAddTagHandler = (entity: Entity) -> (tag: String) -> {
    this.addTag(entity, tag);
  };

  private var _createRemoveTagHandler = (entity: Entity) -> (tag: String) -> {
    this.removeTag(entity, tag);
  };

  /**
   * Scans queries and locates any that need this entity added
   * @param entity
   */
  function addEntity(entity: Entity) {
    final maybeAddComponent = this._addComponentHandlers.get(entity);
    final maybeRemoveComponent = this._removeComponentHandlers.get(entity);
    final addComponent = maybeAddComponent ?? this._createAddComponentHandler(entity);
    final removeComponent = maybeRemoveComponent ?? this._createRemoveComponentHandler(entity);
    this._addComponentHandlers.set(entity, addComponent);
    this._removeComponentHandlers.set(entity, removeComponent);

    final maybeAddTag = this._addTagHandlers.get(entity);
    final maybeRemoveTag = this._removeTagHandlers.get(entity);
    final addTag = maybeAddTag ?? this._createAddTagHandler(entity);
    final removeTag = maybeRemoveTag ?? this._createRemoveTagHandler(entity);
    this._addTagHandlers.set(entity, addTag);
    this._removeTagHandlers.set(entity, removeTag);

    for (query in this._queries.values()) {
      query.checkAndAdd(entity);
    }
    for (tagQuery in this._tagQueries.values()) {
      tagQuery.checkAndAdd(entity);
    }
    entity.componentAdded.subscribe(addComponent);
    entity.componentRemoved.subscribe(removeComponent);
    entity.tagAdded.subscribe(addTag);
    entity.tagRemoved.subscribe(removeTag);
  }

  /**
   * Scans queries and locates any that need this entity removed
   * @param entity
   */
  function removeEntity(entity: Entity) {
    // Handle components
    final addComponent = this._addComponentHandlers.get(entity);
    final removeComponent = this._removeComponentHandlers.get(entity);
    for (query in this._queries.values()) {
      query.removeEntity(entity);
    }
    if (addComponent) {
      entity.componentAdded.unsubscribe(addComponent);
    }
    if (removeComponent) {
      entity.componentRemoved.unsubscribe(removeComponent);
    }

    // Handle tags
    final addTag = this._addTagHandlers.get(entity);
    final removeTag = this._removeTagHandlers.get(entity);
    for (tagQuery in this._tagQueries.values()) {
      tagQuery.removeEntity(entity);
    }

    if (addTag) {
      entity.tagAdded.unsubscribe(addTag);
    }
    if (removeTag) {
      entity.tagRemoved.unsubscribe(removeTag);
    }
  }

  /**
   * Updates any queries when a component is added to an entity
   * @param entity
   * @param component
   */
  function addComponent(entity: Entity, component: Component) {
    final queries = this._componentToQueriesIndex.get(component.constructor) ?? [];
    for (query in queries) {
      query.checkAndAdd(entity);
    }
  }

  /**
   * Updates any queries when a component is removed from an entity
   * @param entity
   * @param component
   */
  function removeComponent(entity: Entity, component: Component) {
    final queries = this._componentToQueriesIndex.get(component.constructor) ?? [];
    for (query in queries) {
      query.removeEntity(entity);
    }
  }

  /**
   * Updates any queries when a tag is added to an entity
   * @param entity
   * @param tag
   */
  function addTag(entity: Entity, tag: String) {
    final queries = this._tagToQueriesIndex.get(tag) ?? [];
    for (query in queries) {
      query.checkAndAdd(entity);
    }
  }

  /**
   * Updates any queries when a component is removed from an entity
   * @param entity
   * @param tag
   */
  function removeTag(entity: Entity, tag: String) {
    final queries = this._tagToQueriesIndex.get(tag) ?? [];
    for (query in queries) {
      query.removeEntity(entity);
    }
  }
}
