package core.loader;

import core.loader.filetypes.SpriteSheetFile;
import core.textures.TextureManager;
import core.loader.filetypes.ImageFile;
import core.scene.SceneManager;
import core.scene.Systems;
import core.scene.Scene;
import core.structs.Set;

import core.loader.const.LOADER_CONST;

/**
 * The Loader handles loading all external content such as Images, Sounds, Texture Atlases and data files.
 * You typically interact with it via `this.load` in your Scene. Scenes can have a `preload` method, which is always
 * called before the Scenes `create` method, allowing you to preload assets that the Scene may need.
 *
 * If you call any `this.load` methods from outside of `Scene.preload` then you need to start the Loader going
 * yourself by calling `Loader.start()`. It's only automatically started during the Scene preload.
 *
 * The Loader uses a combination of tag loading (eg. Audio elements) and XHR and provides progress and completion events.
 * Files are loaded in parallel by default. The amount of concurrent connections can be controlled in your Game Configuration.
 *
 * Once the Loader has started loading you are still able to add files to it. These can be injected as a result of a loader
 * event, the type of file being loaded (such as a pack file) or other external events. As long as the Loader hasn't finished
 * simply adding a new file to it, while running, will ensure it's added into the current queue.
 *
 * Every Scene has its own instance of the Loader and they are bound to the Scene in which they are created. However,
 * assets loaded by the Loader are placed into global game-level caches. For example, loading an XML file will place that
 * file inside `Game.cache.xml`, which is accessible from every Scene in your game, no matter who was responsible
 * for loading it. The same is true of Textures. A texture loaded in one Scene is instantly available to all other Scenes
 * in your game.
 *
 * The Loader works by using custom File Types. These are stored in the FileTypesManager, which injects them into the Loader
 * when it's instantiated. You can create your own custom file types by extending either the File or MultiFile classes.
 * See those files for more details.
 */
class LoaderPlugin extends EventEmitter {
  // The Scene which owns this Loader instance
  public var scene:Scene;

  // A reference to the Scene Systems.
  public var systems:Systems;

  // A reference to the global Cache Manager.
  public var cacheManager:Any;

  // A reference to the global Texture Manager.
  public var textureManager:TextureManager;

  // A reference to the global Scene Manager.
  public var sceneManager:SceneManager;

  /**
   * An optional prefix that is automatically prepended to the start of every file key.
   * If prefix was `MENU.` and you load an image with the key 'Background' the resulting key would be `MENU.Background`.
   * You can set this directly, or call `Loader.setPrefix()`. It will then affect every file added to the Loader
   * from that point on. It does _not_ change any file already in the load queue.
   */
  public var prefix:String = '';

  /**
   * The value of `path`, if set, is placed before any _relative_ file path given. For example:
   *
   * ```haxe
   * this.load.path = "images/sprites/";
   * this.load.image("ball", "ball.png");
   * this.load.image("tree", "level1/oaktree.png");
   * this.load.image("boom", "http://server.com/explode.png");
   * ```
   *
   * Would load the `ball` file from `images/sprites/ball.png` and the tree from
   * `images/sprites/level1/oaktree.png` but the file `boom` would load from the URL
   * given as it's an absolute URL.
   *
   * Please note that the path is added before the filename but *after* the baseURL (if set.)
   *
   * If you set this property directly then it _must_ end with a "/". Alternatively, call `setPath()` and it'll do it for you.
   */
  public var path:String = '';

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
  public var list:Set<File> = new Set<File>();

  /**
   * Files are stored in this Set while they're in the process of being loaded.
   *
   * Upon a successful load they are moved to the `queue` Set.
   *
   * By the end of the load process this Set will be empty.
   */
	public var inflight:Set<File> = new Set<File>();

  /**
   * Files are stored in this Set while they're being processed.
   *
   * If the process is successful they are moved to their final destination, which could be
   * a Cache or the Texture Manager.
   *
   * At the end of the load process this Set will be empty.
   */
	public var queue:Set<File> = new Set<File>();

  /**
   * A temporary Set in which files are stored after processing,
   * awaiting destruction at the end of the load process.
   */
	public var _deleteQueue:Set<File> = new Set<File>();

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

  // The current state of the Loader.
  public var state:Int = 0;

