package core.gameobjects;

import core.scene.Systems;
import core.structs.ProcessQueue;
import core.scene.Scene;

class UpdateList extends ProcessQueue<GameObject> {
  // The Scene that the Update List belongs to.
  public var scene:Scene;

  // The Scene's Systems.
  public var systems:Systems;

  public function new(_scene:Scene, _systems:Systems) {
    super();

    scene = _scene;
		systems = _systems;

    // No duplicates in this list
    checkQueue = true;

    systems.events.once('BOOT', boot);
    systems.events.on('START', start);
  }

  /**
   * This method is called automatically, only once, when the Scene is first created.
   * Do not invoke it directly.
   */
  public function boot() {
    systems.events.once('DESTROY', destroy);
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    systems.events.on('PRE_UPDATE', update);
    systems.events.on('UPDATE', sceneUpdate);
    systems.events.once('SHUTDOWN', shutdown);
  }

  // The update step.
  // Pre-updates every active GameObject in the list.
  public function sceneUpdate(time:Float, delta:Float) {
    for (gameObject in _active) {
      if (!gameObject.active) continue;

      gameObject.preUpdate(time, delta);
    }
  }

  /**
   * The Scene that owns this plugin is shutting down.
   *
   * We need to kill and reset all internal properties as well as stop listening to Scene events.
   */
  public function shutdown() {
    var i = _active.length - 1;

    while (i >= 0) {
      _active[i].destroy(true);

      i--;
    }

		i = _pending.length - 1;

		while (i >= 0) {
			_pending[i].destroy(true);

			i--;
    }
    
		i = _destroy.length - 1;

		while (i >= 0) {
			_destroy[i].destroy(true);

			i--;
    }
    
    _toProcess = 0;
    _pending = [];
    _active = [];
    _destroy = [];

    removeAllListeners();

    systems.events.removeListener('PRE_UPDATE', update);
    systems.events.removeListener('UPDATE', sceneUpdate);
    systems.events.removeListener('SHUTDOWN', shutdown);
  }

  /**
   * The Scene that owns this plugin is being destroyed.
   *
   * We need to shutdown and then kill off all external references.
   */
  override public function destroy() {
    shutdown();

    systems.events.removeListener('START', start);

    scene = null;
    systems = null;
  }
}