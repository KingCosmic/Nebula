package nebula.EntityComponentSystem;

import nebula.EntityComponentSystem.Component;
import nebula.EntityComponentSystem.Types;

import nebula.Interfaces.LifecycleEvents;

import nebula.Engine;

import nebula.Events;
import nebula.EventEmitter;

import nebula.Scene;

import nebula.Util.Observable;
import nebula.Util.Util;
import nebula.Util.Log;

/**
 * Interface holding an entity component pair
 */
interface EntityComponent {
  component: Component;
  entity: Entity;
}

/**
 * AddedComponent message
 */
class AddedComponent implements Message<EntityComponent> {
  readonly type: 'Component Added' = 'Component Added';
  public function new(public data: EntityComponent) {}
}

/**
 * Type guard to know if message is f an Added Component
 */
function isAddedComponent(x: Message<EntityComponent>): x is AddedComponent {
  return !!x && x.type === 'Component Added';
}

/**
 * RemovedComponent message
 */
class RemovedComponent implements Message<EntityComponent> {
  readonly type: 'Component Removed' = 'Component Removed';
  public function new(public data: EntityComponent) {}
}

/**
 * Type guard to know if message is for a Removed Component
 */
function isRemovedComponent(x: Message<EntityComponent>): x is RemovedComponent {
  return !!x && x.type === 'Component Removed';
}

/**
 * Built in events supported by all entities
 */
type EntityEvents = {
  initialize: InitializeEvent;
  //@ts-ignore
  add: AddEvent;
  //@ts-ignore
  remove: RemoveEvent;
  preupdate: PreUpdateEvent;
  postupdate: PostUpdateEvent;
  kill: KillEvent;
};

final EntityEvents = {
  Add: 'add',
  Remove: 'remove',
  Initialize: 'initialize',
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate',
  Kill: 'kill'
};

interface EntityOptions<TComponents extends Component> {
  name?: String;
  components?: TComponents[];
  silenceWarnings?: Bool;
}

/**
 * An Entity is the base type of anything that can have behavior in Excalibur, they are part of the built in entity component system
 *
 * Entities can be strongly typed with the components they contain
 *
 * ```typescript
 * const entity = new Entity<ComponentA | ComponentB>();
 * entity.components.a; // Type ComponentA
 * entity.components.b; // Type ComponentB
 * ```
 */
class Entity<TKnownComponents extends Component = dynamic> implements OnInitialize, OnPreUpdate, OnPostUpdate, OnAdd, OnRemove {
  private static _ID = 0;
  /**
   * The unique identifier for the entity
   */
  public id: Int = Entity._ID++;

  public name = `Entity#${this.id}`;

  /**
   * Listen to or emit events for an entity
   */
  public events = new EventEmitter<EntityEvents>();
  private _tags = new Set<String>();
  public componentAdded$ = new Observable<Component>();
  public componentRemoved$ = new Observable<Component>();
  public tagAdded$ = new Observable<String>();
  public tagRemoved$ = new Observable<String>();
  /**
   * Current components on the entity
   *
   * **Do not modify**
   *
   * Use addComponent/removeComponent otherwise the ECS will not be notified of changes.
   */
  public readonly components = new Map<Function, Component>();
  public componentValues: Component[] = [];
  private _componentsToRemove: ComponentCtor[] = [];

  public function new(options: EntityOptions<TKnownComponents>);
  public function new(components?: TKnownComponents[], name?: String);
  public function new(componentsOrOptions?: TKnownComponents[] | EntityOptions<TKnownComponents>, name?: String) {
    var componentsToAdd!: TKnownComponents[];
    var nameToAdd: String | undefined;
    var silence = false;
    if (Array.isArray(componentsOrOptions)) {
      componentsToAdd = componentsOrOptions;
      nameToAdd = name;
    } else if (componentsOrOptions && typeof componentsOrOptions === 'object') {
      final { components, name, silenceWarnings } = componentsOrOptions;
      componentsToAdd = components ?? [];
      nameToAdd = name;
      silence = !!silenceWarnings;
    }
    if (nameToAdd) {
      this.name = nameToAdd;
    }
    if (componentsToAdd) {
      for (final component of componentsToAdd) {
        this.addComponent(component);
      }
    }

    if (process.env.NODE_ENV === 'development') {
      if (!silence) {
        setTimeout(() => {
          if (!this.scene && !this.isInitialized) {
            Logger.getInstance().warn('Entity "${this.name || this.id}" was not added to a scene.');
          }
        }, 5000);
      }
    }
  }

