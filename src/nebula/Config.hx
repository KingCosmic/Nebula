package nebula;

import nebula.scenes.Scene;
import kha.Color as Color;

typedef GameConfig = {
  ?title:String,
  ?width:Int,
  ?height:Int,
  ?zoom:Float,
  ?resolution:Float,
  scenes:Array<Class<Scene>>,
  ?version:String,
  // ?input:Input.InputConfig,
  ?fps:Int,
  ?backgroundColor:Color,
}

class Config {
  static public var instance:Config;

  public var title:String = "Nebula Starter Kit";

  public var width:Int = 800;
  public var height:Int = 600;
  public var zoom:Float = 1.0;
  public var resolution:Float = 1.0;
  public var scenes:Array<Class<Scene>> = [];
  public var fps:Int = 60;
  public var background:Color = Color.Black;
  public var debug:Bool = false;
  public var fullscreen:Bool = false;
  public var version:String = "1.0.0";

  public function new() {}

  static public function get() {
    if (instance == null) instance = new Config();
    return instance;
  }

  public function setConfig(config:GameConfig) {
    if (config.title != null) title = config.title;
    if (config.width != null) width = config.width;
    if (config.height != null) height = config.height;
    if (config.zoom != null) zoom = config.zoom;
    if (config.resolution != null) resolution = config.resolution;
    if (config.scenes != null) scenes = config.scenes;
    if (config.fps != null) fps = config.fps;
    if (config.backgroundColor != null) background = config.backgroundColor;
    if (config.version != null) version = config.version;
  }
}