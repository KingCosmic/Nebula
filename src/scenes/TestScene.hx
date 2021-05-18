package scenes;

import nebula.loader.filetypes.ImageFile;

// import nebula.input.gamepad.GamepadPlugin;
import nebula.input.keyboard.Keyboard;
import nebula.input.keyboard.Key;
import nebula.gameobjects.Image;
// import nebula.gameobjects.Text;
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
      active: false,
      visible: false,
      loader: true
    });
  }

  override public function preload() {
    ImageFile.loadFile(this, 'helmet', 'helmet');
		//load.font('__DEFAULT', 'TomorrowNight');
  }

  override public function create() {
    // WIP
    keyboard = new Keyboard(this);

    helm = new Image(this, 400, 300, 'helmet');

		// var text = new Text(this, 10, 10, 'TEST', { fontSize: 40 });

    // helm.setScale(4);

    // cameras.main.startFollow(helm);

    displayList.add([helm]);

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