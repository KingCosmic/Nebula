package core.loader.filetypes;

/**
 * A single Sprite Sheet Image File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#spritesheet method and are not typically created directly.
 * 
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#spritesheet.
 */
class SpriteSheetFile extends ImageFile {
  public function new(loader:LoaderPlugin, key:String, url:String, frameConfig:{}) {
    super(loader, key, url, frameConfig);

    type = 'spritesheet';
  }

  override public function addToCache() {
    var texture = cache.addSpriteSheet(key, data, config);

    pendingDestroy(texture);
  }
}