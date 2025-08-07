package nebula.director;

import nebula.Engine;
import nebula.director.DefaultLoader;
import nebula.Scene;
import nebula.director.Transition;
import nebula.director.Loader;

import nebula.util.Log;

import nebula.Events;
import nebula.EventEmitter;

interface DirectorNavigationEvent {
  var sourceName: String;
  var sourceScene: Scene;
  var destinationName: String;
  var destinationScene: Scene;
}

typedef TDirectorEvents = {
  var navigationstart: DirectorNavigationEvent;
  var navigation: DirectorNavigationEvent;
  var navigationend: DirectorNavigationEvent;
};

var DirectorEvents = {
  NavigationStart: 'navigationstart',
  Navigation: 'navigation',
  NavigationEnd: 'navigationend'
};

interface SceneWithOptions {
  /**
   * Scene associated with this route
   *
   * If a constructor is provided it will not be constructed until navigation is requested
   */
  var scene: Scene;
  /**
   * Specify scene transitions
   */
  var transitions: Null<{
    /**
     * Optionally specify a transition when going "in" to this scene
     */
    var incoming: Null<Transition>;
    /**
     * Optionally specify a transition when going "out" of this scene
     */
    var outgoing: Null<Transition>;
  }>;
  /**
   * Optionally specify a loader for the scene
   */
  var loader: Null<DefaultLoader>;
}

interface StartOptions {
  /**
   * Optionally provide first transition from the game start screen
   */
  var inTransition: Null<Transition>;
  /**
   * Optionally provide a main loader to run before the game starts
   */
  var loader: Null<DefaultLoader>;
}

/**
 * Provide scene activation data and override any existing configured route transitions or loaders
 */
interface GoToOptions {
  /**
   * Optionally supply scene activation data passed to Scene.onActivate
   */
  var sceneActivationData: Null<Any>;
  /**
   * Optionally supply destination scene "in" transition, this will override any previously defined transition
   */
  var destinationIn: Null<Transition>;
  /**
   * Optionally supply source scene "out" transition, this will override any previously defined transition
   */
  var sourceOut: Null<Transition>;
  /**
   * Optionally supply a different loader for the destination scene, this will override any previously defined loader
   */
  var loader: Null<DefaultLoader>;
}

/**
 * The Director is responsible for managing scenes and changing scenes in Excalibur.
 *
 * It deals with transitions, scene loaders, switching scenes
 *
 * This is used internally by Excalibur, generally not mean to
 * be instantiated end users directly.
 */
class Director {
  public var events = new EventEmitter<DirectorEvents>();
  private var _logger = Logger.getInstance();
  private var _deferredGoto: Null<String>;
  private var _deferredTransition: Null<Transition>;
  private var _initialized = false;

  /**
   * Current scene's name
   */
  var currentSceneName: String;
  /**
   * Current scene playing in excalibur
   */
  var currentScene: Scene;
  /**
   * Current transition if any
   */
  var currentTransition: Null<Transition>;

  /**
   * All registered scenes in Excalibur
   */
  public var scenes: Map<String, Scene> = new Map();

  /**
   * Holds all instantiated scenes
   */
  private var _sceneToInstance = new Map<String, Scene>();

  var startScene: Null<String>;
  var mainLoader: Null<DefaultLoader>;

  /**
   * The default {@apilink Scene} of the game, use {@apilink Engine.goToScene} to transition to different scenes.
   */
  public var rootScene: Scene;

  private var _sceneToLoader = new Map<String, DefaultLoader>();
  private var _sceneToTransition = new Map<String, { incoming: Null<Transition>, outgoing: Null<Transition> }>();
  /**
   * Used to keep track of scenes that have already been loaded so we don't load multiple times
   */
  private var _loadedScenes = new Map<String, Scene>();

  private var _isTransitioning = false;

  /**
   * Gets whether the director currently transitioning between scenes
   *
   * Useful if you need to block behavior during transition
   */
  public var isTransitioning(get, never): Bool;
  function get_isTransitioning() {
    return this._isTransitioning;
  }

  public function new(
    _engine: Engine,
    scenes: Map<String, Scene>
  ) {
    this.rootScene = this.currentScene = new Scene();
    this.add('root', this.rootScene);
    this.currentScene = this.rootScene;
    this.currentSceneName = 'root';
    for (sceneKey => scene in scenes) {
      this.add(sceneKey, scene);
      if (sceneKey == 'root') {
        this.rootScene = this.getSceneInstance('root'); // always a root scene
        this.currentScene = this.rootScene;
      }
    }
  }

