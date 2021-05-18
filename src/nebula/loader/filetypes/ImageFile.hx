package nebula.loader.filetypes;

import nebula.assets.AssetManager;
import nebula.scenes.Scene;

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

	/**
	 * Adds an Image, or array of Images, to the current load queue.
	 *
	 * You can call this method from within your Scene's `preload`, along with any other files you wish to load:
	 *
	 * ```javascript
	 * function preload () {
	 *   ImageFile.loadFile('logo', 'images/phaserLogo.png');
	 * }
	 * ```
	 */
	static public function loadFile(scene:Scene, key:String, url:String) {
		scene.load.addFile([cast new ImageFile(scene.load, key, url)]);
	}

	override public function startLoad() {
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