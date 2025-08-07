package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.Component;

import nebula.interfaces.LifecycleEvents;

import nebula.Engine;

import nebula.Events;
import nebula.EventEmitter;

import nebula.Scene;

import nebula.util.Observable;
import nebula.util.Util;
import nebula.util.Log;

/**
 * Interface holding an entity component pair
 */
interface EntityComponent {
  var component: Component;
  var entity: Any;
}

/**
 * AddedComponent message
 */
class AddedComponent implements Message<EntityComponent> {
  var type: String = 'Component Added';
  public function new(data: EntityComponent) {}
}

/**
 * Type guard to know if message is f an Added Component
 */
function isAddedComponent(x: Message<EntityComponent>) {
  return !!x && x.type == 'Component Added';
}

/**
 * RemovedComponent message
 */
class RemovedComponent implements Message<EntityComponent> {
  var type: String = 'Component Removed';
  public function new(data: EntityComponent) {}
}

/**
 * Type guard to know if message is for a Removed Component
 */
function isRemovedComponent(x: Message<EntityComponent>) {
  return !!x && x.type == 'Component Removed';
}

/**
 * Built in events supported by all entities
 */
typedef TEntityEvents = {
  var initialize: InitializeEvent;
  var add: AddEvent;
  var remove: RemoveEvent;
  var preupdate: PreUpdateEvent<Actor>;
  var postupdate: PostUpdateEvent<Actor>;
  var kill: KillEvent;
};

final EntityEvents = {
  Add: 'add',
  Remove: 'remove',
  Initialize: 'initialize',
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate',
  Kill: 'kill'
};

interface EntityOptions<TComponents:Component> {
  var name: Null<String>;
  var components: Null<Array<TComponents>>;
  var silenceWarnings: Null<Bool>;
}

/**
 * An Any is the base type of anything that can have behavior in Excalibur, they are part of the built in entity component system
 *
 * Entities can be strongly typed with the components they contain
 *
 * ```typescript
 * const entity = new Any<ComponentA | ComponentB>();
 * entity.components.a; // Type ComponentA
 * entity.components.b; // Type ComponentB
 * ```
 */
class Entity implements OnInitialize implements OnPreUpdate implements OnPostUpdate implements OnAdd implements OnRemove {
  private static var _ID = 0;
  /**
   * The unique identifier for the entity
   */
  public var id: Int = this._ID++;

  public var name = 'Any#${this.id}';

  /**
   * Listen to or emit events for an entity
   */
  public var events = new EventEmitter<TEntityEvents>();
  private var _tags = new Map<String, Bool>();
  public var componentAdded = new Observable<Component>();
  public var componentRemoved = new Observable<Component>();
  public var tagAdded = new Observable<String>();
  public var tagRemoved = new Observable<String>();
  /**
   * Current components on the entity
   *
   * **Do not modify**
   *
   * Use addComponent/removeComponent otherwise the ECS will not be notified of changes.
   */
  public var components = new Map<Function, Component>();
  public var componentValues: Array<Component> = [];
  private var _componentsToRemove: Array<Any> = [];

  public function new(?components: Array<Any>, name: String) {
    var silence = false;
    this.name = nameToAdd;
    if (components) {
      for (component in components) {
        this.addComponent(component);
      }
    }

    // if (process.env.NODE_ENV == 'development') {
    //   if (!silence) {
    //     setTimeout(() => {
    //       if (!this.scene && !this.isInitialized) {
    //         Logger.getInstance().warn('Any "${this.name || this.id}" was not added to a scene.');
    //       }
    //     }, 5000);
    //   }
    // }
  }

  /**
   * The current scene that the entity is in, if any
   */
  public var scene: Null<Scene> = null;

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   * @deprecated use isActive
   */
  public var active(get, set): Bool;
  function get_active(): Bool {
    return this.isActive;
  }

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   * @deprecated use isActive
   */
  function set_active(val: Bool) {
    this.isActive = val;
  }

  /**
   * Whether this entity is active, if set to false it will be reclaimed
   */
  public var isActive: Bool = true;

  /**
   * Kill the entity, means it will no longer be updated. Kills are deferred to the end of the update.
   * If parented it will be removed from the parent when killed.
   */
  public function kill() {
    if (this.isActive) {
      this.isActive = false;
      this.unparent();
    }
    this.emit('kill', new KillEvent(this));
  }

  public function isKilled() {
    return !this.isActive;
  }

  /**
   * Specifically get the tags on the entity from {@apilink TagsComponent}
   */
  public var tags(get, never): Map<String, Bool>;
  function get_tags(): Map<String, Bool> {
    return this._tags;
  }

