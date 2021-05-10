package nebula.scenes;

import nebula.Game;

typedef Pending = {
  key:String,
  scene:Class<Scene>,
  autoStart:Bool,
  data:Any
}

typedef Operation = {
  op:String,
  keyA:String,
  ?keyB:String
}

/**
 * This is our Scene Manager it handles updating and rendering all of our scenes.
 */
class SceneManager {
  /**
   * The Nebula.Game instance this SceneManager belongs to.
   */
  public var game:Game;

  /**
   * A map that helps us quickly access scenes based on their key.
   */
  public var keys:Map<String, Scene> = new Map();

  /**
   * The array in which all of the scenes are kept.
   */
  public var scenes:Array<Scene> = [];

  /**
   * scenes are stored here so they can be started at a laterr date.
   */
  public var pending:Array<Pending> = [];

  /**
   * An operations queue, because we don't manipulate the scenes array during processing.
   */
  public var operations:Array<Operation> = [];

  /**
   * Is the Scene Manager actively processing the scenes list?
   */
  public var isProcessing:Bool = false;

  /**
   * Has the Scene Manager properly started?
   */
  public var isBooted:Bool = false;

  public function new(_game:Game, sceneConfigs:Array<Class<Scene>>) {
    game = _game;
    
    // setup our pending list.
    for (i in 0...sceneConfigs.length) {
			// The i === 0 part just autostarts the first Scene given (unless it says otherwise in its config)
      pending.push({
        key: 'default',
        scene: sceneConfigs[i],
        autoStart: (i == 0),
        data: {}
      });
    }

    game.events.once('READY', boot);
  }

  /**
   * Internal first-time Scene boot handler
   */
  public function boot() {
    // if we've already booted just return
    if (isBooted) return;

    // loop through our stored scenes.
    for (i in 0...pending.length) {
      // iniate our scene class.
      var newScene = createScene(pending[i].scene);

      // store our scene based on it's scene.
      keys.set(newScene.key, newScene);

      // add it to our loaded scenes list.
      scenes.push(newScene);
    }

    // clear the pending list.
    pending = [];

    // update our booted flag.
    isBooted = true;

    // start our default scene.
    start(scenes[0].key);
  }

  /**
   * This method initates our scene class and returns it's instance.
   */
  public function createScene(newScene:Class<Scene>):Scene {
    // create the instance
    var instance:Scene = Type.createInstance(newScene, []);

    // internally boot this scene.
    instance.boot(game, this);

    // run our scenes init method
    instance.init({});

    // return the instance
    return instance;
  }

  /**
   * starts the given scene, restarting it if it's already running.
   */
  public function start(key:String, ?data:Any) {
    // grab our scene
    var scene = getScene(key);

    // if there is no scene for that key just return.
    if (scene == null) return this;

		// If the Scene is already running (perhaps they called start from a launched sub-Scene?)
		// then we close it down before starting it again.
    if (scene.isActive() || scene.isPaused()) {
      // shut the scene down.
      scene.shutdown();

      // restart it.
      scene.start(data);
    } else {
      // otherwise just start it.
      scene.start(data);

      // reset our loader if it isnt null.
      if (scene.load != null) {
        scene.load.reset();
      }
    }

    // boot the scene after it's started.
    bootScene(scene);

    // return the manager for chaining.
    return this;
  }

	/**
	 * Retrieves a Scene via it's key.
	 */
	public function getScene(key:String) {
		return keys.get(key);
	}

	/**
	 * Boot the given Scene.
	 */
	public function bootScene(scene:Scene) {
    // tell it not to update the scene yet.
		scene.runUpdate = false;

    // run its init method
		scene.init({});

    // set it's status
		scene.status = SceneConsts.INIT;

		var loader = null;

    // if our loader isn't null
		if (scene.load != null) {
      // store it locally
			loader = scene.load;

      // reset it.
			loader.reset();
		}

    // if our loader is null
		if (loader != null) {
      // run our preload method
			scene.preload();

			// Is the loader empty after preload?
			if (loader.list.size == 0) {
        // if it is just create the scene.
				create(scene);
			} else {
        // if we do have things to load update our status.
				scene.status = SceneConsts.LOADING;

				// Start the loader as we have something in the queue
				loader.once('COMPLETE', () -> {
          create(loader.scene);
        });

        // start the loader.
				loader.start();
			}
		} else {
			// No preload? Then there was nothing to load either
			create(scene);
		}
	}

	/**
   * Calls the given Scene's create method and updates its status.
   */
	public function create(scene:Scene) {
    // update the Scene's status
		scene.status = SceneConsts.CREATING;

    // run it's create method.
		scene.create();

    // if it's status is 9 just return.
		if (scene.status == SceneConsts.DESTROYED) return;

		// tell the scene it can run it's update.
		scene.runUpdate = true;

    // update it's status.
		scene.status = SceneConsts.RUNNING;

    // emit the scene event.
		scene.events.emit('CREATE', scene);
	}

	/**
	 * Runs all scenes update methods.
	 */
	public function update(time:Float, delta:Float) {
		isProcessing = true;

		// Loop through the active scenes in reverse order
		for (i in new ReverseIterator((scenes.length - 1), 0)) {
			var scene = scenes[i];

			if (scene.status > SceneConsts.START && scene.status <= SceneConsts.RUNNING) {
				scene.step(time, delta);
			}
		}
	}

	/**
	 * loops through our scenes and calls their render methods.
	 */
	public function render(renderer) {
		// Loop through the scenes in forward order
		for (scene in scenes) {
      // is our scene visible and not loading or paused or anything.
			if (scene.visible && scene.status >= SceneConsts.LOADING && scene.status < SceneConsts.SLEEPING) {
				scene.render(renderer);
			}
		}

		isProcessing = false;
	}
}