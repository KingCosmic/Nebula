package nebula.util;

import nebula.util.Log;

class Pool<Type> {
  public var totalAllocations = 0;
  public var index = 0;
  public var objects: Array<Type> = [];
  public var disableWarnings = false;
  private var _logger = Logger.getInstance();

  public function new(
    builder: () -> Type,
    ?recycler: (instance: Type) -> Type,
    maxObjects: Int = 100
  ) {}

  function dispose() {
    this.objects = [];
  }

  function preallocate() {
    for (i in 0...this.maxObjects) {
      this.objects[i] = this.builder();
    }
  }

  /**
   * Use many instances out of the in the context and return all to the pool.
   *
   * By returning values out of the context they will be un-hooked from the pool and are free to be passed to consumers
   * @param context
   */
  function use(context: (pool: Pool<Type>) -> Null<Array<Type>>) {
    final result = context(this);
    if (result) {
      return this.done(...result);
    }
    return this.done();
  }

  /**
   * Use a single instance out of th pool and immediately return it to the pool
   * @param context
   */
  function borrow(context: (object: Type) -> Void) {
    final object = this.get();
    context(object);
    this.index--;
  }

  /**
   * Retrieve a value from the pool, will allocate a new instance if necessary or recycle from the pool
   */
  function get(): Type {
    if (this.index == this.maxObjects) {
      if (!this.disableWarnings) {
        this._logger.warn('Max pooled objects reached, possible memory leak? Doubling');
      }
      this.maxObjects = this.maxObjects * 2;
    }

    if (this.objects[this.index]) {
      // Pool has an available object already constructed
      if (this.recycler) {
        return this.recycler(this.objects[this.index++]);
      }
      return this.objects[this.index++];
    } else {
      // New allocation
      this.totalAllocations++;
      final object = (this.objects[this.index++] = this.builder());
      return object;
    }
  }

  /**
   * Signals we are done with the pool objects for now, Reclaims all objects in the pool.
   *
   * If a list of pooled objects is passed to done they are un-hooked from the pool and are free
   * to be passed to consumers
   * @param objects A list of object to separate from the pool
   */
  function done(...objects: Array<Type>): Null<Array<Type>> {
    // All objects in pool now considered "free"
    this.index = 0;
    for (object in objects) {
      final poolIndex = this.objects.indexOf(object);
      // Build a new object to take the pool place
      this.objects[poolIndex] = this.builder();
      this.totalAllocations++;
    }
    return objects;
  }
}
