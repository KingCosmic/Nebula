package nebula.loader;

import nebula.scenes.Scene;
import nebula.structs.Set;

import nebula.loader.LOADER_CONST;

/**
 * The Loader handles loading all external content such as Images, Sounds, Texture Atlases and data files.
 * You typically interact with it via `this.load` in your Scene. Scenes can have a `preload` method, which is always
 * called before the Scenes `create` method, allowing you to preload assets that the Scene may need.
 *
 * If you call any `this.load` methods from outside of `Scene.preload` then you need to start the Loader going
 * yourself by calling `Loader.start()`. It's only automatically started during the Scene preload.
 *
 * Files are loaded in parallel by default. The amount of concurrent connections can be controlled in your Game Configuration.
 *
 * Once the Loader has started loading you are still able to add files to it. These can be injected as a result of a loader
 * event, the type of file being loaded (such as a pack file) or other external events. As long as the Loader hasn't finished
 * simply adding a new file to it, while running, will ensure it's added into the current queue.
 *
 * Every Scene has its own instance of the Loader and they are bound to the Scene in which they are created. However,
 * assets loaded by the Loader are placed into global game-level caches. For example, loading an Json file will place that
 * file inside `AssetManager.json`, which is accessible from every Scene in your game, no matter who was responsible
 * for loading it. The same is true of Textures. A texture loaded in one Scene is instantly available to all other Scenes
 * in your game.
 *
 * The Loader works by using custom File Types.
 * You can create your own custom file types by extending either the File or MultiFile classes.
 * See those files for more details.
 */
class Loader extends EventEmitter {
	/**
	 * The Scene which owns this Loader instance
	 */
	public var scene:Scene;

	/**
	 * An optional prefix that is automatically prepended to the start of every file key.
	 * If prefix was `MENU.` and you load an image with the key 'Background' the resulting key would be `MENU.Background`.
	 * You can set this directly, or call `Loader.setPrefix()`. It will then affect every file added to the Loader
	 * from that point on. It does _not_ change any file already in the load queue.
	 */
	public var prefix:String = '';

	/**
	 * The total number of files to load. It may not always be accurate because you may add to the Loader during the process
	 * of loading, especially if you load a Pack File. Therefore this value can change, but in most cases remains static.
	 */
	public var totalToLoad:Int = 0;

	/**
	 * The progress of the current load queue, as a float value between 0 and 1.
	 * This is updated automatically as files complete loading.
	 * Note that it is possible for this value to go down again if you add content to the current load queue during a load.
	 */
	public var progress:Float = 0;

	/**
	 * Files are placed in this Set when they're added to the Loader via `addFile`.
	 *
	 * They are moved to the `inflight` Set when they start loading, and assuming a successful
	 * load, to the `queue` Set for further processing.
	 *
	 * By the end of the load process this Set will be empty.
	 */
	public var list:Set<File<Any>> = new Set<File<Any>>();

	/**
	 * Files are stored in this Set while they're in the process of being loaded.
	 *
	 * Upon a successful load they are moved to the `queue` Set.
	 *
	 * By the end of the load process this Set will be empty.
	 */
	public var inflight:Set<File<Any>> = new Set<File<Any>>();

	/**
	 * Files are stored in this Set while they're being processed.
	 *
	 * If the process is successful they are moved to their final destination, which could be
	 * a Cache or the Texture Manager.
	 *
	 * At the end of the load process this Set will be empty.
	 */
	public var queue:Set<File<Any>> = new Set<File<Any>>();

	/**
	 * A temporary Set in which files are stored after processing,
	 * awaiting destruction at the end of the load process.
	 */
	public var _deleteQueue:Set<File<Any>> = new Set<File<Any>>();

	/**
	 * The total number of files that failed to load during the most recent load.
	 * This value is reset when you call `Loader.start`.
	 */
	public var totalFailed:Int = 0;

	/**
	 * The total number of files that successfully loaded during the most recent load.
	 * This value is reset when you call `Loader.start`.
	 */
	public var totalComplete:Int = 0;

	/**
	 * The current state of the Loader.
	 */
	public var state:Int = 0;

	public function new(_scene:Scene) {
		super();

		scene = _scene;

		scene.events.once('BOOT', boot);
		scene.events.on('START', pluginStart);
	}

	/**
	 * This method is called automatically, only once, when the Scene is first created.
	 * Do not invoke it directly.
	 */
	public function boot() {
		scene.events.once('DESTROY', destroy);
	}

