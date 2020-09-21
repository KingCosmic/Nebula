package core.scene;

import core.Game;
import core.scene.Scene;

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

typedef DataObject = {
  ?autoStart:Bool,
  ?data:Any
} 

class SceneManager {
  // The Game that this SceneManager belongs to.
  public var game:Game;

  // An object that maps the keys to the scene so we can quickly get a scene from a key without iteration.
  public var keys:Map<String, Scene> = new Map();

  // The array in which all of the scenes are kept.
  public var scenes:Array<Scene> = [];

  // Scenes pending to be added are stored in here until the manager has time to add it.
  public var _pending:Array<Pending> = [];

  // An operations queue, because we don't manipulate the scenes array during processing.
  public var _queue:Array<Queue> = [];

	// An array of scenes waiting to be started once the game has booted.
  public var _start:Array<String> = [];

  // Boot time data to merge.
  public var _data:Map<String, DataObject> = new Map();

  // Is the Scene Manager actively processing the Scenes list?
  public var isProcessing = false;

  // Has the Scene Manager properly started?
  public var isBooted = false;

	// Do any of the Cameras in any of the Scenes require a custom viewport?
  // If not we can skip scissor tests.
  public var customViewports = 0;

  // these vars are just here to fix issues in Systems
  public var _target:Scene;
  public var _duration:Float = 0;

  public function new(_game: Game, ?sceneConfigs: Array<Class<Scene>>) {
    game = _game;

    if (sceneConfigs == null) sceneConfigs = [];

    for (i in 0...sceneConfigs.length) {
      // The i === 0 part just autostarts the first Scene given (unless it says otherwise in its config)
      _pending.push({
        key: 'default',
				scene: sceneConfigs[i],
        autoStart: (i == 0),
        data: {}
      });
    }

    game.events.once('READY', bootQueue);
  }

  // Internal first-time Scene boot handler.
  public function bootQueue() {
    if (isBooted) return;

    for (entry in _pending) {
      var key = entry.key;
      var sceneConfig = entry.scene;

      var newScene = createSceneFromInstance(key, sceneConfig);

      // Replace key in case the scene changed it
      key = newScene.sys.settings.key;

      keys.set(key, newScene);
      scenes.push(newScene);

      var dataObject = _data.get(key);

      if (dataObject != null) {
        newScene.sys.settings.data = dataObject.data;

				if (dataObject.autoStart) {
          entry.autoStart = true;
        }
      }

      if (entry.autoStart || newScene.sys.settings.active) {
        _start.push(key);
      }
    }

    // Clear the pending lists
    _pending = [];

    _data.clear();

    isBooted = true;

    // _start might have been populated by the above
    for (entry in _start) {
      start(entry);
    }

    _start = [];
  }

  // Process the Scene operations queue.
  public function processQueue() {
    var pendingLength = _pending.length;
    var queueLength = _queue.length;

    if (pendingLength == 0 && queueLength == 0) return;

    if (pendingLength > 0) {
      for (entry in _pending) {
        add(entry.key, entry.scene, entry.autoStart, entry.data);
      }

      // _start might have been populated by this.add
      for (entry in _start) {
        start(entry);
      }

      _start = [];
      _pending = [];

      return;
    }

    for (entry in _queue) {
      var op = entry.op;

      // TODO: Swap for a switch statement
      if (op == 'remove') {
        remove(entry.keyA);
			} else if (op == 'bringToTop') {
        bringToTop(entry.keyA);
			} else if (op == 'sendToBack') {
        sendToBack(entry.keyA);
      }
    }

    _queue = [];
  }

