package game.scenes;

import core.input.keyboard.Key;
import core.input.Pointer;
import kha.math.Random;
import core.gameobjects.Image;

import core.scene.Scene;

class PlayScene extends Scene {
  private var _player:Image;

  private var _keys:{
    w:Key,
    a:Key,
    s:Key,
    d:Key
  };

  public function new() {
    super({
      key: 'Play',
      active: false,
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

    _keys = {
      w: input.keyboard.addKey('W'),
      a: input.keyboard.addKey('A'),
      s: input.keyboard.addKey('S'),
			d: input.keyboard.addKey('D')
    };

    cameras.main.startFollow(_player);
  }

  override function update(time:Float, delta:Float) {
    if (_keys.w.isDown) {
      _player.y -= 100 * delta;
		} else if (_keys.s.isDown) {
      _player.y += 100 * delta;
    }

		if (_keys.a.isDown) {
      _player.x -= 100 * delta;
		} else if (_keys.d.isDown) {
      _player.x += 100 * delta;
    }
  }
}