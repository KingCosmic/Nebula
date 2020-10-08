package game.scenes;

import core.input.keyboard.Key;
import core.input.Pointer;
import kha.math.Random;
import core.gameobjects.Image;
import core.gameobjects.Sprite;

import core.scene.Scene;

class PlayScene extends Scene {
  private var _player:Sprite;
  private var _star:Image;

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
    load.spritesheet('dude', 'dude', { frameWidth: 32, frameHeight: 48 });
  }

	override function create() {
    sys.displayList.add([new Image(this, 400, 300, 'sky')]);

    _star = new Image(this, 450, 300, 'star');
    _star.setScale(2);
    _star.setAlpha(0.5);

    sys.displayList.add([_star]);

    _player = new Sprite(this, 600, 400, 'dude');
    
    sys.displayList.add([_player]);
    sys.updateList.add(_player);

		// Our player animations, turning, walking left and walking right.
		anims.create({
			key: 'left',
      frames: anims.generateFrameNumbers('dude', { start: 0, end: 3 }),
			skipMissedFrames: false,
			frameRate: 10,
			repeat: -1
		});

		anims.create({
			key: 'turn',
      frames: anims.generateFrameNumbers('dude', { start: 4, end: 5 }),
			skipMissedFrames: false,
			frameRate: 20
		});

		anims.create({
			key: 'right',
      frames: anims.generateFrameNumbers('dude', { start: 5, end: 8 }),
			skipMissedFrames: false,
			frameRate: 10,
			repeat: -1
		});

    _keys = {
      w: input.keyboard.addKey('W'),
      a: input.keyboard.addKey('A'),
      s: input.keyboard.addKey('S'),
			d: input.keyboard.addKey('D')
    };

    cameras.main.startFollow(_player);
  }

  override function update(time:Float, delta:Float) {
    _star.rotation += 0.1;

    if (_keys.w.isDown) {
      _player.y -= 100 * delta;
		} else if (_keys.s.isDown) {
      _player.y += 100 * delta;
    }

		if (_keys.a.isDown) {
      _player.x -= 100 * delta;
			_player.anims.play('left', true);
		} else if (_keys.d.isDown) {
      _player.x += 100 * delta;
			_player.anims.play('right', true);
    } else {
			_player.anims.play('turn');
    }
  }
}