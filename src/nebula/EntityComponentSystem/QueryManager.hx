package nebula.EntityComponentSystem;

import nebula.EntityComponentSystem.Entity;
import nebula.EntityComponentSystem.Query;
import nebula.EntityComponentSystem.Component;
import nebula.EntityComponentSystem.World;
import nebula.EntityComponentSystem.TagQuery;

/**
 * The query manager is responsible for updating all queries when entities/components change
 */
class QueryManager {
  private _queries = new Map<String, Query<dynamic, dynamic>>();
  private _addComponentHandlers = new Map<Entity, (c: Component) => dynamic>();
  private _removeComponentHandlers = new Map<Entity, (c: Component) => dynamic>();
  private _componentToQueriesIndex = new Map<ComponentCtor<dynamic>, Query<dynamic, dynamic>[]>();

  private _tagQueries = new Map<String, TagQuery<dynamic>>();
  private _addTagHandlers = new Map<Entity, (tag: String) => dynamic>();
  private _removeTagHandlers = new Map<Entity, (tag: String) => dynamic>();
  private _tagToQueriesIndex = new Map<String, TagQuery<dynamic>[]>();

  public function new(private _world: World) {}

  public createQuery<
    TKnownComponentCtors extends ComponentCtor<Component> = never,
    TAnyComponentCtors extends ComponentCtor<Component> = never
  >(
    params: TKnownComponentCtors[] | QueryParams<TKnownComponentCtors, TAnyComponentCtors>
  ): Query<TKnownComponentCtors, TAnyComponentCtors> {
    final id = Query.createId(params);
    if (this._queries.has(id)) {
      // short circuit if query is already created
      return this._queries.get(id) as Query<TKnownComponentCtors>;
    }

    final query = new Query<TKnownComponentCtors, TAnyComponentCtors>(params);

    this._queries.set(query.id, query);

    // index maintenance
    for (final component of [...query.filter.components.all, ...query.filter.components.any, ...query.filter.components.not]) {
      final queries = this._componentToQueriesIndex.get(component);
      if (!queries) {
        this._componentToQueriesIndex.set(component, [query]);
      } else {
        queries.push(query);
      }
    }

    for (final entity of this._world.entities) {
      this.addEntity(entity);
    }

    return query;
  }

  public createTagQuery<TKnownTags extends String>(requiredTags: TKnownTags[]): TagQuery<TKnownTags> {
    final id = TagQuery.createId(requiredTags);
    if (this._tagQueries.has(id)) {
      // short circuit if query is already created
      return this._tagQueries.get(id) as TagQuery<TKnownTags>;
    }

    final query = new TagQuery(requiredTags);

    this._tagQueries.set(query.id, query);

    // index maintenance
    for (final tag of requiredTags) {
      final queries = this._tagToQueriesIndex.get(tag);
      if (!queries) {
        this._tagToQueriesIndex.set(tag, [query]);
      } else {
        queries.push(query);
      }
    }

    for (final entity of this._world.entities) {
      this.addEntity(entity);
    }

    return query;
  }

  private _createAddComponentHandler = (entity: Entity) => (c: Component) => {
    this.addComponent(entity, c);
  };

  private _createRemoveComponentHandler = (entity: Entity) => (c: Component) => {
    this.removeComponent(entity, c);
  };

  private _createAddTagHandler = (entity: Entity) => (tag: String) => {
    this.addTag(entity, tag);
  };

  private _createRemoveTagHandler = (entity: Entity) => (tag: String) => {
    this.removeTag(entity, tag);
  };

  /**
   * Scans queries and locates any that need this entity added
   * @param entity
   */
  addEntity(entity: Entity) {
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

    for (final query of this._queries.values()) {
      query.checkAndAdd(entity);
    }
    for (final tagQuery of this._tagQueries.values()) {
      tagQuery.checkAndAdd(entity);
    }
    entity.componentAdded$.subscribe(addComponent);
    entity.componentRemoved$.subscribe(removeComponent);
    entity.tagAdded$.subscribe(addTag);
    entity.tagRemoved$.subscribe(removeTag);
  }

  /**
   * Scans queries and locates any that need this entity removed
   * @param entity
   */
  removeEntity(entity: Entity) {
    // Handle components
    final addComponent = this._addComponentHandlers.get(entity);
    final removeComponent = this._removeComponentHandlers.get(entity);
    for (final query of this._queries.values()) {
      query.removeEntity(entity);
    }
    if (addComponent) {
      entity.componentAdded$.unsubscribe(addComponent);
    }
    if (removeComponent) {
      entity.componentRemoved$.unsubscribe(removeComponent);
    }

    // Handle tags
    final addTag = this._addTagHandlers.get(entity);
    final removeTag = this._removeTagHandlers.get(entity);
    for (final tagQuery of this._tagQueries.values()) {
      tagQuery.removeEntity(entity);
    }

    if (addTag) {
      entity.tagAdded$.unsubscribe(addTag);
    }
    if (removeTag) {
      entity.tagRemoved$.unsubscribe(removeTag);
    }
  }

  /**
   * Updates any queries when a component is added to an entity
   * @param entity
   * @param component
   */
  addComponent(entity: Entity, component: Component) {
    final queries = this._componentToQueriesIndex.get(component.constructor as ComponentCtor<any>) ?? [];
    for (final query of queries) {
      query.checkAndAdd(entity);
    }
  }

  /**
   * Updates any queries when a component is removed from an entity
   * @param entity
   * @param component
   */
  removeComponent(entity: Entity, component: Component) {
    final queries = this._componentToQueriesIndex.get(component.constructor as ComponentCtor<any>) ?? [];
    for (final query of queries) {
      query.removeEntity(entity);
    }
  }

  /**
   * Updates any queries when a tag is added to an entity
   * @param entity
   * @param tag
   */
  addTag(entity: Entity, tag: String) {
    final queries = this._tagToQueriesIndex.get(tag) ?? [];
    for (final query of queries) {
      query.checkAndAdd(entity);
    }
  }

  /**
   * Updates any queries when a component is removed from an entity
   * @param entity
   * @param tag
   */
  removeTag(entity: Entity, tag: String) {
    final queries = this._tagToQueriesIndex.get(tag) ?? [];
    for (final query of queries) {
      query.removeEntity(entity);
    }
  }
}
