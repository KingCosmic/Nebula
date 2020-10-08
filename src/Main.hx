package;

import game.scenes.MenuScene;
import game.scenes.PlayScene;
import core.Game;

class Main {
	public static function main() {
		new Game({
			title: 'Phaser 3 example',
			width: 800,
			height: 600,
			scene: [MenuScene, PlayScene],
			fps: {
				min: 30,
				target: 60,
				smoothStep: true
			}
		});
	}
}
