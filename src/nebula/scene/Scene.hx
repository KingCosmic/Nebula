package nebula.scene;

import nebula.animations.AnimationManager;
import nebula.gameobjects.DisplayList;
import nebula.cameras.CameraManager;
import nebula.assets.AssetManager;
import nebula.loader.LoaderPlugin;
import nebula.scale.ScaleManager;
import nebula.input.InputPlugin;
import nebula.EventEmitter;

typedef SceneConfig = {
  key:String,
  active:Bool,
  visible:Bool
}

class Scene {
  // The config passed to the scene
	public var config:SceneConfig;

	// The Scene Systems. You must never overwrite this property, or all hell will break lose.
  public var sys:Systems;

  // A reference to the Phaser.Game instance
  public var game:Game;

	/**
	 * A reference to the global Animations Manager.
	 */
	public var anims:AnimationManager;

  /**
   * A reference to the AssetManager.
   */
  public var assets:AssetManager;

  // A Scene level EventEmitter
  public var events:EventEmitter = new EventEmitter();

  // A Scene level Camera Systems.
  public var cameras:CameraManager;

  // A reference to the Scene Manager Plugin.
  public var scene:SceneManager;

  // A Scene level Game Object Display List.
  public var children:DisplayList;

  // A Scene level Time and Clock Plugin.
  // public var time;

  /**
   * A scene level Loader Plugin.
   * This property will only be available if defined in the Scene Injection Map and the plugin is installed.
   */
  public var load:LoaderPlugin;

  /**
   * A scene level Input Manager Plugin.
   * This property will only be available if defined in the Scene Injection Map and the plugin is installed.
   */
  public var input:InputPlugin;

  // A reference to the global Scale Manager.
  public var scale:ScaleManager;

	public function new(_config:SceneConfig) {
    config = _config;
  }

  public function setManager(_scene:SceneManager) {
    scene = _scene;
    game = scene.game;
    sys = new Systems(this, config);

    scale = game.scale;
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
}