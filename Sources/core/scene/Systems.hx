package core.scene;

import core.animations.AnimationManager;
import core.textures.TextureManager;
import core.scene.Scene.SceneConfig;
import core.gameobjects.DisplayList;
import core.gameobjects.UpdateList;
import core.cameras.CameraManager;
import core.loader.LoaderPlugin;
import core.scale.ScaleManager;
import core.input.InputPlugin;

class Systems {
  // The Scene Configuration object, as passed in when creating the Scene.
	public var config:SceneConfig;

  // A reference to the Scene that these Systems belong to.
  public var scene:Scene;

  // A reference to the Phaser.Game isntance.
  public var game:Game;

  // A reference to the renderer
  public var renderer:Renderer;

  // The Scene Settings. This is the parsed output based on the Scene configuration.
  public var settings:Settings;

  // Should we run the scenes update function? (used to not run update before create and such are done)
  public var runSceneUpdate:Bool = false;

  // Global Systems - these are single-instance global managers that belong to Game
  
  /**
   * A reference to the global Animations Manager.
   *
   * In the default set-up you can access this from within a Scene via the `this.anims` property.
   */
  public var anims:AnimationManager;

	/**
   * A reference to the global Scale Manager.
   *
   * In the default set-up you can access this from within a Scene via the `this.scale` property.
   */
  public var scale:ScaleManager;

	/**
   * A reference to the global Texture Manager.
   *
   * In the default set-up you can access this from within a Scene via the `this.textures` property.
   */
  public var textures:TextureManager;

  // TODO: get the rest of the global plugins.

  // Core PLugins - these are non-optional Scene plugins, needed by lots of the other systems

	/**
   * A reference to the Scene's Camera Manager.
   *
   * Use this to manipulate and create Cameras for this specific Scene.
   *
   * In the default set-up you can access this from within a Scene via the `this.cameras` property.
   */
  public var cameras:CameraManager;

  /**
   * A reference to the Scene's Display List.
   *
   * Use this to organize the children contained in the display list.
   *
   * In the default set-up you can access this from within a Scene via the `this.children` property.
   */
  public var displayList:DisplayList;

  /**
   * A reference to the Scene's Event Manager.
   *
   * Use this to listen for Scene specific events, such as `pause` and `shutdown`.
   *
   * In the default set-up you can access this from within a Scene via the `this.events` property.
   */
  public var events:EventEmitter;

  /**
   * A reference to the Scene Manager Plugin.
   *
   * Use this to manipulate both this and other Scene's in your game, for example to launch a parallel Scene,
   * or pause or resume a Scene, or switch from this Scene to another.
   *
   * In the default set-up you can access this from within a Scene via the `this.scene` property.
   */
  public var scenePlugin:SceneManager;

  public var load:LoaderPlugin;

  public var input:InputPlugin;

  /**
   * A reference to the Scene's Update List.
   *
   * Use this to organize the children contained in the update list.
   *
   * The Update List is responsible for managing children that need their `preUpdate` methods called,
   * in order to process so internal components, such as Sprites with Animations.
   *
   * In the default set-up there is no reference to this from within the Scene itself.
   */
  public var updateList:UpdateList;

	public function new(_scene:Scene, _config:SceneConfig) {
    config = _config;
    scene = _scene;

    scale = scene.game.scale;

    events = scene.events;

    settings = new Settings(config);
  }

  /**
   * This method is called only once by the Scene Manager when the Scene is instantiated.
   * It is responsible for setting up all of the Scene plugins and references.
   * It should never be called directly
   */
  public function init(_game:Game) {
    game = _game;

    settings.status = 1;

    displayList = new DisplayList(scene, this);
    scene.children = displayList;

    updateList = new UpdateList(scene, this);

    anims = game.anims;
    scene.anims = anims;

    cameras = new CameraManager(scene);
    scene.cameras = cameras;

    textures = game.textures;
    scene.textures = textures;

    load = new LoaderPlugin(scene);
    scene.load = load;

    input = new InputPlugin(scene);
    scene.input = input;
    
    events.emit('BOOT', this);

    settings.isBooted = true;
  }

  // Called by a plugin, it tells the System to install the plugin locally.
  public function install(_plugins: Array<{}>) {
    // plugins.installLocal(this, _plugins);
  }

  /**
   * A single game step. Called automatically by the Scene Manager as a result of the timeloop
   * call to the main Game instance.
   */
  public function step(time:Float, delta:Float) {
    events.emit('PRE_UPDATE', time, delta);

    events.emit('UPDATE', time, delta);

    if (runSceneUpdate) scene.update(time, delta);

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
    if (settings.active) {
      settings.status = 6;

      settings.active = false;

      events.emit('PAUSE', this, data);
    }

    return this;
  }

  // Resume this Scene from a paused state.
  public function resume(data) {
    if (!settings.active) {
      settings.status = 5;

      settings.active = true;

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
    settings.status = 7;

    settings.active = false;
    settings.visible = false;

    events.emit('SLEEP', this, data);

    return this;
  }

  // Wake-up this Scene if it was previously asleep.
  public function wake(data:Any) {
    settings.status = 5;

    settings.active = true;
    settings.visible = true;
    
    events.emit('WAKE', this, data);

    if (settings.isTransition) {
      events.emit('TRANSITION_WAKE', settings.transitionFrom, settings.transitionDuration);
    }

    return this;
  }

  /**
   * Returns any data that was sent to this Scene by another Scene.
   *
   * The data is also passed to `Scene.init` and in various Scene events, but
   * you can access it at any point via this method.
   */
  public function getData() {
    return settings.data;
  }

  // Is this Scene sleeping?
  public function isSleeping() {
    return (settings.status == 7);
  }

  // Is this Scene running?
  public function isActive() {
    return (settings.status == 5);
  }

  // Is this Scene paused?
  public function isPaused() {
    return (settings.status ==  6);
  }

  // Is this Scene currently transitioning out to, or in from another Scene?
  public function isTransitioning() {
    return (settings.isTransition || scenePlugin._target != null);
  }

  // Is this Scene currently transitioning out from itself to another Scene?
  public function isTransitionOut() {
		return (scenePlugin._target != null && scenePlugin._duration > 0);
  }

  // Is this Scene currently transitioning in from another Scene?
  public function isTransitionIn() {
    return settings.isTransition;
  }

  // Is this Scene visible and rendering?
  public function isVisible() {
    return settings.visible;
  }

  /**
   * Sets the visible state of this Scene.
   * An invisible Scene will not render, but will still process updates.
   */
  public function setVisible(visible:Bool) {
    settings.visible = visible;

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
      settings.data = data;
    }

    settings.status = 2;

    settings.active = true;
    settings.visible = true;

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

    settings.status = 8;

    settings.active = false;
    settings.visible = false;

    events.emit('SHUTDOWN', this, data);
  }

  /**
   * Destroy this Scene and send a destroy event all of its systems.
   * A destroyed Scene cannot be restarted.
   * You should not call this directly, instead use `SceneManager.remove`.
   */
  public function destroy() {
    settings.status = 9;

    settings.active = false;
    settings.visible = false;

    events.emit('DESTROY', this);

    events.removeAllListeners();
    
    scene = null;
    game = null;
    anims = null;
    // cache = null;
    // registry = null;
    // sound = null;
    textures = null;
    cameras = null;
    displayList = null;
    events = null;
    scenePlugin = null;
    updateList = null;
  }
}