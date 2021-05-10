package nebula.loader.filetypes;

import nebula.assets.AssetManager;

/**
 * A single Sprite Sheet Image File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#spritesheet method and are not typically created directly.
 * 
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#spritesheet.
 */
class SpriteSheetFile extends ImageFile {
	public function new(loader:Loader, key:String, url:String, frameConfig:{}) {
		super(loader, key, url, frameConfig);

		type = 'spritesheet';
	}

	override public function addToCache() {
		var texture = AssetManager.addSpriteSheet(key, data, config.config);

		pendingDestroy(texture);
	}
}