package nebula.scene;

import nebula.cameras.CameraManager;
import nebula.assets.AssetManager;
import nebula.loader.LoaderPlugin;
import nebula.EventEmitter;

typedef SceneConfig = {
	key:String,
	active:Bool,
	visible:Bool
}

class Scene {
	/**
	 * The key used to identify this scene
	 */
  public var key:String;

	// The config passed to the scene
	public var config:SceneConfig;

	// A reference to the Phaser.Game instance
	public var game:Game;

	/**
	 * The scenes current status
	 */
	public var status:Int = 0;

	/**
	 * Is this scene active?
	 */
	public var active:Bool = false;

	/**
	 * Is this scene visible?
	 */
	public var visible:Bool = true;

	/**
	 * Is this scene booted?
	 */
	public var isBooted:Bool = false;

	/**
	 * Should we run the update function?
   * 
   * Keeps us from running update before create is done.
   */
	public var runUpdate:Bool = false;

	/**
	 * A reference to the AssetManager.
	 */
	public var assets:AssetManager;

	// EventEmitter
	public var events:EventEmitter = new EventEmitter();

	// Camera Systems.
	public var cameras:CameraManager;

	// A reference to the Scene Manager Plugin.
	public var manager:SceneManager;
  
	/**
	 * Use this to organize the children contained in the update list.
	 *
	 * The Update List is responsible for managing children that need their `preUpdate` methods called,
	 * in order to process so internal components, such as Sprites with Animations.
	 */
	public var updateList:UpdateList;

	// A Scene level Game Object Display List.
	public var displayList:DisplayList;

	/**
	 * A scene level Loader Plugin.
	 */
	public var load:LoaderPlugin;

	public function new(_config:SceneConfig) {
		config = _config;

    key = config.key;

		status = 1;

		displayList = new DisplayList(this);

		updateList = new UpdateList(this);

		cameras = new CameraManager(this);

		load = new LoaderPlugin(this);
	}

	public function setManager(_game:Game, _manager:SceneManager) {
		manager = _manager;
		game = _game;

		events.emit('BOOT', this);

		isBooted = true;
	}

	// Should be overriden by your own Scenes.
	public function init(?data:Any) {}

	// Should be overriden by your own Scenes.
	public function preload() {}

	// Should be overridden by your own Scenes.
	public function create() {}

	// Should be overridden by your own Scenes.
	// This method is called once per game step while the scene is running.
	public function update(time:Float, delta:Float) {}

	/**
	 * A single game step. Called automatically by the Scene Manager as a result of the timeloop
	 * call to the main Game instance.
	 */
	public function step(time:Float, delta:Float) {
		events.emit('PRE_UPDATE', time, delta);

		events.emit('UPDATE', time, delta);

		if (runUpdate)
			update(time, delta);

		events.emit('POST_UPDATE', time, delta);
	}

	/**
	 * Called automatically by the Scene Manager.
	 * Instructs the Scene to render itself via its Camera Manager to the renderer given.
	 */
	public function render(renderer:Renderer) {
		displayList.depthSort();

		cameras.render(renderer, displayList);

		events.emit('RENDER', renderer);
	}

	// Force a sort of the display list on the next render.
	public function queueDepthSort() {
		displayList.queueDepthSort();
	}

	// Immediately sorts the display list if the flag is set.
	public function depthSort() {
		displayList.depthSort();
	}

	/**
	 * Pause this Scene.
	 * A paused Scene still renders, it just doesn't run ANY of its update handlers or systems.
	 */
	public function pause(data:Any) {
		if (active) {
			status = 6;

			active = false;

			events.emit('PAUSE', this, data);
		}

		return this;
	}

	// Resume this Scene from a paused state.
	public function resume(data) {
		if (!active) {
      status = 5;

			active = true;

			events.emit('RESUME', this, data);
		}

		return this;
	}

	/**
	 * Send this Scene to sleep.
	 *
	 * A sleeping Scene doesn't run its update step or render anything, but it also isn't shut down
	 * or has any of its systems or children removed, meaning it can be re-activated at any point and
	 * will carry on from where it left off. It also keeps everything in memory and events and callbacks
	 * from other Scenes may still invoke changes within it, so be careful what is left active.
	 */
	public function sleep(data:Any) {
		status = 7;

		active = false;
		visible = false;

		events.emit('SLEEP', this, data);

		return this;
	}

	/**
   * Wake-up this Scene if it was previously asleep.
   */
	public function wake(data:Any) {
		status = 5;

		active = true;
		visible = true;

		events.emit('WAKE', this, data);

		return this;
	}

	/**
	 * Returns any data that was sent to this Scene by another Scene.
	 *
	 * The data is also passed to `Scene.init` and in various Scene events, but
	 * you can access it at any point via this method.
	 */
	public function getData() {
		return {};
	}

	// Is this Scene sleeping?
	public function isSleeping() {
		return (status == 7);
	}

	// Is this Scene running?
	public function isActive() {
		return (status == 5);
	}

	// Is this Scene paused?
	public function isPaused() {
		return (status == 6);
	}

	// Is this Scene visible and rendering?
	public function isVisible() {
		return visible;
	}

	/**
	 * Sets the visible state of this Scene.
	 * An invisible Scene will not render, but will still process updates.
	 */
	public function setVisible(v:Bool) {
		visible = v;

		return this;
	}

	// Set the active state of this Scene.
	// An active Scene will run it's core update loop.
	public function setActive(active:Bool, data:{}) {
		if (active) {
			return resume(data);
		} else {
			return pause(data);
		}
	}

	// Start this Scene running and rendering.
	// Called automatically by the SceneManager.
	public function start(?data:{}) {
		if (data != null) {
			// data = data;
		}

		status = 2;

		active = true;
		visible = true;

		// For plugins to listen out for
		events.emit('START', this);

		// For user-land code to listen out for
		events.emit('READY', this, data);
	}

	/**
	 * Shutdown this Scene and send a shutdown event to all of its systems.
	 * A Scene that has been shutdown will not run its update loop or render, but it does
	 * not destroy any of its plugins or references. It is put into hibernation for later use.
	 * If you don't ever plan to use this Scene again, then it should be destroyed instead
	 * to free-up resources.
	 */
	public function shutdown(?data:Any) {
		events.clearEvent('TRANSITON_INIT');
		events.clearEvent('TRANSITION_START');
		events.clearEvent('TRANSITION_COMPLETE');
		events.clearEvent('TRANSITION_OUT');

		status = 8;

		active = false;
		visible = false;

		events.emit('SHUTDOWN', this, data);
	}

	/**
	 * Destroy this Scene and send a destroy event all of its systems.
	 * A destroyed Scene cannot be restarted.
	 * You should not call this directly, instead use `SceneManager.remove`.
	 */
	public function destroy() {
		status = 9;

		active = false;
    visible = false;

		events.emit('DESTROY', this);

		events.removeAllListeners();

		manager = null;
		game = null;
		assets = null;
		cameras = null;
		displayList = null;
		events = null;
		updateList = null;
	}
}