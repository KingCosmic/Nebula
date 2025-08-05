package nebula;

typedef TGarbageCollectionOptions = {
  /**
   * Textures that aren't drawn after a certain number of milliseconds are unloaded from the GPU
   * Default 60_000 ms
   */
  var textureCollectInterval: Null<Int>; // default 60_000 ms
  // TODO future work to integrate the font and text configuration, refactor existing collection mechanism
  // /**
  //  * Font pre-renders that aren't drawn after a certain number of milliseconds are unloaded from the GPU
  //  * Default 60_000 ms
  //  */
  // fontCollectInterval: number; // default 60_000 ms
  // /**
  //  * Text measurements that aren't used after a certain number of milliseconds are unloaded from the GPU
  //  * Default 60_000 ms
  //  */
  // textMeasurementCollectInterval: number; // default 60_000 ms

  /**
   * Returns a timestamp in milliseconds representing now
   */
  function getTimestamp(): Int;
}

var DefaultGarbageCollectionOptions: GarbageCollectionOptions = {
  textureCollectInterval: 60_000
  // TODO future work to integrate the font and text configuration, refactor existing collection mechanism
  // fontCollectInterval: 60_000,
  // textMeasurementCollectInterval: 60_000,
};

class GarbageCollector {
  private var _collectHandle: Int;
  private var _running = false;
  private var _collectionMap = new Map<Any, { type: String, time: Int }>();
  private var _collectors = new Map<String, { collect: (resource: Any) -> Bool, interval: Int }>();

  public function new (options: TGarbageCollectionOptions) {}

  /**
   *
   * @param type Resource type
   * @param timeoutInterval If resource type exceeds interval in milliseconds collect() is called
   * @param collect Collection implementation, returns true if collected
   */
  function registerCollector(type: String, timeoutInterval: Int, collect: (resource: Any) -> Bool) {
    this._collectors.set(type, { collect: collect, interval: timeoutInterval });
  }

  /**
   * Add a resource to be tracked for collection
   * @param type
   * @param resource
   */
  function addCollectableResource(type: String, resource: Any) {
    this._collectionMap.set(resource, { type: type, time: this.options.getTimestamp() });
  }

  /**
   * Update the resource last used timestamp preventing collection
   * @param resource
   */
  function touch(resource: Any) {
    final collectionData = this._collectionMap.get(resource);
    if (collectionData) {
      this._collectionMap.set(resource, [collectionData[0], this.options.getTimestamp()]);
    }
  }

  /**
   * Runs the collection loop to cleanup any stale resources given the registered collect handlers
   */
  public function collectStaleResources(?deadline: IdleDeadline) {
    if (!this._running) {
      return;
    }
    for (type => collector in this._collectors) {
      final collector = collector.collect;
      final timeoutInterval = collector.interval;

      final now = this.options.getTimestamp();
      for (resource => collection in this._collectionMap) {
        final time = collection.time;
        final resourceType = collection.type;
        if (type != resourceType || time + timeoutInterval >= now) {
          continue;
        }

        final collected = collector(resource);
        if (collected) {
          this._collectionMap.delete(resource);
        }
      }
    }

    this._collectHandle = requestIdleCallback(this.collectStaleResources);
  };

  /**
   * Force collect all resources, useful for shutting down a game
   * or if you know that you will not use anything you've allocated before now
   */
  public function forceCollectAll() {
    for (_ => coll in this._collectors) {
      final collector = coll.collect;
      for (resource => collection in this._collectionMap) {
        final collected = collector(resource);
        if (collected) {
          this._collectionMap.delete(resource);
        }
      }
    }
  }

  function running(): Bool {
    return this._running;
  }

  /**
   * Starts the garbage collection loop
   */
  function start() {
    this._running = true;
    this.collectStaleResources();
  }

  /**
   * Stops the garbage collection loop
   */
  function stop() {
    this._running = false;
    cancelIdleCallback(this._collectHandle);
  }
}
