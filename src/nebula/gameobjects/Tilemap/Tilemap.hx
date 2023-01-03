package nebula.gameobjects.tilemap;

import nebula.cameras.Camera;
import nebula.scenes.Scene;

typedef OgmoLayer = {
  name: String,
  _eid: String,
  offsetX: Int,
  offsetY: Int,
  gridCellWidth: Int,
  gridCellHeight: Int,
  gridCellsX: Int,
  gridCellsY: Int,
  tileset: String,
  data: Array<Int>,
  exportMode: Int,
  arrayMode: Int
}

typedef OgmoData = {
  ogmoVersion: String,
  width: Int,
  height: Int,
  offsetX: Int,
  offsetY: Int,
  layers: Array<OgmoLayer>,
}

class Tilemap extends GameObject {

  public var version:String;
  public var layers:Array<Layer>;
  public var tilesets:Array<String>;
  public var objects:Array<String>;

  public function new(_s:Scene, mapData:OgmoData) {
    super(_s, 'tilemap');

    width = mapData.width;
    height = mapData.height;

    version = mapData.ogmoVersion;
  
    tilesets = [];
    objects = [];
  
    for (layer in mapData.layers) {
      tilesets.push(layer.tileset);
    }
  }

  override public function render(renderer:Renderer, camera:Camera) {
		for (layer in layers) {
      layer.render(renderer, camera);
    }
	}
}