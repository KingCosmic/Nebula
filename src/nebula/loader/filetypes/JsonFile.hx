package nebula.loader.filetypes;

import nebula.assets.AssetManager;

import kha.Assets;
import kha.Blob;

/**
 * A single Font File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#font method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#font.
 */
class JsonFile extends File<Blob> {
	public function new(loader:Loader, key:String, url:String) {
		var fileConfig = {
			type: 'json',
			key: key,
			url: url,
			config: {}
		}

		super(loader, fileConfig);
	}

	override public function loadFile() {
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