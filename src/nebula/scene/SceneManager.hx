package nebula.scene;

import nebula.Game;
import nebula.scene.Scene;

typedef Pending = {
	key:String,
	scene:Class<Scene>,
	autoStart:Bool,
	data:{}
};

typedef Queue = {
	op:String,
	keyA:String,
	?keyB:String
};


class SceneManager {
	// The Game that this SceneManager belongs to.
	public var game:Game;

	// An object that maps the keys to the scene so we can quickly get a scene from a key without iteration.
	public var keys:Map<String, Scene> = new Map();

	// The array in which all of the scenes are kept.
	public var scenes:Array<Scene> = [];

	// Scenes pending to be added are stored in here until the manager has time to add it.
	private var pending:Array<Pending> = [];

	/**
   * An operations queue, because we don't manipulate the scenes array during processing.
   * 
   * TODO: make use of this
  **/
	private var queue:Array<Queue> = [];

	// Is the Scene Manager actively processing the Scenes list?
	public var isProcessing = false;

	// Has the Scene Manager properly started?
	public var isBooted = false;

	// Do any of the Cameras in any of the Scenes require a custom viewport?
	// If not we can skip scissor tests.
	public var customViewports = 0;

	public function new(_game:Game, ?sceneConfigs:Array<Class<Scene>>) {
		game = _game;

		if (sceneConfigs == null)
			sceneConfigs = [];

		for (i in 0...sceneConfigs.length) {
			// The i === 0 part just autostarts the first Scene given (unless it says otherwise in its config)
			pending.push({
				key: 'default',
				scene: sceneConfigs[i],
				autoStart: (i == 0),
				data: {}
			});
		}

    // we're ready to boot the scenes
		game.events.once('READY', bootQueue);
	}

	// Internal first-time Scene boot handler.
	public function bootQueue() {
		if (isBooted)
			return;

		for (i in 0...pending.length) {
			var newScene = createSceneFromInstance(pending[i].scene);

			// Replace key in case the scene changed it
			var key:String = newScene.key;

			keys.set(key, newScene);

      // push 
			scenes.push(newScene);
		}

		// Clear the pending lists
    pending = [];

    // let the world know we're booted
		isBooted = true;

    // start our default scene
    start(scenes[0].key);
	}

	// Process the Scene operations queue.
	public function processQueue() {
		var queueLength = queue.length;

		if (queueLength == 0)
			return;

		for (entry in queue) {
			var op = entry.op;

			// TODO: Swap for a switch statement
			if (op == 'bringToTop') {
				bringToTop(entry.keyA);
			} else if (op == 'sendToBack') {
				sendToBack(entry.keyA);
			}
		}

		queue = [];
	}

	/**
   * Boot the given Scene.
   */
	public function bootScene(scene:Scene) {
		scene.runUpdate = false;

		scene.init({});

		scene.status = 1;

		var loader = null;

		if (scene.load != null) {
			loader = scene.load;

			loader.reset();
		}

		if (loader != null) {
			scene.preload();

			// Is the loader empty?
			if (loader.list.size == 0) {
				create(scene);
			} else {
				scene.status = 3;

				// Start the loader as we have something in the queue
				loader.once('COMPLETE', loadComplete);

				loader.start();
			}
		} else {
			// No preload? Then there was nothing to load either
			create(scene);
		}
	}

	// Handles the load completion for a Scene's Loader.
	// Starts the Scene that the Loader belongs to.
	public function loadComplete(loader) {
		create(loader.scene);
	}

	// Handle payload completion for a Scene.
	public function payloadComplete(loader) {
		bootScene(loader.scene);
	}

	// Updates the Scenes.
	dynamic public function update(time:Float, delta:Float) {
		isProcessing = true;

		// Loop through the active scenes in reverse order
		for (i in new ReverseIterator((scenes.length - 1), 0)) {
			var scene = scenes[i];

			if (scene.status > 2 && scene.status <= 5) {
				scene.step(time, delta);
			}
		}
	}

	// Renders the Scenes.
	public function render(renderer) {
		// Loop through the scenes in forward order
		for (scene in scenes) {
			if (scene.visible && scene.status >= 3 && scene.status < 7) {
				scene.render(renderer);
			}
		} 

		isProcessing = false;
	}

	// Calls the given Scene's Phaser.Scene#create method and updates its status.
	public function create(scene:Scene) {
		scene.status = 4;

		scene.create();

		if (scene.status == 9)
			return;

		// If the Scene has an update function we'll set it now, otherwise it'll remain as NOOP
		scene.runUpdate = true;

		scene.status = 5;

		scene.events.emit('CREATE', scene);
	}

	// Creates and initializes a Scene from a function.
	public function createSceneFromInstance(newScene:Class<Scene>):Scene {
		var instance = Type.createInstance(newScene, []);

    // set the asset manager to the games asset manager.
		instance.assets = game.assets;

    instance.setManager(game, this);

		instance.init({});

		return instance;
	}

	// Retrieves the key of a Scene from a Scene config.
	public function getKey(?key:String = 'default', sceneConfig:Scene) {
		key = sceneConfig.key;

		// By this point it's either 'default' or extracted from the Scene
		if (keys.exists(key)) {
			// throw new Error('Cannot add a Scene with duplicate key:' + key);
		}

		return key;
	}

