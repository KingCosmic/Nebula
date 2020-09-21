package;

import core.Game;

import game.scenes.PlayScene;

class Main {
	public static function main() {
		new Game({
			title: 'Phaser 3 example',
			width: 800,
			height: 600,
			scene: [PlayScene],
			fps: {
				min: 30,
				target: 60,
				smoothStep: true
			}
		});
	}
}
