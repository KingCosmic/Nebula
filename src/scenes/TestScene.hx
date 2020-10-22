package scenes;

import nebula.gameobjects.Image;
import nebula.scene.Scene;

class TestScene extends Scene {
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
    var helm = new Image(this, 400, 300, 'helmet');

    // cameras.main.startFollow(helm);

    sys.displayList.add([helm]);
  }
}