package scenes;

import nebula.input.gamepad.GamepadPlugin;
import nebula.gameobjects.Image;
import nebula.gameobjects.Text;
import nebula.scene.Scene;

class TestScene extends Scene {
	public var gamepad:GamepadPlugin;

  public function new() {
    super({
      key: 'test',
      active: false,
      visible: false
    });
  }

  override public function preload() {
    load.image('helmet', 'helmet');
		load.font('__DEFAULT', 'TomorrowNight');
  }

  override public function create() {
    // WIP
    gamepad = new GamepadPlugin(this);

    var helm = new Image(this, 400, 300, 'helmet');

		var text = new Text(this, 10, 10, 'TEST', { fontSize: 40 });

    helm.setScale(4);

    cameras.main.startFollow(helm);

    sys.displayList.add([helm, text]);
  }
}