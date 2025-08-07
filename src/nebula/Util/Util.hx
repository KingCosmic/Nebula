package nebula.util;

import nebula.math.Vector;
import nebula.util.Clock;
import nebula.util.Future;

class Util {
  /**
   *
   */
  public static function getMinIndex(array: Array<Int>): Int {
    if (array.length == 0) {
      throw new Error('Cannot find minIndex of array.length == 0');
    }

    var min = array[0];
    var minIndex = 0;

    for (i in 1...array.length) {
      if (array[i] < min) {
        min = array[i];
        minIndex = i;
      }
    }
    return minIndex;
  }

  /**
   * Find the screen position of an HTML element
   */
  public static function getPosition(el: HTMLElement): Vector {
    // do we need the scroll too? technically the offset method before did that
    if (el && el.getBoundingClientRect) {
      final rect = el.getBoundingClientRect();
      return vec(rect.x + window.scrollX, rect.y + window.scrollY);
    }
    return Vector.Zero;
  }

  /**
   * Add an item to an array list if it doesn't already exist. Returns true if added, false if not and already exists in the array.
   * @deprecated Will be removed in v0.26.0
   */
  public static function addItemToArray<T>(item: T, array: Array<T>): Bool {
    if (array.indexOf(item) == -1) {
      array.push(item);
      return true;
    }
    return false;
  }

  /**
   * Remove an item from an list
   * @deprecated Will be removed in v0.26.0
   */
  public static function removeItemFromArray<T>(item: T, array: Array<T>): Bool {
    var index = -1;
    if ((index = array.indexOf(item)) > -1) {
      array.splice(index, 1);
      return true;
    }

    return false;
  }

  /**
   * See if an array contains something
   */
  public static function contains<T>(array: Array<T>, obj: T): Bool {
    for (i in 0...array.length) {
      if (array[i] == obj) {
        return true;
      }
    }
    return false;
  }

  /**
   * Used for exhaustive checks at compile time
   */
  public static function fail(message: String): Void {
    throw new Error(message);
  }

  /**
   * Create a promise that resolves after a certain number of milliseconds
   *
   * It is strongly recommended you pass the excalibur clock so delays are bound to the
   * excalibur clock which would be unaffected by stop/pause.
   * @param milliseconds
   * @param clock
   */
  public static function delay(milliseconds: Int, ?clock: Clock): Promise<Void> {
    final future = new Future<Void>();
    final schedule = clock?.schedule.bind(clock) ?? setTimeout;
    schedule(() -> {
      future.resolve();
    }, milliseconds);
    return future.promise;
  }

  /**
   * Remove keys from object literals
   * @param object
   * @param keys
   */
  public static function omit(object: Dynamic, keys: Array<Keys>) {
    final newObj: Omit<TObject, Keys> = {};
    for (key in object) {
      if (!keys.includes(key)) {
        newObj[key] = object[key];
      }
    }
    return newObj;
  }

  /**
   * Simple object check.
   * @param item
   */
  static function isPlainObject(value:Dynamic): Bool {
    return value != null && !Std.isOfType(value, Array) && Reflect.isObject(value);
  }

  // Merge two objects deeply
  public static function mergeDeep<T:{ }>(target:T, sources:Array<T>): T {
    if (sources.length == 0) return target;

    final source = sources.shift();

    if (isPlainObject(target) && isPlainObject(source)) {
      for (key in Reflect.fields(source)) {
        final sourceVal = Reflect.field(source, key);
        final targetVal = Reflect.field(target, key);

        if (isPlainObject(sourceVal)) {
          if (targetVal == null) {
            Reflect.setField(target, key, {});
          }
          mergeDeep(cast Reflect.field(target, key), [cast sourceVal]);
        } else {
          Reflect.setField(target, key, sourceVal);
        }
      }
    }

    return mergeDeep(target, sources);
  }
}