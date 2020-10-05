package game.scenes;

import core.input.Pointer;
import kha.math.Random;
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
      trace('ayy I was clicked');
    });
    
		sys.displayList.add([_startButton]);
		
		scene.start('Play');
	}

	override function update(time:Float, delta:Float) {}
}