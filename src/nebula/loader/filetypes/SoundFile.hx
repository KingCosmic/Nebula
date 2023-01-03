package nebula.loader.filetypes;

import nebula.assets.AssetManager;
import nebula.scenes.Scene;

import kha.Assets;
import kha.Blob;

/**
 * A single Font File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#font method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#font.
 */
class SoundFile extends File<Blob> {
	public function new(loader:Loader, key:String, url:String) {
		var fileConfig = {
			type: 'sound',
			key: key,
			url: url,
			config: {}
		}

		super(loader, fileConfig);
	}

	/**
	 * Adds a Font to the current load queue.
	 */
	static public function loadFile(scene:Scene, key:String, url:String) {
		scene.load.addFile([cast new SoundFile(scene.load, key, url)]);
	}

	override public function startLoad() {
		Assets.loadBlob(src, onLoad, onError);
	}

	/**
	 * Adds this file to its target cache upon successful loading and processing.
	 */
	override public function addToCache() {
		var texture = AssetManager.addJson(key, data);

		pendingDestroy(texture);
	}
}