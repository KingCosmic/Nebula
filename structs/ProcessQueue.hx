package core.structs;

/**
 * A Process Queue maintains three internal lists.
 *
 * The `pending` list is a selection of items which are due to be made 'active' in the next update.
 * The `active` list is a selection of items which are considered active and should be updated.
 * The `destroy` list is a selection of items that were active and are awaiting being destroyed in the next update.
 *
 * When new items are added to a Process Queue they are put in the pending list, rather than being added
 * immediately the active list. Equally, items that are removed are put into the destroy list, rather than
 * being destroyed immediately. This allows the Process Queue to carefully process each item at a specific, fixed
 * time, rather than at the time of the request from the API.
 */
class ProcessQueue<T> extends EventEmitter {
  // The `pending` list is a selection of items which are due to be made 'active' in the next update.
  public var _pending:Array<T> = [];

  // The `active` list is a selection of items which are considered active and should be updated.
  public var _active:Array<T> = [];

  // The `destroy` list is a selection of items that were active and are awaiting being destroyed in the next update.
  public var _destroy:Array<T> = [];

  // The total number of items awaiting processing.
  public var _toProcess:Int = 0;

  // If `true` only unique objects will be allowed in the queue.
  public var checkQueue:Bool = false;

  public function new() {
    super();
  }

  /**
   * Adds a new item to the Process Queue.
   *
   * The item is added to the pending list and made active in the next update.
   */
  public function add(item:T) {
    _pending.push(item);

    _toProcess++;

    return item;
  }

  /**
   * Removes an item from the Process Queue.
   *
   * The item is added to the pending destroy and fully removed in the next update.
   */
  public function remove(item:T) {
    _destroy.push(item);

    _toProcess++;

    return item;
  }

  /**
   * Removes all active items from this Process Queue.
   *
   * All the items are marked as 'pending destroy' and fully removed in the next update.
   */
  public function removeAll() {
    var index = _active.length - 1;

    while (index >= 0) {
      _destroy.push(_active[index]);

      _toProcess++;
      index--;
    }

    return this;
  }

  /**
   * Update this queue. First it will process any items awaiting destruction, and remove them.
   *
   * Then it will check to see if there are any items pending insertion, and move them to an
   * active state. Finally, it will return a list of active items for further processing.
   */
  public function update() {
    // Quick bail
    if (_toProcess == 0) return _active;

    for (item in _destroy) {
      // Remove from the active array.
      var idx = _active.indexOf(item);

      if (idx == -1) continue;

      _active.splice(idx, 1);

      emit('PROCESS_QUEUE_REMOVE', item);
    }

    _destroy = [];

    // Process the pending addition list
    // This stops callbacks and out of sync events from populating the active array mid-way during an update
    for (item in _pending) {
      
			if (checkQueue == false || (checkQueue && _active.indexOf(item) == -1)) {
        _active.push(item);

        emit('PROCESS_QUEUE_ADD', item);
      }
    }

    _pending = [];
    _toProcess = 0;

    // The owner of this queue can now safely do whatever it needs to with the active list
    return _active;
  }

  /**
   * Returns the current list of active items.
   *
   * This method returns a reference to the active list array, not a copy of it.
   * Therefore, be careful to not modify this array outside of the ProcessQueue.
   */
  public function getActive() {
    return _active;
  }

  // The number of entries in the active list
  public function getLength() {
    return _active.length;
  }

  // Immediately destroys this process queue, clearing all of its internal arrays and resetting the process totals.
  public function destroy() {
    _toProcess = 0;

    _pending = [];
    _active = [];
    _destroy = [];
  }
}