  /**
   * Initialize the director's internal state
   */
  function onInitialize() {
    if (!this._initialized) {
      this._initialized = true;
      if (this._deferredGoto) {
        var deferredScene = this._deferredGoto;
        this._deferredGoto = undefined;
        var deferredTransition = this._deferredTransition;
        this._deferredTransition = undefined;
        var deferredSceneInstance = this.getSceneInstance(deferredScene);
        if (deferredSceneInstance && deferredTransition) {
          deferredTransition._addToTargetScene(this._engine, deferredSceneInstance);
        }

        var inTransition = this._getInTransition(deferredScene);
        var hideLoader = inTransition?.hideLoader;
        // eslint-disable-next-line @typescript-eslint/no-floating-promises
        this.maybeLoadScene(deferredScene, hideLoader);
        this.swapScene(deferredScene).then(() -> {
          if (deferredSceneInstance && deferredTransition) {
            this.playTransition(deferredTransition, deferredSceneInstance);
          }
        });
      } else {
        this.swapScene('root');
      }
    }
  }

  public var isInitialized(get, never): Bool;
  function get_isInitialized() {
    return this._initialized;
  }

  /**
   * Configures the start scene, and optionally the transition & loader for the director
   *
   * Typically this is called at the beginning of the game to the start scene and transition and never again.
   * @param startScene
   * @param options
   */
  function configureStart(startScene: String, ?options: StartOptions) {
    var maybeLoaderOrCtor = options?.loader;
    if (maybeLoaderOrCtor) {
      this.mainLoader = maybeLoaderOrCtor;
    } else {
      this.mainLoader = new Loader();
    }

    var maybeStartTransition: Null<Transition>;

    if (options?.inTransition) {
      maybeStartTransition = options.inTransition;
    }

    this.startScene = startScene;

    var maybeHideLoader = options?.inTransition?.hideLoader ?? false;
    this.maybeLoadScene(startScene, maybeHideLoader);

    // Fire and forget promise for the initial scene
    if (maybeStartTransition) {
      var startSceneInstance = this.getSceneInstance(startScene);
      if (startSceneInstance) {
        maybeStartTransition._addToTargetScene(this._engine, startSceneInstance);
        this.swapScene(startScene).then(() -> {
          startSceneInstance.onTransition('in');

          return this.playTransition(maybeStartTransition, startSceneInstance);
        });
      }
    } else {
      this.swapScene(startScene);
    }

    this.currentSceneName = this.startScene;
  }

  private function _getLoader(sceneName: String) {
    return this._sceneToLoader.get(sceneName);
  }

  private function _getInTransition(sceneName: String): Null<Transition> {
    var sceneOrRoute = this.scenes[sceneName];
    // if (sceneOrRoute instanceof Scene || isSceneConstructor(sceneOrRoute)) {
      return null;
    // }
    // return sceneOrRoute?.transitions?.in;
  }

  private function _getOutTransition(sceneName: String): Null<Transition> {
    var sceneOrRoute = this.scenes[sceneName];
    // if (sceneOrRoute instanceof Scene || isSceneConstructor(sceneOrRoute)) {
      return null;
    // }
    // return sceneOrRoute?.transitions?.out;
  }

  function getDeferredScene() {
    var maybeDeferred = this.getSceneDefinition(this._deferredGoto);
    if (this._deferredGoto && maybeDeferred) {
      return maybeDeferred;
    }
    return null;
  }

  /**
   * Returns a scene by name if it exists, might be the constructor and not the instance of a scene
   * @param name
   */
  function getSceneDefinition(name: String): Null<Scene> {
    var maybeScene = this.scenes[name];
    // if (maybeScene instanceof Scene || isSceneConstructor(maybeScene)) {
      return maybeScene;
    // } else if (maybeScene) {
      // return maybeScene.scene;
    // }
    return null;
  }

  /**
   * Returns the name of the registered scene, null if none can be found
   * @param scene
   */
  function getSceneName(scene: Scene): Null<String> {
    for (name => maybeScene in this.scenes) {
      // if (maybeScene instanceof Scene) {
        if (scene == maybeScene) {
          return name;
        }
      // } else if (!isSceneConstructor(maybeScene)) {
        // if (scene == maybeScene.scene) {
          // return name;
        // }
      // }
    }

    for (name => maybeScene in this.scenes) {
      // if (isSceneConstructor(maybeScene)) {
        // if (scene.constructor == maybeScene) {
          // return name;
        // }
      // } else if (!(maybeScene instanceof Scene)) {
        if (scene.constructor == maybeScene.scene) {
          return name;
        }
      // }
    }
    return null;
  }

