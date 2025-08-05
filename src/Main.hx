package;

// import samples.TestScene;
import nebula.Engine;

class Main {
	public static function main() {
    final game = new Engine({
      width: 400,
      height: 500,
      backgroundColor: ex.Color.fromHex("#54C0CA"),
      pixelArt: true,
      pixelRatio: 2,
      displayMode: ex.DisplayMode.FitScreen
    });

    game.start();
	}
}
