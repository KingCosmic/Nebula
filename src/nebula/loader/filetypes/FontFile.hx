package nebula.loader.filetypes;

import kha.Assets;
import kha.Font;

import nebula.loader.const.LOADER_CONST;

/**
 * A single Font File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#font method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#font.
 */
class FontFile extends File<Font> {
	public function new(loader:LoaderPlugin, key:String, url:String) {

		var fileConfig = {
			type: 'image',
			key: key,
			url: url,
			config: {}
		}

		super(loader, fileConfig);
	}

	override public function loadFile() {
		Assets.loadFont(src, onLoad, onError);
	}

	/**
	 * Adds this file to its target cache upon successful loading and processing.
	 */
	override public function addToCache() {
		var texture = cache.addFont(key, data);

		pendingDestroy(texture);
	}
}