  /**
   * Returns the same Director, but asserts a scene DOES exist to the type system
   * @param name
   */
  function assertAdded(name: String): Director {
    return this;
  }

  /**
   * Returns the same Director, but asserts a scene DOES NOT exist to the type system
   * @param name
   */
  function assertRemoved(name: String): Director {
    return this;
  }

  /**
   * Adds additional Scenes to the game!
   * @param name
   * @param sceneOrRoute
   */
  function add(name: String, scene: Scene): Director {
    if (this.scenes[name]) {
      this._logger.warn('Scene', name, 'already exists overwriting');
    }
    this.scenes[name] = scene;
    return this.assertAdded(name);
  }

  function remove(name: String) {
    if (nameOrScene == this.currentSceneName) {
      throw new Error('Cannot remove a currently active scene: ${nameOrScene}');
    }

    // remove scene
    this._sceneToInstance.delete(nameOrScene);
    this._sceneToTransition.delete(nameOrScene);
    this._sceneToLoader.delete(nameOrScene);
    this.scenes.delete(nameOrScene);
  }

  /**
   * Go to a specific scene, and optionally override loaders and transitions
   * @param destinationScene
   * @param options
   */
  function goToScene(destinationScene: String, ?options: Any) {
    var maybeDest = this.getSceneInstance(destinationScene);
    if (!maybeDest) {
      this._logger.warn('Scene ${destinationScene} does not exist! Check the name, are you sure you added it?');
      return;
    }
    var sourceSceneInstance = this.currentScene;
    var sourceScene = this.currentSceneName;
    var engineInputEnabled = this._engine.input?.enabled ?? true;
    this._isTransitioning = true;

    var maybeSourceOut = this.getSceneInstance(sourceScene)?.onTransition('out');
    var maybeDestinationIn = maybeDest?.onTransition('in');

    options = Object.spreadWith(
      { sourceOut: this._getOutTransition(this.currentSceneName) ?? maybeSourceOut },
      Object.spreadwith(
        { destinationIn: this._getInTransition(destinationScene) ?? maybeDestinationIn },
        options
      )
    );

    var sourceOut = options.sourceOut,
        destinationIn = options.destinaionIn,
        sceneActivationData = options.sceneActivationData;

    var outTransition = sourceOut ?? this._getOutTransition(this.currentSceneName);
    var inTransition = destinationIn ?? this._getInTransition(destinationScene);

    var hideLoader = outTransition?.hideLoader || inTransition?.hideLoader;
    if (hideLoader) {
      // Start hidden loader early and take advantage of the transition
      // Don't await and block on a hidden loader

      // eslint-disable-next-line @typescript-eslint/no-floating-promises
      this.maybeLoadScene(destinationScene, hideLoader);
    }

    this._emitEvent('navigationstart', sourceScene, destinationScene);

    // Run the out transition on the current scene if present
    if (outTransition) {
      this.playTransition(outTransition, sourceSceneInstance);
    }

    // Run the loader if present
    this.maybeLoadScene(destinationScene, hideLoader);

    // Give incoming transition a chance to grab info from previous
    if (inTransition) {
      inTransition.onPreviousSceneDeactivate(this.currentScene);
    }

    // Setup the in transition on the destination scene if present
    // this is important to it can be initialized with the
    if (inTransition) {
      inTransition._addToTargetScene(this._engine, maybeDest);
    }

    // Swap to the new scene
    // Runs scene lifecycle init and activate
    this.swapScene(destinationScene, sceneActivationData);
    this._emitEvent('navigation', sourceScene, destinationScene);

    // Run the in transition on the new scene if present
    if (inTransition) {
      this.playTransition(inTransition, maybeDest);
    }
    this._emitEvent('navigationend', sourceScene, destinationScene);

    this._engine.input?.toggleEnabled(engineInputEnabled);
    this._isTransitioning = false;
  }

