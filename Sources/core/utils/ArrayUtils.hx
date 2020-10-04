package core.utils;

class ArrayUtils {
  /**
   * Adds the given item, or array of items, to the array.
   *
   * Each item must be unique within the array.
   *
   * The array is modified in-place and returned.
   *
   * You can optionally specify a limit to the maximum size of the array. If the quantity of items being
   * added will take the array length over this limit, it will stop adding once the limit is reached.
   *
   * You can optionally specify a callback to be invoked for each item successfully added to the array.
   */
  static public function add<T>(array:Array<T>, items:Array<T>, ?limit = 0, ?callback:T->Void):Null<Array<T>> {
    
    var remaning = limit - array.length;

    if (limit > 0 && remaning <= 0) {
      // There's nothing more we can do here, the array is full.
      return null;
    }

		//  If we got this far, we have an array of items to insert

    //  Ensure all the items are unique
    var itemLength = items.length - 1;

    while (itemLength >= 0) {
      if (array.indexOf(items[itemLength]) != -1) {
        // Already exists in the array, so remove it.
        items.splice(itemLength, 1);
      }

      itemLength--;
    }

    // Anything left?
    itemLength = items.length;

    if (itemLength == 0) return null;

    if (limit > 0 && itemLength > remaning) {
      items.splice(0, remaning);
    }

    for (entry in items) {
      array.push(entry);

      if (callback != null) callback(entry);
    }

    return items;
  }

  /**
   * Adds the given item, or array of items, to the array starting at the index specified.
   * 
   * Each item must be unique within the array.
   * 
   * Existing elements in the array are shifted up.
   * 
   * The array is modified in-place and returned.
   * 
   * You can optionally specify a limit to the maximum size of the array. If the quantity of items being
   * added will take the array length over this limit, it will stop adding once the limit is reached.
   * 
   * You can optionally specify a callback to be invoked for each item successfully added to the array.
   */
  static public function addAt<T>(array:Array<T>, items:Array<T>, ?index:Int = 0, ?limit:Int = 0, ?callback:T->Void):Null<Array<T>> {
    var remaining = limit - array.length;

    if (limit > 0 && remaining <= 0) {
      return null;
    }

		//  If we got this far, we have an array of items to insert

		//  Ensure all the items are unique
    var itemLength = items.length - 1;
    
    while (itemLength >= 0) {
      if (array.indexOf(items[itemLength]) != -1) {
        items.pop();
      }

      itemLength--;
    }

    // Anything left?
    itemLength = items.length;

    if (itemLength == 0) return null;

    // Truncate to the limit
    if (limit > 0 && itemLength > remaining) {
      items.splice(0, remaining);
    }

    // rip our array where the index is
    var first = array.splice(0, index);
    
    // add the new items in
    first.concat(items);

    // add our other half back on
    first.concat(array);

    // just for the callback
    if (callback != null) {
			for (entry in items) {
        callback(entry);
			}
    }

    return items;
  }

  /**
 * Removes the given item, or array of items, from the array.
 * 
 * The array is modified in-place.
 * 
 * You can optionally specify a callback to be invoked for each item successfully removed from the array.
 */
	static public function remove<T>(array:Array<T>, items:Array<T>, ?callback:T->Void) {
		var itemLength = items.length - 1;

		while (itemLength >= 0) {
			var entry = items[itemLength];

			var index = array.indexOf(entry);

			if (index != -1) {
        array.splice(index, 1);

				if (callback != null) {
					callback(entry);
				}
			} else {
				// Item wasn't found in the array, so remove it from our return results
				items.pop();
			}

			itemLength--;
		}

		return items;
  }

  /**
   * Searches a pre-sorted array for the closet value to the given number.
   *
   * If the `key` argument is given it will assume the array contains objects that all have the required `key` property name,
   * and will check for the closest value of those to the given number.
   */
  static public function findClosestInSortedFromKey<T>(value:Float, array:Array<T>, ?key:String) {
    if (array.length == 0) return null;

    if (array.length == 1) return array[0];

    var i = 1;
    var low:Float = null;
    var high:Float = null;

    if (value < Reflect.getProperty(array[0], key)) return array[0];

    while (Reflect.getProperty(array[i], key) < value) {
      i++;
    }

    if (i > array.length) i = array.length;

    low = Reflect.getProperty(array[i - 1], key);
    high = Reflect.getProperty(array[i], key);

    return ((high - value) <= (value - low)) ? array[i] : array[i - 1];
  }

	static public function findClosestInSorted(value:Float, array:Array<Float>) {
		if (array.length == 0)
			return null;

		if (array.length == 1)
			return array[0];

		var i = 1;
		var low:Float = null;
		var high:Float = null;

		while (array[i] < value) {
			i++;
		}

		low = array[i - 1];
		high = array[i];

		return ((high - value) <= (value - low)) ? high : low;
  }
}