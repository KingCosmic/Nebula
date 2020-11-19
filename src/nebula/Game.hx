package nebula;

// Kha imports
import kha.Framebuffer;
import kha.System;
import kha.Color;

// core code
import nebula.animations.AnimationManager;
import nebula.assets.AssetManager;
import nebula.input.InputManager;
import nebula.scale.ScaleManager;
import nebula.scene.SceneManager;
import nebula.scene.Scene;

typedef GameConfig = {
  title:String,
  ?width:Int,
  ?height:Int,
  ?zoom:Float,
  ?resolution:Float,
  scene:Array<Class<Scene>>,
  ?version:String,
  // ?input:Input.InputConfig,
  ?fps:Int,
  // ?render:RenderConfig,
  ?backgroundColor:Color,
}

class Game {
  public var config:GameConfig;

  // The renderer this game is using.
  public var renderer:Renderer;

  // A flag indicating when this Game instance has finished its boot process.
  public var isBooted:Bool = false;

  // A flag indicating if this Game is currently running it's game step or not.
  public var isRunning:Bool = false;

	// An Event Emitter which is used to broadcast game-level events from the global systems.
  public var events:EventEmitter = new EventEmitter();

  // An instance of the Animation Manager.
  public var anims:AnimationManager;

  // An instance of the Asset Manager.
  // The Asset Manager is a global system responsible for managing all textures being used by your game.
  public var assets:AssetManager;

  // An instance of the Cache Manager.
  // The Cache Manager is a global system responsible for caching, accessing and releasing external game assets.
  // public var cache: CacheManager = new CacheManager(this);

  // An instance of the Data Manager.
  // public var registry: DataManager = new DataManager(this);

  // An instance of the Input Manager.
  // The Input Manager is a global system responsible for the capture of browser-level input events.
  public var input:InputManager;

  // An instance of the Scene Manager.
  // The Scene Manager is a global system responsible for creating, modifying and updating the Scenes in your game.
  public var scene:SceneManager;

  // A reference to the Device inspector.
  // Contains information about the device running this game, such as OS, browser vendor and feature support.
  // Used by various systems to determine capabilities and code paths.
  // public var device = Device;

	/**
   * An instance of the Scale Manager.
   *
   * The Scale Manager is a global system responsible for handling scaling of the game canvas.
   */
  public var scale:ScaleManager;

  // An instance of the base Sound Manager.
  // The Sound Manager is a global system responsible for the playback and updating of all audio in your game.
  // public var sound = SoundManagerCreator.create(this);

  // An instance of the Time Step.
  // The Time Step is a global system responsible for setting-up and responding to the browser events, ...
  // ... processing them and calculating delta values. It then automatically calls the game step.
  public var loop:TimeStep;

  // Is this Game pending destruction at the start of the next frame?
  public var pendingDestroy:Bool = false;

  // Does the window the game is running in currently have focus or not?
  // This is modified by the VisibilityHandler.
  public var hasFocus:Bool = false;

  public function new(_config:GameConfig) {
    config = _config;

    anims = new AnimationManager(this);

    assets = new AssetManager(this);

		input = new InputManager(this, this.config);
    
		scene = new SceneManager(this, config.scene);

		System.start({ title: config.title, width: config.width, height: config.height }, (window) -> {
      // we have to initialize kha things once window starts.
			scale = new ScaleManager(this);

      renderer = new Renderer(this);

      // now we can boot the game.
			boot(window);
			// TODO: make some default textures that get placed when textures are missing.
      texturesReady();
		});
  }

  public function boot(window:kha.Window) {
    isBooted = true;

    scale.preBoot(window);

    events.emit('BOOT');
  }

  // Called automatically when the Texture Manager has ...
  // finished setting up and preparing the default textures
  public function texturesReady() {
    events.emit('READY');

    start();
  }

  // Called automatically by Game.boot once all of the global systems have finished setting themselves up.
  // By this point the Game is now ready to start the main loop running.
  // It will also enable the Visibility Handler.
  public function start() {
    isRunning = true;

    loop = new TimeStep(this, config.fps);

    loop.start(step);
    System.notifyOnFrames(render);

    // TODO: visibility changes.
  }

  /**
	 * The main Game Step. Called automatically by the Time Step.
	 *
	 * The step will update the global managers first, then proceed to update each Scene in turn, via the Scene Manager.
   */
	public function step(time:Float, delta:Float) {
    if (pendingDestroy)
      return runDestroy();

    // Global Managers like Input and Sound update in the prestep.

    events.emit('PRE_STEP', time, delta);

    // This is mostly meant for user-land code and plugins.

    events.emit('STEP', time, delta);

    // Update the Scene Manager and all active Scenes.

    scene.update(time, delta);

    // Our final event before rendering starts.

    events.emit('POST_STEP', time, delta);
  }

  /*
   * Render our game via the Renderer. This process emits `prerender` and `postrender` events.
   */
  public function render(frames:Array<Framebuffer>) {

    // grab our buffer from the incoming frames.
    final buffer = frames[0];

		// Run the Pre-render (clearing the canvas, setting background colors, etc)
		renderer.preRender(buffer);

		events.emit('PRE_RENDER', renderer);

		// The main render loop. Iterates all Scenes and all Cameras in those scenes, rendering to the renderer instance.

		scene.render(renderer);

		// The Post-Render call. Tidies up loose end, takes snapshots, etc.

		renderer.postRender();

		// The final event before the step repeats. Your last chance to do anything to the canvas before it all starts again.

		events.emit('POST_RENDER', renderer);
  }

  // Called automatically by the Visibility Handler.
  // This will pause the main loop and then emit a pause event.
  public function onHidden() {
    loop.pause();

    events.emit('PAUSE');
  }

  // Called automatically by the Visibility Hanlder.
  // This will resume the main loop and then emit a resume event.
  public function onVisible() {
    loop.resume();

    events.emit('RESUME');
  }

  // Called automatically by the Visibility Handler.
  // This will set the main loop into a 'blurred' state, which pauses it.
  public function onBlurt() {
    hasFocus = false;

    loop.blur();
  }

  // Called automatically by the Visibility Handler.
  // This will set the main loop into a 'focused' state, which resumes it.
  public function onFocus() {
    hasFocus = true;

    loop.focus();
  }

  // Returns the current game frame.
  // When the game starts running, the frame is incremented every time Request Animation Frame, or Set Timeout, fires.
  public function getFrame() {
    return loop.frame;
  }

  // Returns the time that the current game step started at, as based on `performance.now`
  public function getTime() {
    return loop.now;
  }

  /**
	 * Flags this Game instance as needing to be destroyed on the _next frame_, making this an asynchronous operation.
	 *
	 * It will wait until the current frame has completed and then call `runDestroy` internally.
	 *
	 * If you need to react to the games eventual destruction, listen for the `DESTROY` event.
	 *
	 * If you **do not** need to run Phaser again on the same web page you can set the `noReturn` argument to `true` and it will free-up
	 * memory being held by the core Phaser plugins. If you do need to create another game instance on the same page, leave this as `false`.
   */
  public function destroy() {
    // TODO: make this.
    pendingDestroy = true;
  }

  // Destroys this Phaser.Game instance, all global systems, all sub-systems and all Scenes.
  public function runDestroy() {
    scene.destroy();

    events.emit('DESTROY');

    events.removeAllListeners();

    renderer.destroy();

    loop.destroy();

    pendingDestroy = false;
  }
}

/**
 * "Computers are good at following instructions, but not at reading your mind." - Donald Knuth
 */