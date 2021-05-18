package nebula.loader.filetypes;

import nebula.assets.AssetManager;
import nebula.scenes.Scene;

import kha.Assets;
import kha.Font;

/**
 * A single Font File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#font method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#font.
 */
class FontFile extends File<Font> {
	public function new(loader:Loader, key:String, url:String) {
		var fileConfig = {
			type: 'font',
			key: key,
			url: url,
			config: {}
		}

		super(loader, fileConfig);
	}

	/**
	 * Adds a Font to the current load queue.
	 *
	 * You can call this method from within your Scene's `preload`, along with any other files you wish to load:
	 *
	 * ```javascript
	 * function preload () {
	 *   this.load.font('fontname', 'fontname');
	 * }
	 * ```
	 */
	static public function loadFile(scene:Scene, key:String, url:String) {
		scene.load.addFile([cast new FontFile(scene.load, key, url)]);
	}

	override public function startLoad() { 
		Assets.loadFont(src, onLoad, onError);
	}

	/**
	 * Adds this file to its target cache upon successful loading and processing.
	 */
	override public function addToCache() {
		var texture = AssetManager.addFont(key, data);

		pendingDestroy(texture);
	}
}