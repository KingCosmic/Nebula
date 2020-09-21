package core.loader.const;

class LOADER_CONST {
  /**
   * The Loader is idle.
   */
  static public var IDLE = 0;

  /**
   * The Loader is actively loading.
   */
	static public var LOADING = 1;

  /**
   * The Loader is processing files is has loaded.
   */
	static public var PROCESSING = 2;

  /**
   * The Loader has completed loading and processing.
   */
	static public var COMPLETE = 3;

  /**
   * The Loader is shutting down.
   */
	static public var SHUTDOWN = 4;

  /**
   * The Loader has been destroyed.
   */
	static public var DESTROYED = 5;

  /**
   * File is in the load queue but not yet started
   */
	static public var FILE_PENDING = 10;

  /**
   * File has been started to load by the loader (onLoad called)
   */
	static public var FILE_LOADING = 11;

  /**
   * File has loaded successfully, awaiting processing
   */
	static public var FILE_LOADED = 12;

  /**
   * File failed to load
   */
	static public var FILE_FAILED = 13;

  /**
   * File is being processed (onProcess callback)
   */
	static public var FILE_PROCESSING = 14;

  /**
   * The File has errored somehow during processing.
   */
	static public var FILE_ERRORED = 16;

  /**
   * File has finished processing.
   */
	static public var FILE_COMPLETE = 17;

  /**
   * File has been destroyed
   */
	static public var FILE_DESTROYED = 18;

  /**
   * File was populated from local data and doesn't need an HTTP request
   */
	static public var FILE_POPULATED = 19;
}