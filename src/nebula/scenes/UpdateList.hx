package nebula.scenes;

import nebula.gameobjects.GameObject;

class UpdateList extends EventEmitter {
	/**
	 * The Scene that the Update List belongs to.
	 */
	public var scene:Scene;

	/**
	 * The `pending` list is a selection of items which are due to be made 'active' in the next update.
	 */
	public var _pending:Array<GameObject> = [];

	/**
	 * The `active` list is a selection of items which are considered active and should be updated.
	 */
	public var _active:Array<GameObject> = [];

	/**
	 * The `destroy` list is a selection of items that were active and are awaiting being destroyed in the next update.
	 */
	public var _destroy:Array<GameObject> = [];

	/**
	 * The total number of items awaiting processing.
	 */
	public var _toProcess:Int = 0;

	/**
	 * If `true` only unique objects will be allowed in the queue.
	 */
	public var checkQueue:Bool = false;

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

	/**
	 * runs every gameobjects preUpdate method.
	 */
	public function sceneUpdate(time:Float, delta:Float) {
		for (gameObject in _active) {
			if (!gameObject.active)
				continue;

			gameObject.preUpdate(time, delta);
		}
	}

	/**
	 * Adds a new item to the Process Queue.
	 *
	 * The item is added to the pending list and made active in the next update.
	 */
	public function add(item:GameObject) {
		_pending.push(item);

		_toProcess++;

		return item;
	}

	/**
	 * Removes an item from the Process Queue.
	 *
	 * The item is added to the pending destroy and fully removed in the next update.
	 */
	public function remove(item:GameObject) {
		_destroy.push(item);

		_toProcess++;

		return item;
	}

	/**
	 * Removes all active items from this Process Queue.
	 *
	 * All the items are marked as 'pending destroy' and fully removed in the next update.
	 */
	public function removeAll() {
		var index = _active.length - 1;

		while (index >= 0) {
			_destroy.push(_active[index]);

			_toProcess++;
			index--;
		}

		return this;
	}

	/**
	 * Update this queue. First it will process any items awaiting destruction, and remove them.
	 *
	 * Then it will check to see if there are any items pending insertion, and move them to an
	 * active state. Finally, it will return a list of active items for further processing.
	 */
	public function update() {
		// Quick bail
		if (_toProcess == 0)
			return _active;

		for (item in _destroy) {
			// Remove from the active array.
			var idx = _active.indexOf(item);

			if (idx == -1)
				continue;

			_active.splice(idx, 1);

			emit('PROCESS_QUEUE_REMOVE', item);
		}

		_destroy = [];

		// Process the pending addition list
		// This stops callbacks and out of sync events from populating the active array mid-way during an update
		for (item in _pending) {
			if (checkQueue == false || (checkQueue && _active.indexOf(item) == -1)) {
				_active.push(item);

				emit('PROCESS_QUEUE_ADD', item);
			}
		}

		_pending = [];
		_toProcess = 0;

		// The owner of this queue can now safely do whatever it needs to with the active list
		return _active;
	}

	/**
	 * Returns the current list of active items.
	 *
	 * This method returns a reference to the active list array, not a copy of it.
	 * Therefore, be careful to not modify this array outside of the ProcessQueue.
	 */
	public function getActive() {
		return _active;
	}

	// The number of entries in the active list
	public function getLength() {
		return _active.length;
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
	public function destroy() {
		shutdown();

		scene.events.removeListener('START', start);

		scene = null;
	}
}