package nebula.loader;

import nebula.assets.AssetManager;
import nebula.loader.Loader;

import nebula.loader.LOADER_CONST;

typedef FileConfig = {
	type:String,
	key:String,
	url:String,
	config:Dynamic
};

class File<FT> {
	/**
	 * A reference to the loader that is going to load this file.
	 */
	public var loader:Loader;

	/**
	 * The file type string (image, json, etc) for sorting within the Loader.
	 */
	public var type:String = '';

	/**
	 * A unique cache key (unique within it's file type)
	 */
	public var key:String = '';

	/**
	 * The final URL this file will load from, including baseURL and path.
	 * Set automatically when the Loader calls 'load' on this file.
	 */
	public var src:String = '';

	/**
	 * The current state of the file. One of the FILE_CONST values.
	 */
	public var state:Int = LOADER_CONST.FILE_PENDING;

	/**
	 * The processed file data, stored here after the file has loaded.
	 */
	public var data:FT;

	/**
	 * The config for this file.
	 */
	public var config:Dynamic;

	public function new(_loader:Loader, fileConfig:FileConfig) {
		loader = _loader;

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
	 * During the load the methods onLoad, onError and onProgress are called, based on the load events.
	 * You shouldn't normally call this method directly, it's meant to be invoked by the Loader.
	 */
	public function load() {
    state = LOADER_CONST.FILE_LOADING;

    startLoad();
	}

	/**
	 * here for other files to override.
	 */
  public function startLoad() {}

	/**
	 * Called when the file finishes loading.
	 */
	public function onLoad(_data:FT) {
		data = _data;

		loader.nextFile(cast this, true);
	}

	/**
	 * Called if the file errors while loading.
	 */
	public function onError(error:kha.AssetError) {
		trace(error.error);
		trace('errored');
		loader.nextFile(cast this, false);
	}

	/**
	 * Called during the file load progress.
	 */
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

		loader.fileProcessComplete(cast this);
	}

	/**
	 * Called when the File has completed processing but it generated an error.
	 * Checks on the state of its multifile, if set.
	 */
	public function onProcessError() {
		state = LOADER_CONST.FILE_ERRORED;

		loader.fileProcessComplete(cast this);
	}

	/**
	 * Checks if a key matching the one used by this file exists in the target Cache or not.
	 * This is called automatically by the LoaderPlugin to decide if the file can be safely
	 * loaded or will conflict.
	 */
	public function hasCacheConflict() {
		return (AssetManager.get().textureExists(key));
	}

	/**
	 * Adds this file to its target cache upon successful loading and processing.
	 * This method is often overridden by specific file types.
	 */
	public function addToCache() {}

	/**
	 * Called once the file has been added to its cache and is now ready for deletion from the Loader.
	 * It will emit a `filecomplete` event from the LoaderPlugin.
	 */
	public function pendingDestroy(?_data:Any) {
		if (_data == null)
			_data = data;

		loader.emit('FILE_COMPLETE', key, type, _data);
		loader.emit('FILE_KEY_COMPLETE' + type + '-' + key, key, type, data);

		loader.flagForRemoval(this);
	}

	/**
	 * Destroy this File and any references it holds
	 */
	public function destroy() {}
}