  /**
   * Check if a tag exists on the entity
   * @param tag name to check for
   */
  public function hasTag(tag: String): Bool {
    return this._tags.has(tag);
  }

  /**
   * Adds a tag to an entity
   * @param tag
   */
  public function addTag(tag: String) {
    this._tags.add(tag);
    this.tagAdded.notifyAll(tag);
    return this;
  }

  /**
   * Removes a tag on the entity
   *
   * Removals are deferred until the end of update
   * @param tag
   */
  public function removeTag(tag: String) {
    this._tags.delete(tag);
    this.tagRemoved.notifyAll(tag);
    return this;
  }

  /**
   * The types of the components on the Any
   */
  public var types(get, never): Array<Any>;
  function get_types() {
    return Array.from(this.components.keys());
  }

  /**
   * Returns all component instances on entity
   */
  public function getComponents(): Array<Component> {
    return Array.from(this.components.values());
  }

  /**
   * Verifies that an entity has all the required types
   * @param requiredTypes
   */
  function hasAll(requiredTypes: Array<Any>): Bool {
    for (i in 0...requiredTypes.length) {
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
  function hasAllTags(requiredTags: Array<String>): Bool {
    for (i in 0...requiredTags.length) {
      if (!this.tags.has(requiredTags[i])) {
        return false;
      }
    }
    return true;
  }

  function get(type: String): Component {
    return this.components.get(type);
  }

  private var _parent: Null<Any> = null;
  public var parent(get, never): Null<Any>;
  function get_parent(): Null<Any> {
    return this._parent;
  }

  public var childrenAdded = new Observable<Any>();
  public var childrenRemoved = new Observable<Any>();

  private var _children: Array<Any> = [];
  /**
   * Get the direct children of this entity
   */
  public var children(get, never): Array<Any>;
  function get_children() {
    return this._children;
  }

  /**
   * Unparents this entity, if there is a parent. Otherwise it does nothing.
   */
  public function unparent() {
    if (this._parent) {
      this._parent.removeChild(this);
      this._parent = null;
    }
  }

  /**
   * Adds an entity to be a child of this entity
   * @param entity
   */
  public function addChild(entity: Any): Any {
    if (entity.parent == null) {
      if (this.getAncestors().includes(entity)) {
        throw new Error('Cycle detected, cannot add entity');
      }
      this._children.push(entity);
      entity._parent = this;
      this.childrenAdded.notifyAll(entity);
    } else {
      throw new Error('Any already has a parent, cannot add without unparenting');
    }
    return this;
  }

  /**
   * Remove an entity from children if it exists
   * @param entity
   */
  public function removeChild(entity: Any): Any {
    if (entity.parent == this) {
      removeItemFromArray(entity, this._children);
      entity._parent = null;
      this.childrenRemoved.notifyAll(entity);
    }
    return this;
  }

  /**
   * Removes all children from this entity
   */
  public function removeAllChildren(): Any {
    // Avoid modifying the array issue by walking backwards
    var i = this.children.length - 1;
    while (i >= 0) {
      this.removeChild(this.children[i]);
      i--;
    }
    return this;
  }

  /**
   * Returns a list of parent entities starting with the topmost parent. Includes the current entity.
   */
  public function getAncestors(): Array<Any> {
    final result: Array<Any> = [this];
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
  public function getDescendants(): Array<Any> {
    var result: Array<Any> = [this];
    var queue: Array<Any> = [this];
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
  public function clone(): Any {
    final newEntity = new Any();
    for (c in this.types) {
      final componentInstance = this.get(c);
      if (componentInstance) {
        newEntity.addComponent(componentInstance.clone());
      }
    }
    for (child in this.children) {
      newEntity.addChild(child.clone());
    }
    return newEntity;
  }

  /**
   * Adds a copy of all the components from another template entity as a "prefab"
   * @param templateEntity Any to use as a template
   * @param force Force component replacement if it already exists on the target entity
   */
  public function addTemplate(templateEntity: Any, force: Bool = false): Any {
    for (c in templateEntity.getComponents()) {
      this.addComponent(c.clone(), force);
    }
    for (child in templateEntity.children) {
      this.addChild(child.clone().addTemplate(child));
    }
    return this;
  }

  private function _getClassHierarchyRoot(componentType: String): Any {
    var current = componentType;
    var parent = Object.getPrototypeOf(current.prototype)?.constructor;

    while (parent && parent != Object && parent != Component) {
      current = parent;
      parent = Object.getPrototypeOf(current.prototype)?.constructor;
    }
    return current;
  }

  /**
   * Adds a component to the entity
   * @param component Component or Any to add copy of components from
   * @param force Optionally overwrite any existing components of the same type
   */
  public function addComponent<TComponent:Component>(component: TComponent, force: Bool = false): Any {
    // if component already exists, skip if not forced
    if (this.has(component.constructor)) {
      if (force) {
        // Remove existing component type if exists when forced
        this.removeComponent(component.constructor, true);
      } else {
        // early exit component exits
        return this;
      }
    }

    // TODO circular dependencies will be a problem
    if (component.dependencies && component.dependencies.length) {
      for (Ctor in component.dependencies) {
        this.addComponent(new Ctor());
      }
    }

    component.owner = this;
    final rootComponent = this._getClassHierarchyRoot(component.constructor);
    this.components.set(rootComponent, component);
    this.components.set(component.constructor, component);
    this.componentValues.push(component);
    if (component.onAdd) {
      component.onAdd(this);
    }

    this.componentAdded.notifyAll(component);
    return this;
  }

  /**
   * Removes a component from the entity, by default removals are deferred to the end of entity update to avoid consistency issues
   *
   * Components can be force removed with the `force` flag, the removal is not deferred and happens immediately
   * @param typeOrInstance
   * @param force
   */
  public function removeComponent<TComponent:Component>(
    typeOrInstance: TComponent,
    force = false
  ): Any {
    var type: ComponentCtor<TComponent>;
    if (isComponentCtor(typeOrInstance)) {
      type = typeOrInstance;
    } else {
      type = typeOrInstance.constructor;
    }

    if (force) {
      final componentToRemove = this.components.get(type);
      if (componentToRemove) {
        this.componentRemoved.notifyAll(componentToRemove);
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

    return this;
  }

  public function clearComponents() {
    final components = this.types;
    for (c in components) {
      this.removeComponent(c);
    }
  }

  /**
   * @hidden
   * @internal
   */
  public function processComponentRemoval() {
    for (type in this._componentsToRemove) {
      this.removeComponent(type, true);
    }
    this._componentsToRemove.length = 0;
  }

  /**
   * Check if a component type exists
   * @param type
   */
  public function has(type: String): Bool {
    return this.components.has(type);
  }

  private var _isInitialized = false;
  private var _isAdded = false;

  /**
   * Gets whether the actor is Initialized
   */
  public var isInitialized(get, never): Bool;
  function get_isInitialized(): Bool {
    return this._isInitialized;
  }

  public var isAdded(get, never): Bool;
  function get_isAdded(): Bool {
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
  public function _preupdate(engine: Engine, elapsed: Int) {
    this.events.emit('preupdate', new PreUpdateEvent(engine, elapsed, this));
    this.onPreUpdate(engine, elapsed);
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPostUpdate} lifecycle event
   * @internal
   */
  public function _postupdate(engine: Engine, elapsed: Int) {
    this.events.emit('postupdate', new PostUpdateEvent(engine, elapsed, this));
    this.onPostUpdate(engine, elapsed);
  }

  /**
   * `onInitialize` is called before the first update of the entity. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('initialize', (evt) => {...})`
   */
  public function onInitialize(engine: Engine) {
    // Override me
  }

  /**
   * `onAdd` is called when Actor is added to scene. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('add', (evt) => {...})`
   */
  public function onAdd(engine: Engine) {
    // Override me
  }

  /**
   * `onRemove` is called when Actor is added to scene. This method is meant to be
   * overridden.
   *
   * Synonymous with the event handler `.on('remove', (evt) => {...})`
   */
  public function onRemove(engine: Engine) {
    // Override me
  }

  /**
   * Safe to override onPreUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreUpdate` is called directly before an entity is updated.
   */
  public function onPreUpdate(engine: Engine, elapsed: Int) {
    // Override me
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('postupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after an entity is updated.
   */
  public function onPostUpdate(engine: Engine, elapsed: Int) {
    // Override me
  }

  /**
   *
   * Any update lifecycle, called internally
   * @internal
   * @param engine
   * @param elapsed
   */
  public function update(engine: Engine, elapsed: Int) {
    this._initialize(engine);
    this._add(engine);
    this._preupdate(engine, elapsed);
    for (child in this.children) {
      child.update(engine, elapsed);
    }
    this._postupdate(engine, elapsed);
    this._remove(engine);
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    if (handler) {
      this.events.off(eventName, handler);
    } else {
      this.events.off(eventName);
    }
  }
}
