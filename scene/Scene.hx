package core.scene;

import core.animations.AnimationManager;
import core.input.InputPlugin;
import core.loader.LoaderPlugin;
import core.textures.TextureManager;
import core.scale.ScaleManager;
import core.gameobjects.DisplayList;
import core.cameras.CameraManager;
import core.EventEmitter;

// import core.animations.AnimationManager;


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
   * A reference to the Texture Manager.
   * This property will only be available if defined in the Scene Injection Map.
   */
  public var textures:TextureManager;

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