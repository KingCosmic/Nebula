package nebula.scene;

import nebula.gameobjects.GameObject;
import nebula.structs.ProcessQueue;

class UpdateList extends ProcessQueue<GameObject> {
	// The Scene that the Update List belongs to.
	public var scene:Scene;

	public function new(_scene:Scene) {
		super();

		scene = _scene;

		// No duplicates in this list
		checkQueue = true;

		scene.events.once('BOOT', boot);
		scene.events.on('START', start);
	}

	/**
	 * This method is called automatically, only once, when the Scene is first created.
	 * Do not invoke it directly.
	 */
	public function boot() {
		scene.events.once('DESTROY', destroy);
	}

	/**
	 * This method is called automatically by the Scene when it is starting up.
	 * It is responsible for creating local systems, properties and listening for Scene events.
	 * Do not invoke it directly.
	 */
	public function start() {
		scene.events.on('PRE_UPDATE', update);
		scene.events.on('UPDATE', sceneUpdate);
		scene.events.once('SHUTDOWN', shutdown);
	}

	// The update step.
	// Pre-updates every active GameObject in the list.
	public function sceneUpdate(time:Float, delta:Float) {
		for (gameObject in _active) {
			if (!gameObject.active)
				continue;

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

		scene.events.removeListener('PRE_UPDATE', update);
		scene.events.removeListener('UPDATE', sceneUpdate);
		scene.events.removeListener('SHUTDOWN', shutdown);
	}

	/**
	 * The Scene that owns this plugin is being destroyed.
	 *
	 * We need to shutdown and then kill off all external references.
	 */
	override public function destroy() {
		shutdown();

		scene.events.removeListener('START', start);

		scene = null;
	}
}