	/**
	 * Returns an array of all the current Scenes being managed by this Scene Manager.
	 *
	 * You can filter the output by the active state of the Scene and choose to have
	 * the array returned in normal or reversed order.
	 */
	public function getScenes(isActive:Bool = true, inReverse:Bool = false):Array<Scene> {
		var out = [];

		for (scene in scenes) {
			if (!isActive || (isActive && scene.isActive())) {
				out.push(scene);
			}
		}

		if (inReverse)
			out.reverse();

		return out;
	}

	// Retrieves a Scene.
	public function getScene(key:String) {
		return keys.get(key);
	}

	// Determines if a Scene is running.
	public function isActive(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.isActive();
		}

		return null;
	}

	// Determines if a Scene is paused.
	public function isPaused(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.isPaused();
		}

		return null;
	}

	// Determines if a Scene is visible.
	public function isVisible(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.isVisible();
		}

		return null;
	}

	// Determines if a Scene is sleeping.
	public function isSleeping(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.isSleeping();
		}

		return null;
	}

	// Pauses the given scene
	public function pause(key:String, data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.pause(data);
		}

		return this;
	}

	// Resumes the given scene
	public function resume(key:String, data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.resume(data);
		}

		return this;
	}

	// Puts the given Scene to sleep.
	public function sleep(key:String, ?data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.sleep(data);
		}

		return this;
	}

	// Awakens the given Scene.
	public function wake(key:String, ?data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.wake(data);
		}

		return this;
	}

	/**
	 * Runs the given Scene.
	 *
	 * If the given Scene is paused, it will resume it. If sleeping, it will wake it.
	 * If not running at all, it will be started.
	 *
	 * Use this if you wish to open a modal Scene by calling `pause` on the current
	 * Scene, then `run` on the modal Scene.
	 */
	public function run(key:String, data:Any) {
		var scene = getScene(key);

		if (scene == null) {
			for (pend in pending) {
				if (pend.key == key) {
					queueOp('start', key, data);
					break;
				}
			}
			return this;
		}

		if (scene.isSleeping()) {
			// Sleeping?
			scene.wake(data);
		} else if (scene.isPaused()) {
			// Paused?
			scene.resume(data);
		} else {
			// Not actually running?
			start(key, data);
		}

		return this;
	}

	// Starts the given Scene.
	public function start(key:String, ?data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			// If the Scene is already running (perhaps they called start from a launched sub-Scene?)
			// then we close it down before starting it again.

			if (scene.isActive() || scene.isPaused()) {
				scene.shutdown();

				scene.start(data);
			} else {
				scene.start(data);

				// TODO: code loader

				var loader = null;

				if (scene.load != null) {
					loader = scene.load;
				}

				// Files payload?
				if (loader != null) {
					loader.reset();
				}
			}

			bootScene(scene);
		}

		return this;
	}

	// Stops the given Scene.
	public function stop(key:String, data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.shutdown(data);
		}

		return this;
	}

	// Sleeps one Scene and starts the other.
	public function switchScene(from:String, to:String) {
		var sceneA = getScene(from);
		var sceneB = getScene(to);

		if (sceneA != null && sceneB != null && from != to) {
			sleep(from);

			if (isSleeping(to)) {
				wake(to);
			} else {
				start(to);
			}
		}

		return this;
	}

	// Retrieve a Scene by numeric index.
	public function getAt(index:Int) {
		return scenes[index];
	}

	// Retrieves the numeric index of a Scene
	public function getIndex(key:String) {
		var scene = getScene(key);

		return scenes.indexOf(scene);
	}

	// Brings a Scene to the top of the Scenes list.
	// This means it will render above all other Scenes.
	public function bringToTop(key:String) {
		if (isProcessing) {
			queue.push({op: 'bringToTop', keyA: key, keyB: null});
		} else {
			var index = getIndex(key);

			if (index != -1 && index < scenes.length) {
				var scene = getScene(key);

				scenes.splice(index, 1);
				scenes.push(scene);
			}
		}

		return this;
	}

	// Sends a Scene to the back of the Scenes list.
	// This means it will render below all other Scenes.
	public function sendToBack(key:String) {
		if (isProcessing) {
			queue.push({op: 'sendToBack', keyA: key, keyB: null});
		} else {
			var index = getIndex(key);

			if (index != -1 && index > 0) {
				var scene = getScene(key);

				scenes.splice(index, 1);
				scenes.unshift(scene);
			}
		}

		return this;
	}

	// TODO: moveDown()
	// TODO: moveUp()
	// TODO: moveAbove()
	// TODO: moveBelow()
	// TODO: swapPosition()
	// TODO: dump()
	// Queue a Scene operation for the next update.
	public function queueOp(op:String, keyA:String, keyB:String) {
		queue.push({op: op, keyA: keyA, keyB: keyB});

		return this;
	}

	// Destroy the SceneManager and all of it's Scene's systems.
	public function destroy() {
		for (scene in scenes) {
			scene.destroy();
		}

		update = (time:Float, delta:Float) -> {};

		scenes = [];

		pending = [];
    queue = [];

		game = null;
	}
}