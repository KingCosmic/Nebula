package nebula.gameobjects.tilemap;

import nebula.cameras.Camera;
import nebula.Renderer;
import nebula.gameobjects.tilemap.Tilemap;
import nebula.gameobjects.tilemap.Tilemap.OgmoLayer;

class Layer {
  public var active:Bool = true;

  public var data:OgmoLayer;

  public var tiles:Array<Image> = [];

  public function new(tilemap:Tilemap, layerdata:OgmoLayer) {
    data = layerdata;

    // loop through the tiles and create the images
    for (tileData in data.data) {
      // create the image
      // add it to the tiles array
      var tile = new Image(scene, tileData.x, tileData.y, data.tileset, tileData);
    }
  }

  public function render(renderer:Renderer, camera:Camera) {

  }
}