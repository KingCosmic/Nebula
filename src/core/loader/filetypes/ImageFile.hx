package core.loader.filetypes;

import core.loader.const.LOADER_CONST;

/**
 * A single Image File suitable for loading by the Loader.
 *
 * These are created when you use the Phaser.Loader.LoaderPlugin#image method and are not typically created directly.
 *
 * For documentation about what all the arguments and configuration options mean please see Phaser.Loader.LoaderPlugin#image.
 */
class ImageFile extends File {
  public function new(loader:LoaderPlugin, key:String, url:String, ?frameConfig:{}) {
    if (frameConfig == null) frameConfig = {};
  
    var fileConfig = {
      type: 'image',
      cache: loader.textureManager,
      key: key,
      url: url,
      config: frameConfig
    }

		super(loader, fileConfig);
  }

  /**
   * Adds this file to its target cache upon successful loading and processing.
   */
  override public function addToCache() {
    var texture = cache.addImage(key, data);

    pendingDestroy(texture);
  }
}