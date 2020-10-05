package core.structs;

/**
 * A Set is a collection of unique elements.
 */
class Set<T> {
  // The entries of this Set. Stored internally as an array.
  public var entries:Array<T> = [];

  public function new(?elements:Array<T>) {
    if (elements == null) elements = [];
    // add our elements
    for (element in elements) {
      set(element);
    }
  }

  /**
   * Inserts the provided value into this Set. If the value is already contained in this Set this method will have no effect.
   */
  public function set(value:T) {
    if (entries.indexOf(value) == -1) {
      entries.push(value);
    }

    return this;
  }

  /**
   * Get an element of this Set which has a property of the specified name, if that property is equal to the specified value.
   * If no elements of this Set satisfy the condition then this method will return `null`.
   */
  public function get(property:String, value:Any):Null<T> {
    for (entry in entries) {
      if (Reflect.getProperty(entry, property) == value) {
        return entry;
      }
    }

    return null;
  }

  /**
   * Returns an array containing all the values of this Set.
   */
  public function getArray() {
    return entries.slice(0);
  }

  /**
   * Removes the given value from this Set if this Set contains that value.
   */
  public function delete(value:T) {
    var index = entries.indexOf(value);

    if (index > -1) {
      entries.splice(index, 1);
    }

    return this;
  }

  /**
   * Passes each value in this Set to the given callback.
   * Use this function when you know this Set will be modified during the iteration, otherwise use `iterate`.
   */
  public function each(callback:T->Int->Bool) {
    var temp = entries.slice(0);
    
    for (i in 0...temp.length) {
      if (callback(temp[i], i) == false) {
        break;
      }
    }

    return this;
  }

  /**
   * Passes each value in this Set to the given callback.
   * For when you absolutely know this Set won't be modified during the iteration.
   */
  public function iterate(callback:T->Int->Bool) {
    for (i in 0...entries.length) {
      if (callback(entries[i], i) == false) {
        break;
      }
    }

    return this;
  }

  /**
   * Goes through each entry in this Set and invokes the given function on them, passing in the arguments.
   */
  public function iterateLocal(callbackKey:String, ?arg1:Any, ?arg2:Any, ?arg3:Any, ?arg4:Any, ?arg5:Any) {
    for (entry in entries) {
			var prop = Reflect.getProperty(entry, callbackKey);
      if (Reflect.isFunction(prop)) {
        prop(arg1, arg2, arg3, arg4, arg5);
      }
    }

    return this;
  }

  /**
   * Clears this Set so that it no longer contains any values.
   */
  public function clear() {
    entries = [];

    return this;
  }

  /**
   * Returns `true` if this Set contains the given value, otherwise returns `false`.
   */
  public function contains(value:T) {
    return (entries.indexOf(value) > -1);
  }

  /**
   * Returns a new Set containing all values that are either in this Set or in the Set provided as an argument.
   */
  public function union(set:Set<T>) {
    var newSet = new Set<T>();

    set.iterate((value, index) -> {
      newSet.set(value);

      return true;
    });

    iterate((value, index) -> {
      newSet.set(value);

      return true;
    });

    return newSet;
  }

  /**
   * Returns a new Set that contains only the values which are in this Set and that are also in the given Set.
   */
  public function intersect(set:Set<T>) {
    var newSet = new Set<T>();

    iterate((value, index) -> {
      if (set.contains(value)) {
        newSet.set(value);
      }

      return true;
    });

    return newSet;
  }

  /**
   * Returns a new Set containing all the values in this Set which are *not* also in the given Set.
   */
  public function difference(set:Set<T>) {
    var newSet = new Set<T>();

    iterate((value, index) -> {
      if (!set.contains(value)) {
        newSet.set(value);
      }

      return true;
    });

    return newSet;
  }

  /**
   * The size of this Set. This is the number of entries within it.
   * Changing the size will truncate the Set if the given value is smaller than the current size.
   * Increasing the size larger than the current size has no effect.
   */
  public var size(get, set):Int;

  function get_size() {
    return entries.length;
  }

  function set_size(value:Int) {
    if (value < entries.length) {
      entries = entries.slice(value);
      return entries.length;
    } else {
      return entries.length;
    }
  }
}