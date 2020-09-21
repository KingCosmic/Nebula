package core.scene;

typedef SettingsConfig = {
  key: String,
  active:Bool,
  visible:Bool
}

class Settings {
  public var config:SettingsConfig;

  public var status:Int = 0;

  public var key:String;

  public var active:Bool = false;

  public var visible:Bool = true;

  public var isBooted:Bool = false;

  public var isTransition:Bool = false;

  public var transitionFrom:Scene;
  
  public var transitionDuration:Int = 0;
  
  public var transitionAllowInput:Bool = true;

  // Loader payload array

  public var data = {};

  public var pack:Bool = false;

  public var cameras:Array<{}>;

	public var map = {
		game: 'game',
		renderer: 'renderer',
		anims: 'anims',
		cache: 'cache',
		plugins: 'plugins',
		registry: 'registry',
		scale: 'scale',
		sound: 'sound',
		textures: 'textures',
		events: 'events',
		cameras: 'cameras',
		add: 'add',
		make: 'make',
		scenePlugin: 'scene',
		displayList: 'children',
		lights: 'lights',
		data: 'data',
		input: 'input',
		load: 'load',
		time: 'time',
		tweens: 'tweens',
		arcadePhysics: 'physics',
	};
  // public var physics
  // public var loader
  // public var plugins
  // public var input

  public function new(_config:SettingsConfig) {
    config = _config;

    key = config.key;
    active = config.active;
    visible = config.visible;
  }
}