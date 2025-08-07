package nebula.entitycomponentsystem;

import nebula.entitycomponentsystem.System;
import nebula.entitycomponentsystem.World;

import nebula.util.Util;

import nebula.Scene;

function isSystemConstructor(x: Any) {
  return !!x?.prototype && !!x?.prototype?.constructor?.name;
}

/**
 * The SystemManager is responsible for keeping track of all systems in a scene.
 * Systems are scene specific
 */
class SystemManager {
  /**
   * List of systems, to add a new system call {@apilink SystemManager.addSystem}
   */
  public var systems: Array<System> = [];
  public var initialized = false;
  public function new(_world: World) {}

  /**
   * Get a system registered in the manager by type
   * @param systemType
   */
  public function get<T:System>(SystemType: SystemCtor<T>): Null<T> {
    return this.systems.find((s) -> Std.isOfType(s, SystemType));
  }

  /**
   * Adds a system to the manager, it will now be updated every frame
   * @param systemOrCtor
   */
  public function addSystem(system: System) {
    this.systems.push(system);
    this.systems.sort((a, b) -> a.priority - b.priority);
    // If systems are added and the manager has already been init'd
    // then immediately init the system
    if (this.initialized && system.initialize) {
      system.initialize(this._world, this._world.scene);
    }
  }

  /**
   * Removes a system from the manager, it will no longer be updated
   * @param system
   */
  public function removeSystem(system: System) {
    removeItemFromArray(system, this.systems);
  }

  /**
   * Initialize all systems in the manager
   *
   * Systems added after initialize() will be initialized on add
   */
  public function initialize() {
    if (!this.initialized) {
      this.initialized = true;
      for (s in this.systems) {
        if (s.initialize) {
          s.initialize(this._world, this._world.scene);
        }
      }
    }
  }

  /**
   * Updates all systems
   * @param type whether this is an update or draw system
   * @param scene context reference
   * @param elapsed time in milliseconds
   */
  public function updateSystems(type: SystemType, scene: Scene, elapsed: Float) {
    final systems = this.systems.filter((s) -> s.systemType == type);
    for (s in systems) {
      if (s.preupdate) {
        s.preupdate(scene, elapsed);
      }
    }

    for (s in systems) {
      s.update(elapsed);
    }

    for (s in systems) {
      if (s.postupdate) {
        s.postupdate(scene, elapsed);
      }
    }
  }

  public function clear() {
    var i = this.systems.length - 1;
    while(i >= 0) {
      this.removeSystem(this.systems[i]);
      i--;
    }
  }
}