  /**
   * The current scene that the entity is in, if any
   */
  public scene: Scene | null = null;

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   * @deprecated use isActive
   */
  public get active(): Bool {
    return this.isActive;
  }

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   * @deprecated use isActive
   */
  public set active(val: Bool) {
    this.isActive = val;
  }

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   */
  public isActive: Bool = true;

  /**
   * Kill the entity, means it will no longer be updated. Kills are deferred to the end of the update.
   * If parented it will be removed from the parent when killed.
   */
  public kill() {
    if (this.isActive) {
      this.isActive = false;
      this.unparent();
    }
    this.emit('kill', new KillEvent(this));
  }

  public isKilled() {
    return !this.isActive;
  }

  /**
   * Specifically get the tags on the entity from {@apilink TagsComponent}
   */
  public get tags(): Set<String> {
    return this._tags;
  }

  /**
   * Check if a tag exists on the entity
   * @param tag name to check for
   */
  public hasTag(tag: String): Bool {
    return this._tags.has(tag);
  }

  /**
   * Adds a tag to an entity
   * @param tag
   */
  public addTag(tag: String): Entity<TKnownComponents> {
    this._tags.add(tag);
    this.tagAdded$.notifyAll(tag);
    return this;
  }

  /**
   * Removes a tag on the entity
   *
   * Removals are deferred until the end of update
   * @param tag
   */
  public removeTag(tag: String): Entity<TKnownComponents> {
    this._tags.delete(tag);
    this.tagRemoved$.notifyAll(tag);
    return this;
  }

  /**
   * The types of the components on the Entity
   */
  public get types(): ComponentCtor[] {
    return Array.from(this.components.keys()) as ComponentCtor[];
  }

  /**
   * Returns all component instances on entity
   */
  public getComponents(): Component[] {
    return Array.from(this.components.values());
  }

