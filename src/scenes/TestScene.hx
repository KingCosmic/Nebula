package scenes;

import nebula.gameobjects.Image;
import nebula.gameobjects.Text;
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
		load.font('__DEFAULT', 'TomorrowNight');
  }

  override public function create() {
    var helm = new Image(this, 400, 300, 'helmet');

		var text = new Text(this, 10, 10, 'TEST', { fontSize: 40 });

    helm.setScale(4);

    cameras.main.startFollow(helm);

    displayList.add([helm, text]);
  }
}