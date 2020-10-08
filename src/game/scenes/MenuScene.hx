package game.scenes;

import core.gameobjects.Image;
import core.scene.Scene;

class MenuScene extends Scene {
	private var _startButton:Image;

	public function new() {
		super({
			key: 'Start',
			active: true,
			visible: true
		});
	}

	override function preload() {
		load.image('star', 'star');
	}

	override function create() {
    _startButton = new Image(this, 400, 300, 'star');
    _startButton.setInteractive();

    _startButton.on('GAMEOBJECT_POINTER_DOWN', () -> {
      scene.start('Play');
    });
    
		sys.displayList.add([_startButton]);
	}

	override function update(time:Float, delta:Float) {}
}