  /**
   * Retrieves a scene instance by key if it's registered.
   *
   * This will call any constructors that were given as a definition
   * @param scene
   */
  function getSceneInstance(scene: String): Null<Scene> {
    var sceneDefinition = this.getSceneDefinition(scene);
    if (!sceneDefinition) {
      return undefined;
    }
    if (this._sceneToInstance.has(scene)) {
      return this._sceneToInstance.get(scene);
    }
    // if (sceneDefinition instanceof Scene) {
      this._sceneToInstance.set(scene, sceneDefinition);
      return sceneDefinition;
    // }
    // var newScene = new SceneDefinition();
    // this._sceneToInstance.set(scene, newScene);
    // return newScene;
  }

  /**
   * Triggers scene loading if has not already been loaded
   * @param scene
   * @param hideLoader
   */
  function maybeLoadScene(scene: String, hideLoader = false) {
    var loader = this._getLoader(scene) ?? new DefaultLoader();
    var sceneToLoad = this.getSceneDefinition(scene);
    var sceneToLoadInstance = this.getSceneInstance(scene);
    if (sceneToLoad && sceneToLoadInstance && !this._loadedScenes.has(sceneToLoadInstance)) {
      sceneToLoadInstance.onPreLoad(loader);
      sceneToLoadInstance.events.emit('preload', { loader: loader });
      if (hideLoader) {
        // Don't await a hidden loader

        // eslint-disable-next-line @typescript-eslint/no-floating-promises
        this._engine.load(loader, hideLoader);
      } else {
        this._engine.load(loader);
      }
      this._loadedScenes.add(sceneToLoadInstance);
    }
  }

  /**
   * Plays a transition in the current scene and does book keeping for input.
   * @param transition
   */
  function playTransition(transition: Transition, targetScene: Scene) {
    if (!this.isInitialized) {
      this._deferredTransition = transition;
      return;
    }

    if (transition) {
      this.currentTransition = transition;
      final sceneInputEnabled = targetScene.input?.enabled ?? true;

      targetScene.input?.toggleEnabled(!transition.blockInput);
      this._engine.input?.toggleEnabled(!transition.blockInput);

      targetScene.events.emit('transitionstart', transition);
      this.currentTransition._addToTargetScene(this._engine, targetScene);
      this.currentTransition._play();
      targetScene.events.emit('transitionend', transition);

      targetScene.input.toggleEnabled(sceneInputEnabled);
    }
    this.currentTransition.kill();
    this.currentTransition.reset();
    this.currentTransition = null;
  }

  /**
   * Swaps the current and destination scene after performing required lifecycle events
   *
   * Note: swap scene will wait for any pending loader on the destination scene
   * @param destinationScene
   * @param data
   */
  function swapScene(destinationScene: String, ?data: Any): Any {
    var engine = this._engine;
    // if not yet initialized defer goToScene
    if (!this.isInitialized) {
      this._deferredGoto = destinationScene;
      return;
    }

    var maybeDest = this.getSceneInstance(destinationScene);

    if (maybeDest) {
      var previousScene = this.currentScene;
      var nextScene = maybeDest;
      var previousSceneData: Null<Any> = null;

      this._logger.debug('Going to scene:', destinationScene);
      // only deactivate when initialized
      if (this.currentScene.isInitialized) {
        var context = { engine: engine, previousScene: previousScene, nextScene: nextScene };
        previousSceneData = this.currentScene._deactivate(context);
        this.currentScene.events.emit('deactivate', new DeactivateEvent(context, this.currentScene));
        this.currentScene.input.clear();
      }

      // wait for the scene to be loaded if needed
      var destLoader = this._sceneToLoader.get(destinationScene);
      destLoader.areResourcesLoaded();

      // set current scene to new one
      this.currentScene = nextScene;
      this.currentSceneName = destinationScene;
      engine.screen.setCurrentCamera(nextScene.camera);

      // initialize the current scene if has not been already
      this.currentScene._initialize(engine);

      var context = { engine: engine, previousScene: previousScene, previousSceneData: previousSceneData, nextScene: nextScene, data: data };
      this.currentScene._activate(context);
      this.currentScene.events.emit('activate', new ActivateEvent(context, this.currentScene));
    } else {
      this._logger.error('Scene', destinationScene, 'does not exist!');
    }
  }

  private function _emitEvent(eventName: String, sourceScene: String, destinationScene: String) {
    var source = this.getSceneDefinition(sourceScene)!;
    var dest = this.getSceneDefinition(destinationScene)!;
    this.events.emit(eventName, {
      sourceScene: source,
      sourceName: sourceScene,
      destinationScene: dest,
      destinationName: destinationScene
    });
  }
}