  // Adds a new Scene into the SceneManager.
  // You must give each Scene a unique key by which you'll identify it.
  public function add(key: String, sceneConfig:Class<Scene>, autoStart:Bool = false, ?data:Any):Null<Scene> {

    // If processing or not booted then put scene into a holding pattern
    if (isProcessing || !isBooted) {
      _pending.push({
        key: key,
        scene: sceneConfig,
        autoStart: autoStart,
        data: data
      });

      if (!isBooted) {
        _data.set(key, { data: data });
      }

      return null;
    }

    var newScene = createSceneFromInstance(key, sceneConfig);

		// By this point it's either 'default' or extracted from the Scene
		if (keys.exists(newScene.sys.settings.key)) {
			return null; // throw new Error('Cannot add a Scene with duplicate key:' + key);
		}

    // Any data to inject?
    newScene.sys.settings.data = data;

    // Replace key in case the scene changed it
    key = newScene.sys.settings.key;

    keys.set(key, newScene);
    scenes.push(newScene);

    if (autoStart || newScene.sys.settings.active) {
      if (_pending.length > 0) {
        _start.push(key);
      } else {
        start(key);
      }
    }

    return newScene;
  }

  /**
   * Removes a Scene from the SceneManager.
   *
   * The Scene is removed from the local scenes array, it's key is cleared from the keys
   * cache and Scene.Systems.destroy is then called on it.
   *
   * If the SceneManager is processing the Scenes when this method is called it will
   * queue the operation for the next update sequence.
   */
  public function remove(key: String) {

    if (isProcessing) {
      _queue.push({ op: 'remove', keyA: key, keyB: null });
    } else {
      var sceneToRemove = getScene(key);

      if (sceneToRemove == null || sceneToRemove.sys.isTransitioning()) {
        return this;
      }

      var index = scenes.indexOf(sceneToRemove);
      var sceneKey = sceneToRemove.sys.settings.key;

      if (index > -1) {
        keys.remove(sceneKey);
        scenes.splice(index, 1);

        if (_start.indexOf(sceneKey) > -1) {
          index = _start.indexOf(sceneKey);
          _start.splice(index, 1);
        }

        sceneToRemove.sys.destroy();
      }
    }

    return this;
  }

  // Boot the given Scene.
  public function bootScene(scene:Scene) {
    var sys = scene.sys;
    var settings = sys.settings;

    sys.runSceneUpdate = false;

    scene.init(settings.data);

    settings.status = 1;

    if (settings.isTransition) {
      sys.events.emit('TRANSITION_INIT', settings.transitionFrom, settings.transitionDuration);
    }

    var loader = null;

    if (sys.load != null) {
      loader = sys.load;

      loader.reset();
    }

    if (loader != null) {
      scene.preload();

      // Is the loader empty?
      if (loader.list.size == 0) {
        create(scene);
      } else {
        settings.status = 3;

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
    processQueue();

    isProcessing = true;

    // Loop through the active scenes in reverse order
    for (i in new ReverseIterator((scenes.length - 1), 0)) {
      var sys = scenes[i].sys;

			if (sys.settings.status > 2 && sys.settings.status <= 5) {
				sys.step(time, delta);
			}
    }
  }

  // Renders the Scenes.
  public function render(renderer) {
    // Loop through the scenes in forward order
    for (scene in scenes) {
      var sys = scene.sys;

			if (sys.settings.visible && sys.settings.status >= 3 && sys.settings.status < 7) {
        sys.render(renderer);
      }
    }

    isProcessing = false;
  }

  // Calls the given Scene's Phaser.Scene#create method and updates its status.
  public function create(scene:Scene) {
    var sys = scene.sys;
    var settings = sys.settings;

    settings.status = 4;

    scene.create();

    if (settings.status == 9) return;

    if (settings.isTransition) {
			sys.events.emit('TRANSITION_START', settings.transitionFrom, settings.transitionDuration);
    }

    // If the Scene has an update function we'll set it now, otherwise it'll remain as NOOP
    sys.runSceneUpdate = true;

    settings.status = 5;

    sys.events.emit('CREATE', scene);
  }

  // Creates and initializes a Scene from a function.
  public function createSceneFromInstance(key:String, newScene:Class<Scene>):Scene {
    var instance = Type.createInstance(newScene, []);

    instance.setManager(this);

    var configKey = instance.sys.settings.key;

    if (configKey == '') {
      instance.sys.settings.key = key;
    }

    instance.sys.init(game);

    return instance;
  }

  // Retrieves the key of a Scene from a Scene config.
  public function getKey(?key:String = 'default', sceneConfig:Scene) {
    key = sceneConfig.sys.settings.key;

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
      if (!isActive || (isActive && scene.sys.isActive())) {
        out.push(scene);
      }
    }

    if (inReverse) out.reverse();

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
      return scene.sys.isActive();
    }

    return null;
  }

