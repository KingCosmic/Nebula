package nebula.loader.filetypes;

import nebula.assets.AssetManager;

import kha.Assets;
import kha.Image;

/**
 * A single Image File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#image method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#image.
 */
class ImageFile extends File<Image> {
	public function new(loader:Loader, key:String, url:String, ?frameConfig:{}) {
		if (frameConfig == null)
			frameConfig = {};

		var fileConfig = {
			type: 'image',
			key: key,
			url: url,
			config: frameConfig
		}

		super(loader, fileConfig);
	}

	override public function loadFile() {
		Assets.loadImage(src, onLoad, onError);
	}

	/**
	 * Adds this file to its target cache upon successful loading and processing.
	 */
	override public function addToCache() {
		var texture = AssetManager.addImage(key, data);

		pendingDestroy(texture);
	}
}