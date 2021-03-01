package scenes;

import nebula.gameobjects.Image;
import nebula.gameobjects.Text;
import nebula.scene.Scene;

class TestScene extends Scene {
  public var helm:Image;

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
    helm = new Image(this, 400, 300, 'helmet');

    var test = new Image(this, 400, 10, 'helmet');

		var text:Text = new Text(this, 10, 10, 'TEST', { fontSize: 40 }).setScrollFactor(0);

    helm.setScale(4);

    cameras.main.startFollow(helm);

    displayList.add([helm, text, test]);
  }

  override public function update(time:Float, delta:Float) {
    helm.x += 2;
  }
}