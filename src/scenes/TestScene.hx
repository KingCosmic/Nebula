package scenes;

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
    JsonFile.loadFile(this, 'mapdata', 'map.ldtk');
  }

  override public function create() {
    trace('creating bro');
    // WIP
    keyboard = new Keyboard(this);

    helm = new Image(this, 400, 300, 'helmet');

		var text = new Text(this, 10, 10, 'TEST', { fontSize: 40 });

    helm.setScale(4);

    // cameras.main.startFollow(helm);

    displayList.add([helm, text]);

    trace(AssetManager.get().json.get('mapdata'));

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