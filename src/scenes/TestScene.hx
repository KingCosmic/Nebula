package scenes;

import haxe.Json;
import nebula.gameobjects.tilemap.Tilemap;
import nebula.loader.filetypes.SpriteSheetFile;
// import nape.shape.Polygon;
// import nebula.physics.nape.NapePhysics;
import nebula.assets.AssetManager;
import nebula.loader.filetypes.JsonFile;
import nebula.gameobjects.Text;
import nebula.loader.filetypes.FontFile;
import nebula.loader.filetypes.ImageFile;

import nebula.input.keyboard.Keyboard;
import nebula.input.keyboard.Key;
import nebula.gameobjects.Image;
import nebula.scenes.Scene;

class TestScene extends Scene {
  private var keyboard:Keyboard;

  // private var physics:NapePhysics;

  private var helm:Image;

	private var keys:{
		w:Key,
		a:Key,
		s:Key,
		d:Key
	};

  public function new() { 
    super({
      key: 'test',
      active: true,
      visible: true,
      loader: true
    });
  }

  override public function preload() {
    ImageFile.loadFile(this, 'helmet', 'helmet');
    FontFile.loadFile(this, '__DEFAULT', 'TomorrowNight');
    JsonFile.loadFile(this, 'mapdata', 'level.json');
    SpriteSheetFile.loadFile(this, 'enviroment', 'tileset', { 
      frameWidth: 16,
      frameHeight: 16
    });
  }

  override public function create() {
    trace('creating bro');
    // initiate our keyboard plugin so we can use keyboard input in this scene.
    keyboard = new Keyboard(this);

    cameras.main.setZoom(3);

    // initiate our physics plugin so we can use physics in this scene.
    // physics = new NapePhysics(this);

    helm = new Image(this, 400, 300, 'helmet');
    
    var mapData:Any = haxe.Json.parse(AssetManager.get().getJson('mapdata').toString());

    var tilemap = new Tilemap(this, 0, 0, mapData);

		var text = new Text(this, 10, 10, 'TEST', { fontSize: 40 }).setScrollFactor(0, 0);

    // physics.addGameobject(helm, {
    //   type: 'dynamic',
    //   shape: new Polygon(Polygon.box(helm.width, helm.height))
    // });

    cameras.main.startFollow(helm);

    displayList.add([tilemap]);
    displayList.add([helm, text]);

		keys = {
			w: keyboard.addKey('W'),
			a: keyboard.addKey('A'),
			s: keyboard.addKey('S'),
			d: keyboard.addKey('D')
		};
  }

  override function update(time:Float, delta:Float) {
		if (keys.w.isDown) {
			helm.y -= 100 * delta;
		} else if (keys.s.isDown) {
			helm.y += 100 * delta;
		}

		if (keys.a.isDown) {
			helm.x -= 100 * delta;
		} else if (keys.d.isDown) {
			helm.x += 100 * delta;
		}
  }
}