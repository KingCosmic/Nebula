package nebula.scenes;

import nebula.cameras.CameraManager;
import nebula.loader.Loader;

typedef SceneConfig = {
	key:String,
	active:Bool,
	visible:Bool,
  loader:Bool
}

class Scene {
	/**
	 * The key used to identify this scene
	 */
	public var key:String;

	/**
	 * The config passed to the scene
	 */
	public var config:SceneConfig;

	/**
	 * A reference to the Nebula.Game instance
	 */
	public var game:Game;

	/**
	 * The scenes current status
	 */
	public var status:Int = SceneConsts.PENDING;

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
	 * Scene level EventEmitter.
	 */
	public var events:EventEmitter = new EventEmitter();

	/**
	 * This Manages all cameras for this scene.
	 */
	public var cameras:CameraManager;

	/**
	 * A reference to the game level Scene Manager.
	 */
	public var manager:SceneManager;

	/**
	 * The Update List is responsible for managing children that need their `preUpdate` methods called,
	 * in order to process so internal components, such as Sprites with Animations.
	 */
	public var updateList:UpdateList;

	/**
	 * Displaylist for rendering gameobjects
	 */
	public var displayList:Null<DisplayList>;


	/**
	 * this scenes loader, populated by the user if they need to laod anything.
	 */
  public var load:Dynamic;

	public function new(_config:SceneConfig) {
		config = _config;

		key = config.key;

		status = SceneConsts.INIT;

		displayList = new DisplayList(this);

		updateList = new UpdateList(this);

		cameras = new CameraManager(this);

    // if we need the loader we add it to the scene.
    if (config.loader) load = new Loader(this);
	}

	/**
	 * a internal boot method to setup some internal variables for the scene.
   * This is called by the SceneManager there should be no reason to call this manually.
	 */
	public function boot(_game:Game, _manager:SceneManager) {
		manager = _manager;
		game = _game;

		events.emit('BOOT', this);

		isBooted = true;
	}

	/**
	 * Should be overriden by your own Scenes.
	 */
	public function init(?data:Any) {}

	/**
	 * Should be overriden by your own Scenes.
	 */
	public function preload() {}

	/**
	 * Should be overridden by your own Scenes.
	 */
	public function create() {}

	/**
	 * Should be overridden by your own Scenes.
	 * This method is called once per game step while the scene is running.
	 */
	public function update(time:Float, delta:Float) {}

	/**
	 * A single game step. Called automatically by the Scene Manager as a result of the timeloop
	 * call to the main Game instance.
	 */
	public function step(time:Float, delta:Float) {
    // if we shouldn't run the udpate function, just return.
		if (!runUpdate) return;

    // emit our preupdate event
		events.emit('PRE_UPDATE', time, delta);

    // emit our update event.
		events.emit('UPDATE', time, delta);

    // run our scene update.
    update(time, delta);

    // emit our post update event.
		events.emit('POST_UPDATE', time, delta);
	}

	/**
	 * Called automatically by the Scene Manager.
	 * Instructs the Scene to render itself via its Camera Manager to the renderer given.
	 */
	public function render(renderer:Renderer) {
    // sort our displaylist by depth.
		displayList.depthSort();

    // render our displaylist.
		cameras.render(renderer, displayList);

    // emit our render event.
		events.emit('RENDER', renderer);
	}

	/**
	 * Force a sort of the display list on the next render.
	 */
	public function queueDepthSort() {
    // queue a displayList sort for next render.
		displayList.queueDepthSort();
	}

	/**
	 * Immediately sorts the display list if the flag is set.
	 */
	public function depthSort() {
    // sort our displaylist
		displayList.depthSort();
	}

	/**
	 * Pause this Scene.
	 * A paused Scene still renders, it just doesn't run ANY of its update handlers or systems.
	 */
	public function pause(data:Any) {
    // if we're already paused, just return for chaining.
    if (!active) return this;

    // change our status.
    status = SceneConsts.PAUSED;

    // set our active flag.
    active = false;

    // emit our pause event.
    events.emit('PAUSE', this, data);

    // return for chaining.
		return this;
	}

	/**
	 * Resume this Scene from a paused state.
	 */
	public function resume(data) {
		if (!active) {
			status = SceneConsts.RUNNING;

			active = true;

			events.emit('RESUME', this, data);
		}

		return this;
	}

	/**
	 * Is this Scene running?
	 */
	public function isActive() {
		return (status == SceneConsts.RUNNING);
	}

	/**
	 * Is this Scene paused?
	 */
	public function isPaused() {
		return (status == SceneConsts.PAUSED);
	}

	/**
	 * Is this Scene visible and rendering?
	 */
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

	/**
	 * Set the active state of this Scene.
	 * An active Scene will run it's core update loop.
	 */
	public function setActive(active:Bool, data:{}) {
		if (active) {
			return resume(data);
		} else {
			return pause(data);
		}
	}

	/**
	 * Start this Scene running and rendering.
	 * Called automatically by the SceneManager.
	 */
	public function start(?data:{}) {
		if (data != null) {
			// data = data;
		}

		status = SceneConsts.START;

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

		status = SceneConsts.SHUTDOWN;

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
		status = SceneConsts.DESTROYED;

		active = false;
		visible = false;

		events.emit('DESTROY', this);

		events.removeAllListeners();

		manager = null;
		game = null;
		cameras = null;
		displayList = null;
		events = null;
		updateList = null;
	}
}