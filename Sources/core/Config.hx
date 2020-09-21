package core;

import core.Game.GameConfig;

// TODO: Finish this.

class Config {
  public var width:Int;
  public var height:Int;

  public var zoom:Float;
  public var resolution:Float;

  public var scaleMode:Int = 0;

  public function new(config:GameConfig) {
    if (config.width == null) config.width = 1024;
    if (config.height == null) config.height = 768;
    if (config.zoom == null) config.zoom = 1;
    if (config.resolution == null) config.resolution = 1;

    width = config.width;
    height = config.height;
    zoom = config.zoom;
    resolution = config.resolution;
  }
}