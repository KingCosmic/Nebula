package core.loader;

import kha.Assets;
import core.textures.TextureManager;
import core.loader.const.LOADER_CONST;
import core.loader.LoaderPlugin;

class File {
  // A reference to the loader that is going to load this file.
  public var loader:LoaderPlugin;

	// A reference to the Cache, or Texture Manager, that is going to store this file if it loads.
  public var cache:TextureManager;

  // The file type string (image, json, etc) for sorting within the Loader.
  public var type:String = '';

  // A unique cache key (unique within it's file type)
  public var key:String = '';

  /**
   * The final URL this file will load from, including baseURL and path.
   * Set automatically when the Loader calls 'load' on this file.
   */
  public var src:String = '';

  // The current state of the file. One of the FILE_CONST values.
  public var state:Int = LOADER_CONST.FILE_PENDING;

  // The processed file data, stored here after the file has loaded.
  public var data:kha.Image;

  public var config:Dynamic;

	public function new(_loader:LoaderPlugin, fileConfig:{
		type:String,
		cache:TextureManager,
		key:String,
    url:String,
    config:{}
	}) {
    loader = _loader;
    cache = fileConfig.cache;

    key = fileConfig.key;
    type = fileConfig.type;

    config = (fileConfig.config != null) ? fileConfig.config : {};

    if (loader.prefix != '') {
      key = loader.prefix + key;
    }

    src = fileConfig.url;

    if (type == '' || key == '') {
      trace('Invalid Loader.' + type + ' key');
    }
  }

  /**
   * Called by the Loader, starts the actual file downloading.
   * During the load the methods onLoad, onError and onProgress are called, based on the XHR events.
   * You shouldn't normally call this method directly, it's meant to be invoked by the Loader.
   */
  public function load() {
    if (state == LOADER_CONST.FILE_POPULATED) {
			// Can happen for example in a JSONFile if they've provided a JSON object instead of a URL
      loader.nextFile(this, true);
    } else {
      state = LOADER_CONST.FILE_LOADING;

      Assets.loadImage(src, onLoad, onError);
    }
  }

  // Called when the file finishes loading, is sent a DOM ProgressEvent.
  public function onLoad(_data:kha.Image) {
    data = _data;

    loader.nextFile(this, true);
  }

  // Called if the file errors while loading, is sent a DOM ProgressEvent.
  public function onError(error:kha.AssetError) {
    trace(error.error);
    trace('errored');
    loader.nextFile(this, false);
  }

  // Called during the file load progress.
  public function onProgress(event) {
    // TODO:
    loader.emit('FILE_PROGRESS', this);
  }

  /**
   * Usually overridden by the FileTypes and is called by Loader.nextFile.
   * This method controls what extra work this File does with its loaded data, for example a JSON file will parse itself during this stage.
   */
  public function onProcess() {
    state = LOADER_CONST.FILE_PROCESSING;

    onProcessComplete();
  }

  /**
   * Called when the File has completed processing.
   * Checks on the state of its multifile, if set.
   */
  public function onProcessComplete() {
    state = LOADER_CONST.FILE_COMPLETE;

    loader.fileProcessComplete(this);
  }

  /**
   * Called when the File has completed processing but it generated an error.
   * Checks on the state of its multifile, if set.
   */
  public function onProcessError() {
    state = LOADER_CONST.FILE_ERRORED;

    loader.fileProcessComplete(this);
  }

  /**
   * Checks if a key matching the one used by this file exists in the target Cache or not.
   * This is called automatically by the LoaderPlugin to decide if the file can be safely
   * loaded or will conflict.
   */
  public function hasCacheConflict() {
    return (cache != null && cache.exists(key));
  }

  /**
   * Adds this file to its target cache upon successful loading and processing.
   * This method is often overridden by specific file types.
   */
  public function addToCache() {
    if (cache != null) {
      // cache.add(key, data);
    }

    pendingDestroy();
  }

  /**
   * Called once the file has been added to its cache and is now ready for deletion from the Loader.
   * It will emit a `filecomplete` event from the LoaderPlugin.
   */
  public function pendingDestroy(?_data:Any) {
    if (_data == null) _data = data;

    loader.emit('FILE_COMPLETE', key, type, _data);
    loader.emit('FILE_KEY_COMPLETE' + type + '-' + key, key, type, data);

    loader.flagForRemoval(this);
  }

  // Destroy this File and any references it holds
  public function destroy() {}
}