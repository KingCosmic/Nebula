package nebula.loader.filetypes;

import nebula.assets.AssetManager;
import nebula.scenes.Scene;

import kha.Assets;
import kha.Image;

/**
 * A single Sprite Sheet Image File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#spritesheet method and are not typically created directly.
 * 
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#spritesheet.
 */
class SpriteSheetFile extends File<Image> {
	public function new(loader:Loader, key:String, url:String, frameConfig:{}) {
    if (frameConfig == null)
			frameConfig = {};

		var fileConfig = {
			type: 'spritesheet',
			key: key,
			url: url,
			config: frameConfig
		}

		super(loader, fileConfig);
	}

	/**
	 * Adds a Sprite Sheet Image, or array of Sprite Sheet Images, to the current load queue.
	 *
	 * The term 'Sprite Sheet' in Phaser means a fixed-size sheet. Where every frame in the sheet is the exact same size,
	 * and you reference those frames using numbers, not frame names. This is not the same thing as a Texture Atlas, where
	 * the frames are packed in a way where they take up the least amount of space, and are referenced by their names,
	 * not numbers. Some articles and software use the term 'Sprite Sheet' to mean Texture Atlas, so please be aware of
	 * what sort of file you're actually trying to load.
	 *
	 * You can call this method from within your Scene's `preload`, along with any other files you wish to load.
	 */
	static public function loadFile(scene:Scene, key:String, url:String, frameConfig:{}) {
		scene.load.addFile([cast new SpriteSheetFile(scene.load, key, url, frameConfig)]);
	}

  override public function startLoad() {
		Assets.loadImage(src, onLoad, onError);
	}

	override public function addToCache() {
		var texture = AssetManager.get().addSpriteSheet(key, data, config);

		pendingDestroy(texture);
	}
}