	/**
	 * This method is called automatically by the Scene when it is starting up.
	 * It is responsible for creating local systems, properties and listening for Scene events.
	 * Do not invoke it directly.
	 */
	public function pluginStart() {
		scene.events.once('SHUTDOWN', shutdown);
	}

	/**
	 * An optional prefix that is automatically prepended to the start of every file key.
	 *
	 * If prefix was `MENU.` and you load an image with the key 'Background' the resulting key would be `MENU.Background`.
	 *
	 * Once a prefix is set it will then affect every file added to the Loader from that point on. It does _not_ change any
	 * file _already_ in the load queue. To reset it, call this method with no arguments.
	 */
	public function setPrefix(?_prefix:String = '') {
		prefix = _prefix;

		return this;
	}

	/**
	 * Adds a file, or array of files, into the load queue.
	 *
	 * The Loader will check that the key used by the file won't conflict with
   * any other key either in the loader, the inflight queue or the target cache.
	 * If allowed it will then add the file into the pending list, read for the load to start.
   * Or, if the load has already started, ready for the next batch of files to be
   * pulled from the list to the inflight queue.
	 *
	 * You should not normally call this method directly, but rather use one of
   * the Loader methods like `image` or `atlas`,
	 * however you can call this as long as the file given to it is well formed.
	 */
	public function addFile(files:Array<File<Any>>) {
    // loop through our files
		for (file in files) {
			// Does the file already exist in the cache or texture manager?
			// Or will it conflict with a file already in the queue or inflight?
			if (keyExists(file))
				continue;

      // if not lets add it.
			list.set(file);

      // emit our add event.
			emit('ADD', file.key, file.type, this, file);

      // if we're not loading continue
			if (!isLoading())
				continue;

      // if we are loading make sure to update the total
			totalToLoad++;
      
      // and update the current progress.
			updateProgress();
		}
	}

	/**
	 * Checks the key and type of the given file to see if it will conflict with anything already
	 * in a Cache, the Texture Manager, or the list or inflight queues.
	 */
	public function keyExists(file:File<Any>) {
		var keyConflict = file.hasCacheConflict();

		if (!keyConflict) {
			list.iterate((item, index) -> {
				if (item.type == file.type && item.key == file.key) {
					keyConflict = true;

					return false;
				}

				return true;
			});
		}

		if (!keyConflict && isLoading()) {
			inflight.iterate((item, index) -> {
				if (item.type == file.type && item.key == file.key) {
					keyConflict = true;

					return false;
				}

				return true;
			});

			queue.iterate((item, index) -> {
				if (item.type == file.type && item.key == file.key) {
					keyConflict = true;

					return false;
				}

				return true;
			});
		}

		return keyConflict;
	}

	/**
	 * Is the Loader actively loading, or processing loaded files?
	 */
	public function isLoading() {
		return (state == LOADER_CONST.LOADING || state == LOADER_CONST.PROCESSING);
	}

	/**
	 * Is the Loader ready to start a new load?
	 */
	public function isReady() {
		return (state == LOADER_CONST.IDLE || state == LOADER_CONST.COMPLETE);
	}

	/**
	 * Starts the Loader running. This will reset the progress and totals and then emit a `start` event.
	 * If there is nothing in the queue the Loader will immediately complete, otherwise it will start
	 * loading the first batch of files.
	 *
	 * The Loader is started automatically if the queue is populated within your Scenes `preload` method.
	 *
	 * However, outside of this, you need to call this method to start it.
	 *
	 * If the Loader is already running this method will simply return.
	 */
	public function start() {
		// If we're not ready just return.
		if (!isReady())
			return;

		// Reset our progress.
		progress = 0;

		// Aswell as internal stats.
		totalFailed = 0;
		totalComplete = 0;
		totalToLoad = list.size;

    // emit our start event.
		emit('START', this);

		// If there's no files to be loaded, just complete the load.
		if (list.size == 0) {
			loadComplete();
		} else {
			// Otherwise we update the state.
			state = LOADER_CONST.LOADING;

			// Reset the current inflight and queue list.
			inflight.clear();
			queue.clear();

			// Reset the progess.
			updateProgress();

			// Check the queue.
			checkLoadQueue();

			// Setup the update event.
			scene.events.on('UPDATE', update);
		}
	}

	/**
	 * Called automatically during the load process.
	 * It updates the `progress` value and then emits a progress event, which you can use to
	 * display a loading bar in your game.
	 */
	public function updateProgress() {
		progress = 1 - ((list.size + inflight.size) / totalToLoad);

		emit('PROGRESS', progress);
	}

