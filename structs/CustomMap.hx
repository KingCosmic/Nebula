package core.structs;

class CustomMap<T> {
  // The entries in this map.
	public var entries:Map<String, T> = new Map();
  public var size = 0;

	public function new(?elements:Array<{ key:String, item:T }>) {
    if (elements == null) elements = [];

    for (element in elements) {
      this.set(element.key, element.item);
    }
  }

  // Adds an element with a specified `key` and `value` to this Map.
  // If the `key` already exists, the value will be replaced.
	public function set(key:String, value:T) {
    if (!this.has(key)) {
      this.size = this.size + 1;
    }

    this.entries.set(key, value);

    return this;
  }

  // Returns the value associated to the `key`, or `undefined` if there is none.
  public function get(key:String) {
    if (this.has(key)) {
      return this.entries[key];
    }

    return null;
  }

  // Returns an `Array` of all the values stored in this Map.
  public function getArray():Array<T> {
    var output: Array<T> = [];

    for (entry in entries) {
      output.push(entry);
    }

    return output;
  }

  // Returns a bolean indicating whether an element to test for presence of in this Map.
  public function has(key:String) {
    return this.entries.exists(key);
  }

  // Delete the specified element from this Map.
  public function delete(key:String) {
    if (this.has(key)) {
      this.entries[key] = null;
      this.size = this.size - 1;
    }

    return this;
  }

  // Delete all entries from this Map.
  public function clear() {
    this.entries.clear();
    this.size = 0;

    return this;
  }

  // Returns all entry keys in this Map.
  public function keys():Array<String> {
    var output = [];

    for (k => v in entries) {
      output.push(k);
    }

    return output;
  }

  // Returns an `Array` of all entries
  public function values():Array<T> {
    var output = [];

    for (value in entries) {
      output.push(value);
    }

    return output;
  }

  // Passes all entries in this Map to the given callback.
  public function each(callback:T->Bool) {
    for (entry in entries) {
      if (callback(entry) == false) {
        break;
      }
    }

    return this;
  }

  // Returns `true` if the value exists within this Map. Otherwise, returns `false`.
  public function contains(value:T) {
    for (entry in entries) {
      if (entry == value) {
        return true;
      }
    }

    return false;
  }

  // Merges all new keys from the given Map into this one.
  // If it encounters a key that already exists it will be skipped unless override is set to `true`.
  public function merge(map:CustomMap<T>, force: Bool) {
    for (k => value in map.entries) {
      if (this.has(k) && force == true) {
        this.set(k, value);
      } else {
        this.set(k, value);
      }
    }

    return this;
  }
}