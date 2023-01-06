package nebula.gameobjects.tilemap;

import nebula.assets.AssetManager;
import nebula.assets.Texture;
import nebula.geom.Rectangle;
import kha.math.Vector2;
import nebula.cameras.Camera;
import nebula.Renderer;
import nebula.gameobjects.tilemap.Tilemap;
import nebula.gameobjects.tilemap.Tilemap.OgmoLayer;

class Layer extends GameObject {
  public var data:OgmoLayer;

  public var tiles:Array<Image> = [];

  public var tilesDrawn:Int = 0;
  public var tilesTotal:Float = 0;
	public var skipCull:Bool = true;

  public var tileset:Texture;

  public var tilemap:Tilemap;

  public function new(_tilemap:Tilemap, layerdata:OgmoLayer) {
    super(_tilemap.scene, 'layer');
    data = layerdata;

    originX = 0;
    originY = 0;

    tilemap = _tilemap;

    tileset = AssetManager.get().getTexture(data.tileset);

    width = data.gridCellsX * data.gridCellWidth;
    height = data.gridCellsY * data.gridCellHeight;

    // loop through the tiles and create the images
    for (tileData in data.data) {
      // create the image
      // add it to the tiles array
      // var tile = new Image(scene, tileData.x, tileData.y, data.tileset, tileData);
    }

    for (y in 0...data.gridCellsY) {
      for (x in 0...data.gridCellsX) {
        var tile = getTileData(x, y);

        if (tile == -1) {
          continue;
        }

        final frame = tileset.frames.get(Std.string(tile));

        if (frame == null) continue;

        var pos = new Vector2(x * data.gridCellWidth, y * data.gridCellHeight);

        tiles.push(new Image(scene, pos.x, pos.y, data.tileset, Std.string(tile)).setOrigin(0, 0));
      }
    }
  }

  public function getTileData(row:Int, col:Int) {
    // returns the tile at the specified row and col
    return data.data[col * data.gridCellsX + row];
  }

  public function cull(camera:Camera) {
    var outputArray = [];
    var renderOrder = 0;
    
    var mapTiles = data.data;
    var mapWidth = data.gridCellsX;
    var mapHeight = data.gridCellsY;

    var bounds = new Rectangle();

    if (skipCull || scrollFactorX != 1 || scrollFactorY != 1)
    {
      bounds.x = 0;
      bounds.width = mapWidth;
      bounds.y = 0;
      bounds.height = mapHeight;
    }

    var drawLeft = Std.int(Math.max(0, bounds.x));
    var drawRight = Std.int(Math.min(mapWidth, bounds.width));
    var drawTop = Std.int(Math.max(0, bounds.y));
    var drawBottom = Std.int(Math.min(mapHeight, bounds.height));

    var tile;

    if (renderOrder == 0)
    {
      //  right-down

      for (y in drawTop...drawBottom)
      {
        for (x in drawLeft...drawRight)
        {
          tile = getTileData(x, y);

          if (tile == -1)
          {
            continue;
          }

          outputArray.push(tile);
        }
      }
    }

    tilesDrawn = outputArray.length;
    tilesTotal = mapWidth * mapHeight;

    return outputArray;
  }

  override public function render(renderer:Renderer, camera:Camera) {
    for (tile in tiles) {
      tile.render(renderer, camera);
    }
  }

  // override public function render(renderer:Renderer, camera:Camera) {
  //   var renderTiles = cull(camera);

  //   var tileCount = renderTiles.length;
  //   var calcAlpha = camera.alpha * alpha;

  //   if (tileCount == 0 || calcAlpha <= 0) return;

  //   var calcX = tilemap.x - (originX * width);
  //   var calcY = tilemap.y - (originY * height);

  //   // grab our framebuffer to draw to.
  //   final g = renderer.framebuffer.g2;

  //   // calculate the camera position relative to this gameobject.
  //   var cameraPos = new Vector2(scrollFactorX * camera.scrollX, scrollFactorY * camera.scrollY);

  //   // rotate our graphics by the object rotation centered on our objects position.
  //   g.rotate(rotation, calcX - cameraPos.x, calcY - cameraPos.y);

  //   // set our alpha.
  //   g.pushOpacity(calcAlpha);

  //   for (y in 0...data.gridCellsY) {
  //     for (x in 0...data.gridCellsX) {
  //       var tile = getTileData(x, y);

  //       if (tile == -1) {
  //         continue;
  //       }

  //       final frame = tileset.frames.get(Std.string(tile));

  //       if (frame == null) continue;

  //       var pos = new Vector2(x * data.gridCellWidth, y * data.gridCellHeight);

  //       g.drawScaledSubImage(
  //         frame.texture.source,
  //         frame.cutX, frame.cutY,
  //         frame.cutWidth, frame.cutHeight,
  //         calcX + (pos.x - cameraPos.x), calcY + (pos.y - cameraPos.y),
  //         frame.cutWidth, frame.cutHeight
  //       );
  //     }
  //   }

  //   // reset our rotation.
  //   g.rotate(-rotation, calcX - cameraPos.x, calcY - cameraPos.y);

  //   // reset our alpha.
  //   g.popOpacity();
  // }
}