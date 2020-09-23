package game.scenes;

import core.gameobjects.Image;

import core.scene.Scene;

class PlayScene extends Scene {
  private var _player:Image;

  public function new() {
    super({
      key: 'Play',
      active: true,
      visible: true
    });
  }

  override function preload() {
    load.image('sky', 'sky');
    load.image('star', 'star');
  }

	override function create() {
    sys.displayList.add([new Image(this, 400, 300, 'sky')]);

    _player = new Image(this, 600, 400, 'star');
    
    sys.displayList.add([_player]);

    cameras.main.startFollow(_player);
  }

  override function update(time:Float, delta:Float) {
    _player.x += 100 * delta;
  }
}