	/**
	 * Called automatically during the load process.
	 */
	public function update() {
		if (state == LOADER_CONST.LOADING && list.size > 0) {
			checkLoadQueue();
		}
	}

	/**
	 * An internal method called by the Loader.
	 *
	 * It will check to see if there are any more files in the pending list that need loading, and if so it will move
	 * them from the list Set into the inflight Set, set their CORs flag and start them loading.
	 *
	 * It will carrying on doing this for each file in the pending list until it runs out, or hits the max allowed parallel downloads.
	 */
	public function checkLoadQueue() {
    final listArray = list.getArray();

    for (i in 0...listArray.length) {
      final file = listArray[i];

			if (file.state == LOADER_CONST.FILE_POPULATED || (file.state == LOADER_CONST.FILE_PENDING)) {
        trace('loading ' + file.key + '');
				inflight.set(file);

        for (i in 0...list.size) {
          
        }

				list.delete(file);

				file.load();
			}
    }
	}

	/**
	 * An internal method called automatically by the XHRLoader belong to a File.
	 *
	 * This method will remove the given file from the inflight Set and update the load progress.
	 * If the file was successful its `onProcess` method is called, otherwise it is added to the delete queue.
	 */
	public function nextFile(file:File<Any>, success:Bool) {
		//  Has the game been destroyed during load? If so, bail out now.
		if (inflight == null)
			return;

		inflight.delete(file);

		updateProgress();

		if (success) {
			totalComplete++;

			queue.set(file);

			emit('FILE_LOAD', file);

			file.onProcess();
		} else {
			totalFailed++;

			_deleteQueue.set(file);

			emit('FILE_LOAD_ERROR', file);

			fileProcessComplete(file);
		}
	}

	/**
	 * An internal method that is called automatically by the File when it has finished processing.
	 *
	 * If the process was successful, and the File isn't part of a MultiFile, its `addToCache` method is called.
	 *
	 * It this then removed from the queue. If there are no more files to load `loadComplete` is called.
	 */
	public function fileProcessComplete(file:File<Any>) {
		//  Has the game been destroyed during load? If so, bail out now.
		if (scene == null) {
			return;
		}

		// This file has failed, so move it to the failed Set
		if (file.state == LOADER_CONST.FILE_COMPLETE) {
			// If we got here, then the file processed, so let it add itself to its cache
			file.addToCache();
		}

		// Remove it from the queue
		queue.delete(file);

		// Nothing left to do?
		if (list.size == 0 && inflight.size == 0 && queue.size == 0) {
			loadComplete();
		}
	}

	/**
	 * Called at the end when the load queue is exhausted and all files have either loaded or errored.
	 * By this point every loaded file will now be in its associated cache and ready for use.
	 *
	 * Also clears down the Sets, puts progress to 1 and clears the deletion queue.
	 */
	public function loadComplete() {
		emit('POST_PROCESS', this);

		list.clear();
		inflight.clear();
		queue.clear();

		progress = 1;

		state = LOADER_CONST.COMPLETE;

		scene.events.removeListener('UPDATE', update);

		// Call 'destroy' on each file ready for deletion
		_deleteQueue.iterateLocal('destroy');

		_deleteQueue.clear();

		emit('COMPLETE', this, totalComplete, totalFailed);
	}

	/**
	 * Adds a File into the pending-deletion queue.
	 */
	public function flagForRemoval(file:Any) {
		_deleteQueue.set(file);
	}

	/**
	 * Resets the Loader.
	 *
	 * This will clear all lists and reset the base URL, path and prefix.
	 *
	 * Warning: If the Loader is currently downloading files, or has files in its queue, they will be aborted.
	 */
	public function reset() {
		list.clear();
		inflight.clear();
		queue.clear();

		setPrefix();

		state = LOADER_CONST.IDLE;
	}

	/**
	 * The Scene that owns this plugin is shutting down.
	 * We need to kill and reset all internal properties as well as stop listening to Scene events.
	 */
	public function shutdown() {
		reset();

		state = LOADER_CONST.SHUTDOWN;

		scene.events.removeListener('UPDATE', update);
		scene.events.removeListener('SHUTDOWN', shutdown);
	}

	/**
	 * The Scene that owns this plugin is being destroyed.
	 * We need to shutdown and then kill off all external references.
	 */
	public function destroy() {
		shutdown();

		state = LOADER_CONST.DESTROYED;

		scene.events.removeListener('START', pluginStart);

		list = null;
		inflight = null;
		queue = null;

		scene = null;
	}
}