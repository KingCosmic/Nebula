package scenes;

import nebula.gameobjects.Image;
import nebula.scene.Scene;
import nebula.input.gamepad.GamepadPlugin;

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
  }

  override public function create() {
    gamepad = new GamepadPlugin(this);

    var helm = new Image(this, 400, 300, 'helmet');

    helm.setScale(4);

    cameras.main.startFollow(helm);

    sys.displayList.add([helm]);
  }
}