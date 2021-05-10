package nebula;

// Kha imports
import nebula.Renderer.RendererConfig;
import nebula.assets.AssetManager;
import kha.Window;
import kha.Framebuffer;
import kha.System;
import kha.Color;

// Core imports
import nebula.scenes.SceneManager;
import nebula.scenes.Scene;

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
  ?render:RendererConfig,
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

  public var scenes:SceneManager;

  // An instance of the Time Step.
	public var timestep:TimeStep;

  /**
   * The window this game is being rendered to.
   */
  public var window:Window;

  // Does the window the game is running in currently have focus or not?
  // This is modified by the VisibilityHandler.
  public var hasFocus:Bool = false;

  public function new(_config:GameConfig) {
    config = _config;

		scenes = new SceneManager(this, config.scene);

		System.start({ title: config.title, width: config.width, height: config.height }, (_window) -> {
      // have to create our renderer after kha is initialized.
      renderer = new Renderer(this, config.render);

      // now we can boot the game.
			boot(_window);

			// TODO: make some default textures that get placed when textures are missing.
      // then call texturesReady.
      texturesReady();
		});
  }

  public function boot(_window:Window) {
    window = _window;

    isBooted = true;

    // call our internal boot method on global required plugins.
    AssetManager.boot(this);

    // emit our boot event for other custom plugins to listen to.
    events.emit('BOOT', window);
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

		timestep = new TimeStep(this, config.fps);

    timestep.start(step);
    System.notifyOnFrames(render);

    // TODO: visibility changes.
  }

  /**
	 * The main Game Step. Called automatically by the Time Step.
	 *
	 * The step will update the global managers first, then proceed to update each Scene in turn, via the Scene Manager.
   */
	public function step(time:Float, delta:Float) {
    // Global Managers like Input and Sound update in the prestep.

    events.emit('PRE_STEP', time, delta);

    // This is mostly meant for user-land code and plugins.

    events.emit('STEP', time, delta);

    // Update the Scene Manager and all active Scenes.

    scenes.update(time, delta);

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

    // emit a pre-render event incase anything needs to do code.
		events.emit('PRE_RENDER', renderer);

		// The main render loop. Iterates all Scenes and all Cameras in those scenes,
    // rendering to the renderer instance.
		scenes.render(renderer);

		// The Post-Render call. Tidies up loose end, takes snapshots, etc.
		renderer.postRender();

		// The final event before the step repeats. Your last chance to do anything
    // to the canvas before it all starts again.
		events.emit('POST_RENDER', renderer);
  }

  // Called automatically by the Visibility Handler.
  // This will pause the main loop and then emit a pause event.
  public function onHidden() {
    timestep.pause();

    events.emit('PAUSE');
  }

  // Called automatically by the Visibility Hanlder.
  // This will resume the main loop and then emit a resume event.
  public function onVisible() {
    timestep.resume();

    events.emit('RESUME');
  }

  // Called automatically by the Visibility Handler.
  // This will set the main loop into a 'blurred' state, which pauses it.
  public function onBlur() {
    hasFocus = false;

    timestep.blur();
  }

  // Called automatically by the Visibility Handler.
  // This will set the main loop into a 'focused' state, which resumes it.
  public function onFocus() {
    hasFocus = true;

    timestep.focus();
  }

  // Returns the current game frame.
  // When the game starts running, the frame is incremented every time Request Animation Frame, or Set Timeout, fires.
  public function getFrame() {
		return timestep.frame;
  }

  // Returns the time that the current game step started at, as based on `performance.now`
  public function getTime() {
		return timestep.now;
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
  }
}

/**
 * "Computers are good at following instructions, but not at reading your mind." - Donald Knuth
 */