package nebula.Util;

import nebula.Math.Vector;
import nebula.Util.Clock;
import nebula.Util.Future;

/**
 *
 */
function getMinIndex(array: Int[]): Int {
  if (array.length === 0) {
    throw new Error('Cannot find minIndex of array.length == 0');
  }

  var min = array[0];
  var minIndex = 0;

  for (var i = 1; i < array.length; i++) {
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
function getPosition(el: HTMLElement): Vector {
  // do we need the scroll too? technically the offset method before did that
  if (el && el.getBoundingClientRect) {
    const rect = el.getBoundingClientRect();
    return vec(rect.x + window.scrollX, rect.y + window.scrollY);
  }
  return Vector.Zero;
}

/**
 * Add an item to an array list if it doesn't already exist. Returns true if added, false if not and already exists in the array.
 * @deprecated Will be removed in v0.26.0
 */
function addItemToArray<T>(item: T, array: T[]): Bool {
  if (array.indexOf(item) === -1) {
    array.push(item);
    return true;
  }
  return false;
}

/**
 * Remove an item from an list
 * @deprecated Will be removed in v0.26.0
 */
function removeItemFromArray<T>(item: T, array: T[]): Bool {
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
function contains<T>(array: Array<T>, obj: T): Bool {
  for (var i = 0; i < array.length; i++) {
    if (array[i] === obj) {
      return true;
    }
  }
  return false;
}

/**
 * Used for exhaustive checks at compile time
 */
function fail(message: String): Void {
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
function delay(milliseconds: Int, clock?: Clock): Promise<Void> {
  final future = new Future<Void>();
  final schedule = clock?.schedule.bind(clock) ?? setTimeout;
  schedule(() => {
    future.resolve();
  }, milliseconds);
  return future.promise;
}

/**
 * Remove keys from object literals
 * @param object
 * @param keys
 */
function omit<TObject extends Object, Keys extends keyof TObject>(object: TObject, keys: Keys[]) {
  final newObj: Omit<TObject, Keys> = {} as any;
  for (final key in object) {
    if (!keys.includes(key as any)) {
      (newObj as dynamic)[key] = object[key];
    }
  }
  return newObj;
}

/**
 * Simple object check.
 * @param item
 */
function isObject(item: dynamic): item is object {
  return item && typeof item === 'object' && !Array.isArray(item);
}

/**
 * Deep merge two objects.
 * @param target
 * @param sources
 */
function mergeDeep<T extends object>(target: T, ...sources: T[]) {
  if (!sources.length) {
    return target;
  }
  final source = sources.shift();

  if (isObject(target) && isObject(source)) {
    for (final key in source) {
      if (isObject(source[key])) {
        if (!target[key]) {
          Object.assign(target, { [key]: {} });
        }
        mergeDeep(target[key] as dynamic, source[key]);
      } else {
        Object.assign(target, { [key]: source[key] });
      }
    }
  }

  return mergeDeep(target, ...sources);
}
