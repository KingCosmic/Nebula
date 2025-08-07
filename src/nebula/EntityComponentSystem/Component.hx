package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.Entity;

/**
 *
 */
function isComponentCtor(value: Any) {
  return !!value && !!value.prototype && !!value.prototype.constructor;
}

/**
 * Type guard to check if a component implements clone
 * @param x
 */
function hasClone(x: Any) {
  return !!x?.clone;
}

/**
 * Components are containers for state in Excalibur, the are meant to convey capabilities that an Entity possesses
 *
 * Implementations of Component must have a zero-arg constructor to support dependencies
 *
 * ```typescript
 * class MyComponent extends ex.Component {
 *   // zero arg support required if you want to use component dependencies
 *   constructor(public optionalPos?: ex.Vector) {}
 * }
 * ```
 */
abstract class Component {
  // TODO maybe generate a unique id?

  /**
   * Optionally list any component types this component depends on
   * If the owner entity does not have these components, new components will be added to the entity
   *
   * Only components with zero-arg constructors are supported as automatic component dependencies
   */
  var dependencies: Null<Array<Any>>;

  /**
   * Current owning {@apilink Entity}, if any, of this component. Null if not added to any {@apilink Entity}
   */
  var owner: Null<Entity> = null;

  /**
   * Clones any properties on this component, if that property value has a `clone()` method it will be called
   */
  function clone(): Component {
    final Cons = this.new;
    final newComponent = new Cons();
    for (prop in this) {
      if (this.hasOwnProperty(prop)) {
        final val = this[prop];
        if (hasClone(val) && prop != 'owner' && prop != 'clone') {
          newComponent[prop] = val.clone();
        } else {
          newComponent[prop] = val;
        }
      }
    }
    return newComponent;
  }

  /**
   * Optional callback called when a component is added to an entity
   */
  var onAdd: Null<(owner: Entity) -> Void>;

  /**
   * Optional callback called when a component is removed from an entity
   */
  var onRemove: Null<(previousOwner: Entity) -> Void>;
}