  // The current index being used by multi-file loaders to avoid key clashes.
  public var multiKeyIndex:Int = 0;

  public function new(_scene:Scene) {
    super();

    scene = _scene;
    systems = scene.sys;
    // cacheManager = scene.sys.cache;
    textureManager = scene.sys.textures;
    sceneManager = scene.sys.scenePlugin;

    systems.events.once('BOOT', boot);
		systems.events.on('START', pluginStart);
  }

	/**
  * Adds an Image, or array of Images, to the current load queue.
  *
  * You can call this method from within your Scene's `preload`, along with any other files you wish to load:
  *
  * ```javascript
  * function preload ()
  * {
  *     this.load.image('logo', 'images/phaserLogo.png');
  * }
  * ```
  *
  * The file is **not** loaded right away. It is added to a queue ready to be loaded either when the loader starts,
  * or if it's already running, when the next free load slot becomes available. This happens automatically if you
  * are calling this from within the Scene's `preload` method, or a related callback. Because the file is queued
  * it means you cannot use the file immediately after calling this method, but must wait for the file to complete.
  * The typical flow for a Phaser Scene is that you load assets in the Scene's `preload` method and then when the
  * Scene's `create` method is called you are guaranteed that all of those assets are ready for use and have been
  * loaded.
  *
  * Phaser can load all common image types: png, jpg, gif and any other format the browser can natively handle.
  * If you try to load an animated gif only the first frame will be rendered. Browsers do not natively support playback
  * of animated gifs to Canvas elements.
  *
  * The key must be a unique String. It is used to add the file to the global Texture Manager upon a successful load.
  * The key should be unique both in terms of files being loaded and files already present in the Texture Manager.
  * Loading a file using a key that is already taken will result in a warning. If you wish to replace an existing file
  * then remove it from the Texture Manager first, before loading a new one.
  *
  * Instead of passing arguments you can pass a configuration object, such as:
  *
  * ```javascript
  * this.load.image({
  *     key: 'logo',
  *     url: 'images/AtariLogo.png'
  * });
  * ```
  *
  * See the documentation for `Phaser.Types.Loader.FileTypes.ImageFileConfig` for more details.
  *
  * Once the file has finished loading you can use it as a texture for a Game Object by referencing its key:
  *
  * ```javascript
  * this.load.image('logo', 'images/AtariLogo.png');
  * // and later in your game ...
  * this.add.image(x, y, 'logo');
  * ```
  *
  * If you have specified a prefix in the loader, via `Loader.setPrefix` then this value will be prepended to this files
  * key. For example, if the prefix was `MENU.` and the key was `Background` the final key will be `MENU.Background` and
  * this is what you would use to retrieve the image from the Texture Manager.
  *
  * The URL can be relative or absolute. If the URL is relative the `Loader.baseURL` and `Loader.path` values will be prepended to it.
  *
  * If the URL isn't specified the Loader will take the key and create a filename from that. For example if the key is "alien"
  * and no URL is given then the Loader will set the URL to be "alien.png". It will always add `.png` as the extension, although
  * this can be overridden if using an object instead of method arguments. If you do not desire this action then provide a URL.
  *
  * Phaser also supports the automatic loading of associated normal maps. If you have a normal map to go with this image,
  * then you can specify it by providing an array as the `url` where the second element is the normal map:
  *
  * ```javascript
  * this.load.image('logo', [ 'images/AtariLogo.png', 'images/AtariLogo-n.png' ]);
  * ```
  *
  * Or, if you are using a config object use the `normalMap` property:
  *
  * ```javascript
  * this.load.image({
  *     key: 'logo',
  *     url: 'images/AtariLogo.png',
  *     normalMap: 'images/AtariLogo-n.png'
  * });
  * ```
  *
  * The normal map file is subject to the same conditions as the image file with regard to the path, baseURL, CORs and XHR Settings.
  * Normal maps are a WebGL only feature.
  *
  * Note: The ability to load this type of file will only be available if the Image File type has been built into Phaser.
  * It is available in the default build but can be excluded from custom builds.
  */
  public function image(key:String, url:String) {
    addFile([new ImageFile(this, key, url)]);

    return this;
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
		* You can call this method from within your Scene's `preload`, along with any other files you wish to load:
		*
		* ```javascript
		* function preload ()
		* {
		*     this.load.spritesheet('bot', 'images/robot.png', { frameWidth: 32, frameHeight: 38 });
		* }
		* ```
		*
		* The file is **not** loaded right away. It is added to a queue ready to be loaded either when the loader starts,
		* or if it's already running, when the next free load slot becomes available. This happens automatically if you
		* are calling this from within the Scene's `preload` method, or a related callback. Because the file is queued
		* it means you cannot use the file immediately after calling this method, but must wait for the file to complete.
		* The typical flow for a Phaser Scene is that you load assets in the Scene's `preload` method and then when the
		* Scene's `create` method is called you are guaranteed that all of those assets are ready for use and have been
		* loaded.
		*
		* Phaser can load all common image types: png, jpg, gif and any other format the browser can natively handle.
		* If you try to load an animated gif only the first frame will be rendered. Browsers do not natively support playback
		* of animated gifs to Canvas elements.
		*
		* The key must be a unique String. It is used to add the file to the global Texture Manager upon a successful load.
		* The key should be unique both in terms of files being loaded and files already present in the Texture Manager.
		* Loading a file using a key that is already taken will result in a warning. If you wish to replace an existing file
		* then remove it from the Texture Manager first, before loading a new one.
		*
		* Instead of passing arguments you can pass a configuration object, such as:
		*
		* ```javascript
		* this.load.spritesheet({
		*     key: 'bot',
		*     url: 'images/robot.png',
		*     frameConfig: {
		*         frameWidth: 32,
		*         frameHeight: 38,
		*         startFrame: 0,
		*         endFrame: 8
		*     }
		* });
		* ```
		*
		* See the documentation for `Phaser.Types.Loader.FileTypes.SpriteSheetFileConfig` for more details.
		*
		* Once the file has finished loading you can use it as a texture for a Game Object by referencing its key:
		*
		* ```javascript
		* this.load.spritesheet('bot', 'images/robot.png', { frameWidth: 32, frameHeight: 38 });
		* // and later in your game ...
		* this.add.image(x, y, 'bot', 0);
		* ```
		*
		* If you have specified a prefix in the loader, via `Loader.setPrefix` then this value will be prepended to this files
		* key. For example, if the prefix was `PLAYER.` and the key was `Running` the final key will be `PLAYER.Running` and
		* this is what you would use to retrieve the image from the Texture Manager.
		*
		* The URL can be relative or absolute. If the URL is relative the `Loader.baseURL` and `Loader.path` values will be prepended to it.
		*
		* If the URL isn't specified the Loader will take the key and create a filename from that. For example if the key is "alien"
		* and no URL is given then the Loader will set the URL to be "alien.png". It will always add `.png` as the extension, although
		* this can be overridden if using an object instead of method arguments. If you do not desire this action then provide a URL.
		*
		* Phaser also supports the automatic loading of associated normal maps. If you have a normal map to go with this image,
		* then you can specify it by providing an array as the `url` where the second element is the normal map:
		*
		* ```javascript
		* this.load.spritesheet('logo', [ 'images/AtariLogo.png', 'images/AtariLogo-n.png' ], { frameWidth: 256, frameHeight: 80 });
		* ```
		*
		* Or, if you are using a config object use the `normalMap` property:
		*
		* ```javascript
		* this.load.spritesheet({
		*     key: 'logo',
		*     url: 'images/AtariLogo.png',
		*     normalMap: 'images/AtariLogo-n.png',
		*     frameConfig: {
		*         frameWidth: 256,
		*         frameHeight: 80
		*     }
		* });
		* ```
		*
		* The normal map file is subject to the same conditions as the image file with regard to the path, baseURL, CORs and XHR Settings.
		* Normal maps are a WebGL only feature.
		*
		* Note: The ability to load this type of file will only be available if the Sprite Sheet File type has been built into Phaser.
		* It is available in the default build but can be excluded from custom builds.
    */
  public function spritesheet(key:String, url:String, frameConfig:{}) {
    addFile([new SpriteSheetFile(this, key, url, frameConfig)]);

    return this;
  }

  /**
   * This method is called automatically, only once, when the Scene is first created.
   * Do not invoke it directly.
   */
  public function boot() {
    systems.events.once('DESTROY', destroy);
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function pluginStart() {
    systems.events.once('SHUTDOWN', shutdown);
  }

  /**
   * The value of `path`, if set, is placed before any _relative_ file path given. For example:
   *
   * ```haxe
   * this.load.setPath("images/sprites/");
   * this.load.image("ball", "ball.png");
   * this.load.image("tree", "level1/oaktree.png");
   * this.load.image("boom", "http://server.com/explode.png");
   * ```
   *
   * Would load the `ball` file from `images/sprites/ball.png` and the tree from
   * `images/sprites/level1/oaktree.png` but the file `boom` would load from the URL
   * given as it's an absolute URL.
   *
   * Please note that the path is added before the filename but *after* the baseURL (if set.)
   *
   * Once a path is set it will then affect every file added to the Loader from that point on. It does _not_ change any
   * file _already_ in the load queue. To reset it, call this method with no arguments.
   */
  public function setPath(?_path:String = '') {
    if (_path != '' && _path.substr(-1) == '/') {
      _path = _path + '/';
    }

    path = _path;

    return this;
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
   * The file must be an instance of `Phaser.Loader.File`, or a class that extends it. The Loader will check that the key
   * used by the file won't conflict with any other key either in the loader, the inflight queue or the target cache.
   * If allowed it will then add the file into the pending list, read for the load to start. Or, if the load has already
   * started, ready for the next batch of files to be pulled from the list to the inflight queue.
   *
   * You should not normally call this method directly, but rather use one of the Loader methods like `image` or `atlas`,
   * however you can call this as long as the file given to it is well formed.
   */
  public function addFile(files:Array<File>) {
    for (file in files) {
			// Does the file already exist in the cache or texture manager?
      // Or will it conflict with a file already in the queue or inflight?
      if (keyExists(file)) continue;

      list.set(file);

			emit('ADD', file.key, file.type, this, file);

      if (!isLoading()) continue;

      totalToLoad++;
      updateProgress();
    }
  }

  /**
   * Checks the key and type of the given file to see if it will conflict with anything already
   * in a Cache, the Texture Manager, or the list or inflight queues.
   */
  public function keyExists(file:File) {
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
    if (!isReady()) return;

    progress = 0;

    totalFailed = 0;
    totalComplete = 0;
    totalToLoad = list.size;

    emit('START', this);

    if (list.size == 0) {
      loadComplete();
    } else {
      state = LOADER_CONST.LOADING;
      
      inflight.clear();
      queue.clear();

      updateProgress();

      checkLoadQueue();

      systems.events.on('UPDATE', update);
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
    list.each((file, index) -> {
			if (file.state == LOADER_CONST.FILE_POPULATED || (file.state == LOADER_CONST.FILE_PENDING)) {
				inflight.set(file);

				list.delete(file);

				file.load();
			}

			return false;
    });
  }

  /**
   * An internal method called automatically by the XHRLoader belong to a File.
   *
   * This method will remove the given file from the inflight Set and update the load progress.
   * If the file was successful its `onProcess` method is called, otherwise it is added to the delete queue.
   */
  public function nextFile(file:File, success:Bool) {
		//  Has the game been destroyed during load? If so, bail out now.
    if (inflight == null) return;

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
  public function fileProcessComplete(file:File) {
		//  Has the game been destroyed during load? If so, bail out now.
		if (scene == null || systems == null || systems.game == null || systems.game.pendingDestroy) {
			return;
    }

		//  This file has failed, so move it to the failed Set
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

    systems.events.removeListener('UPDATE', update);

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

    setPath();
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

    systems.events.removeListener('UPDATE', update);
    systems.events.removeListener('SHUTDOWN', shutdown);
  }

  /**
   * The Scene that owns this plugin is being destroyed.
   * We need to shutdown and then kill off all external references.
   */
  public function destroy() {
    shutdown();

    state = LOADER_CONST.DESTROYED;

		systems.events.removeListener('START', pluginStart);

    list = null;
    inflight = null;
    queue = null;

    scene = null;
    systems = null;
    textureManager = null;
    cacheManager = null;
    sceneManager = null;
  }
}