  /**
   * Verifies that an entity has all the required types
   * @param requiredTypes
   */
  hasAll<TComponent extends Component>(requiredTypes: ComponentCtor<TComponent>[]): Bool {
    for (var i = 0; i < requiredTypes.length; i++) {
      if (!this.components.has(requiredTypes[i])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Verifies that an entity has all the required tags
   * @param requiredTags
   */
  hasAllTags(requiredTags: String[]): Bool {
    for (var i = 0; i < requiredTags.length; i++) {
      if (!this.tags.has(requiredTags[i])) {
        return false;
      }
    }
    return true;
  }

  get<TComponent extends Component>(type: ComponentCtor<TComponent>): MaybeKnownComponent<TComponent, TKnownComponents> {
    return this.components.get(type) as MaybeKnownComponent<TComponent, TKnownComponents>;
  }

  private _parent: Entity | null = null;
  public get parent(): Entity | null {
    return this._parent;
  }

  public childrenAdded$ = new Observable<Entity>();
  public childrenRemoved$ = new Observable<Entity>();

  private _children: Entity[] = [];
  /**
   * Get the direct children of this entity
   */
  public get children(): readonly Entity[] {
    return this._children;
  }

  /**
   * Unparents this entity, if there is a parent. Otherwise it does nothing.
   */
  public unparent() {
    if (this._parent) {
      this._parent.removeChild(this);
      this._parent = null;
    }
  }

  /**
   * Adds an entity to be a child of this entity
   * @param entity
   */
  public addChild(entity: Entity): Entity {
    if (entity.parent === null) {
      if (this.getAncestors().includes(entity)) {
        throw new Error('Cycle detected, cannot add entity');
      }
      this._children.push(entity);
      entity._parent = this;
      this.childrenAdded$.notifyAll(entity);
    } else {
      throw new Error('Entity already has a parent, cannot add without unparenting');
    }
    return this;
  }

  /**
   * Remove an entity from children if it exists
   * @param entity
   */
  public removeChild(entity: Entity): Entity {
    if (entity.parent === this) {
      removeItemFromArray(entity, this._children);
      entity._parent = null;
      this.childrenRemoved$.notifyAll(entity);
    }
    return this;
  }

  /**
   * Removes all children from this entity
   */
  public removeAllChildren(): Entity {
    // Avoid modifying the array issue by walking backwards
    for (var i = this.children.length - 1; i >= 0; i--) {
      this.removeChild(this.children[i]);
    }
    return this;
  }

  /**
   * Returns a list of parent entities starting with the topmost parent. Includes the current entity.
   */
  public getAncestors(): Entity[] {
    final result: Entity[] = [this];
    var current = this.parent;
    while (current) {
      result.push(current);
      current = current.parent;
    }
    return result.reverse();
  }

  /**
   * Returns a list of all the entities that descend from this entity. Includes the current entity.
   */
  public getDescendants(): Entity[] {
    var result: Entity[] = [this];
    var queue: Entity[] = [this];
    while (queue.length > 0) {
      final curr = queue.pop();
      if (curr) {
        queue = queue.concat(curr.children);
        result = result.concat(curr.children);
      }
    }
    return result;
  }

  /**
   * Creates a deep copy of the entity and a copy of all its components
   */
  public clone(): Entity {
    final newEntity = new Entity();
    for (final c of this.types) {
      final componentInstance = this.get(c);
      if (componentInstance) {
        newEntity.addComponent(componentInstance.clone());
      }
    }
    for (final child of this.children) {
      newEntity.addChild(child.clone());
    }
    return newEntity;
  }

  /**
   * Adds a copy of all the components from another template entity as a "prefab"
   * @param templateEntity Entity to use as a template
   * @param force Force component replacement if it already exists on the target entity
   */
  public addTemplate(templateEntity: Entity, force: Bool = false): Entity {
    for (final c of templateEntity.getComponents()) {
      this.addComponent(c.clone(), force);
    }
    for (final child of templateEntity.children) {
      this.addChild(child.clone().addTemplate(child));
    }
    return this;
  }

  private _getClassHierarchyRoot(componentType: ComponentCtor): ComponentCtor {
    var current = componentType;
    var parent = Object.getPrototypeOf(current.prototype)?.constructor;

    while (parent && parent !== Object && parent !== Component) {
      current = parent;
      parent = Object.getPrototypeOf(current.prototype)?.constructor;
    }
    return current;
  }

  /**
   * Adds a component to the entity
   * @param component Component or Entity to add copy of components from
   * @param force Optionally overwrite any existing components of the same type
   */
  public function addComponent<TComponent extends Component>(component: TComponent, force: Bool = false): Entity<TKnownComponents | TComponent> {
    // if component already exists, skip if not forced
    if (this.has(component.constructor as ComponentCtor)) {
      if (force) {
        // Remove existing component type if exists when forced
        this.removeComponent(component.constructor as ComponentCtor, true);
      } else {
        // early exit component exits
        return this as Entity<TKnownComponents | TComponent>;
      }
    }

    // TODO circular dependencies will be a problem
    if (component.dependencies && component.dependencies.length) {
      for (final ctor of component.dependencies) {
        this.addComponent(new ctor());
      }
    }

    component.owner = this;
    final rootComponent = this._getClassHierarchyRoot(component.constructor as ComponentCtor);
    this.components.set(rootComponent, component);
    this.components.set(component.constructor, component);
    this.componentValues.push(component);
    if (component.onAdd) {
      component.onAdd(this);
    }

    this.componentAdded$.notifyAll(component);
    return this as Entity<TKnownComponents | TComponent>;
  }

  /**
   * Removes a component from the entity, by default removals are deferred to the end of entity update to avoid consistency issues
   *
   * Components can be force removed with the `force` flag, the removal is not deferred and happens immediately
   * @param typeOrInstance
   * @param force
   */
  public function removeComponent<TComponent extends Component>(
    typeOrInstance: ComponentCtor<TComponent> | TComponent,
    force = false
  ): Entity<Exclude<TKnownComponents, TComponent>> {
    var type: ComponentCtor<TComponent>;
    if (isComponentCtor(typeOrInstance)) {
      type = typeOrInstance;
    } else {
      type = typeOrInstance.constructor as ComponentCtor<TComponent>;
    }

    if (force) {
      final componentToRemove = this.components.get(type);
      if (componentToRemove) {
        this.componentRemoved$.notifyAll(componentToRemove);
        componentToRemove.owner = undefined;
        if (componentToRemove.onRemove) {
          componentToRemove.onRemove(this);
        }
        final componentIndex = this.componentValues.indexOf(componentToRemove);
        if (componentIndex > -1) {
          this.componentValues.splice(componentIndex, 1);
        }
      }

      final rootComponent = this._getClassHierarchyRoot(type);
      this.components.delete(rootComponent);
      this.components.delete(type); // remove after the notify to preserve typing
    } else {
      this._componentsToRemove.push(type);
    }

    return this as any;
  }

  public clearComponents() {
    final components = this.types;
    for (final c of components) {
      this.removeComponent(c);
    }
  }

  /**
   * @hidden
   * @internal
   */
  public processComponentRemoval() {
    for (final type of this._componentsToRemove) {
      this.removeComponent(type, true);
    }
    this._componentsToRemove.length = 0;
  }

  /**
   * Check if a component type exists
   * @param type
   */
  public function has<TComponent extends Component>(type: ComponentCtor<TComponent>): Bool {
    return this.components.has(type);
  }

  private _isInitialized = false;
  private _isAdded = false;

  /**
   * Gets whether the actor is Initialized
   */
  public get isInitialized(): Bool {
    return this._isInitialized;
  }

  public get isAdded(): Bool {
    return this._isAdded;
  }

  /**
   * Initializes this entity, meant to be called by the Scene before first update not by users of Excalibur.
   *
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   * @internal
   */
  public function _initialize(engine: Engine) {
    if (!this.isInitialized) {
      this.onInitialize(engine);
      this.events.emit('initialize', new InitializeEvent(engine, this));
      this._isInitialized = true;
    }
  }

  /**
   * Adds this Actor, meant to be called by the Scene when Actor is added.
   *
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   * @internal
   */
  public function _add(engine: Engine) {
    if (!this.isAdded && this.isActive) {
      this.onAdd(engine);
      this.events.emit('add', new AddEvent(engine, this));
      this._isAdded = true;
    }
  }

  /**
   * Removes Actor, meant to be called by the Scene when Actor is added.
   *
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   * @internal
   */
  public function _remove(engine: Engine) {
    if (this.isAdded && !this.isActive) {
      this.onRemove(engine);
      this.events.emit('remove', new RemoveEvent(engine, this));
      this._isAdded = false;
    }
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPreUpdate} lifecycle event
   * @internal
   */
  public _preupdate(engine: Engine, elapsed: Float) {
    this.events.emit('preupdate', new PreUpdateEvent(engine, elapsed, this));
    this.onPreUpdate(engine, elapsed);
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPostUpdate} lifecycle event
   * @internal
   */
  public _postupdate(engine: Engine, elapsed: Float) {
    this.events.emit('postupdate', new PostUpdateEvent(engine, elapsed, this));
    this.onPostUpdate(engine, elapsed);
  }

  /**
   * `onInitialize` is called before the first update of the entity. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('initialize', (evt) => {...})`
   */
  public onInitialize(engine: Engine) {
    // Override me
  }

  /**
   * `onAdd` is called when Actor is added to scene. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('add', (evt) => {...})`
   */
  public onAdd(engine: Engine) {
    // Override me
  }

  /**
   * `onRemove` is called when Actor is added to scene. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('remove', (evt) => {...})`
   */
  public onRemove(engine: Engine) {
    // Override me
  }

  /**
   * Safe to override onPreUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreUpdate` is called directly before an entity is updated.
   */
  public onPreUpdate(engine: Engine, elapsed: number) {
    // Override me
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('postupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after an entity is updated.
   */
  public onPostUpdate(engine: Engine, elapsed: Float) {
    // Override me
  }

  /**
   *
   * Entity update lifecycle, called internally
   * @internal
   * @param engine
   * @param elapsed
   */
  public update(engine: Engine, elapsed: Float) {
    this._initialize(engine);
    this._add(engine);
    this._preupdate(engine, elapsed);
    for (final child of this.children) {
      child.update(engine, elapsed);
    }
    this._postupdate(engine, elapsed);
    this._remove(engine);
  }

  public function emit<TEventName extends EventKey<EntityEvents>>(eventName: TEventName, event: EntityEvents[TEventName]): void;
  public function emit(eventName: String, event?: any): void;
  public function emit<TEventName extends EventKey<EntityEvents> | String>(eventName: TEventName, event?: any): void {
    this.events.emit(eventName, event);
  }

  public function on<TEventName extends EventKey<EntityEvents>>(eventName: TEventName, handler: Handler<EntityEvents[TEventName]>): Subscription;
  public function on(eventName: String, handler: Handler<unknown>): Subscription;
  public function on<TEventName extends EventKey<EntityEvents> | String>(eventName: TEventName, handler: Handler<any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public once<TEventName extends EventKey<EntityEvents>>(eventName: TEventName, handler: Handler<EntityEvents[TEventName]>): Subscription;
  public once(eventName: String, handler: Handler<unknown>): Subscription;
  public once<TEventName extends EventKey<EntityEvents> | String>(eventName: TEventName, handler: Handler<any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public off<TEventName extends EventKey<EntityEvents>>(eventName: TEventName, handler: Handler<EntityEvents[TEventName]>): void;
  public off(eventName: String, handler: Handler<unknown>): void;
  public off(eventName: String): void;
  public off<TEventName extends EventKey<EntityEvents> | String>(eventName: TEventName, handler?: Handler<any>): void {
    if (handler) {
      this.events.off(eventName, handler);
    } else {
      this.events.off(eventName);
    }
  }
}