	// Determines if a Scene is paused.
	public function isPaused(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.sys.isPaused();
		}

		return null;
  }
  
	// Determines if a Scene is visible.
	public function isVisible(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.sys.isVisible();
		}

		return null;
  }
  
	// Determines if a Scene is sleeping.
	public function isSleeping(key:String):Null<Bool> {
		var scene = getScene(key);

		if (scene != null) {
			return scene.sys.isSleeping();
		}

		return null;
  }
  
  // Pauses the given scene
	public function pause(key:String, data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.sys.pause(data);
		}

		return this;
  }
  
	// Resumes the given scene
	public function resume(key:String, data:Any) {
		var scene = getScene(key);

		if (scene != null) {
			scene.sys.resume(data);
		}

		return this;
  }
  
	// Puts the given Scene to sleep.
	public function sleep(key:String, ?data:Any) {
		var scene = getScene(key);

		if (scene != null && !scene.sys.isTransitioning()) {
			scene.sys.sleep(data);
		}

		return this;
  }
  
  // Awakens the given Scene.
  public function wake(key:String, ?data:Any) {
    var scene = getScene(key);

    if (scene != null) {
      scene.sys.wake(data);
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
      for (pend in _pending) {
        if (pend.key == key) {
          queueOp('start', key, data);
          break;
        }
      }
      return this;
    }

    if (scene.sys.isSleeping()) {
      // Sleeping?
      scene.sys.wake(data);
    } else if (scene.sys.isPaused()) {
      // Paused?
      scene.sys.resume(data);
    } else {
      // Not actually running?
      start(key, data);
    }

    return this;
  }

  // Starts the given Scene.
  public function start(key:String, ?data:Any) {
    // If the Scene Manager is not running, then put the Scene into a holding pattern.
    if (!isBooted) {
      _data[key] = {
        autoStart: true,
        data: data
      }

      return this;
    }

    var scene = getScene(key);

    if (scene != null) {
			// If the Scene is already running (perhaps they called start from a launched sub-Scene?)
      // then we close it down before starting it again.
      
      if (scene.sys.isActive() || scene.sys.isPaused()) {
        scene.sys.shutdown();

        scene.sys.start(data);
      } else {
        scene.sys.start(data);

        // TODO: code loader

        var loader = null;

        if (scene.sys.load != null) {
          loader = scene.sys.load;
        }

        // Files payload?
        if (loader != null) {
          loader.reset();

          /*if (loader.addPack({ payload: scene.sys.settings.pack })) {
            scene.sys.settings.status = 3;

            loader.once('COMPLETE', payloadComplete);

            loader.start();

            return this;
          }*/
        }
      }

      bootScene(scene);
    }

    return this;
  }

  // Stops the given Scene.
  public function stop(key:String, data:Any) {
    var scene = getScene(key);

    if (scene != null && !scene.sys.isTransitioning()) {
      scene.sys.shutdown(data);
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
  public function getIndex(key: String) {
    var scene = getScene(key);

    return scenes.indexOf(scene);
  }

  // Brings a Scene to the top of the Scenes list.
  // This means it will render above all other Scenes.
  public function bringToTop(key:String) {
    if (isProcessing) {
      _queue.push({ op: 'bringToTop', keyA: key, keyB: null });
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
      _queue.push({ op: 'sendToBack', keyA: key, keyB: null });
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
    _queue.push({ op: op, keyA: keyA, keyB: keyB });

    return this;
  }

  // Destroy the SceneManager and all of it's Scene's systems.
  public function destroy() {
    for (scene in scenes) {
      var sys = scene.sys;

      sys.destroy();
    }

    update = (time:Float, delta:Float) -> {};

    scenes = [];

    _pending = [];
    _start = [];
    _queue = [];

    game = null;
  }
}