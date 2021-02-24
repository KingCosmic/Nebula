package;

import scenes.TestScene;
import nebula.Game;

class Main {
	public static function main() {
		new Game({
			title: 'Nebula Test',
			width: 800,
			height: 600,
			scenes: [TestScene]
		});
	}
}
