package nebula.util;

import nebula.util.Future;

class AsyncWaitQueue<T> {
  // Code from StephenCleary https://gist.github.com/StephenCleary/ba50b2da419c03b9cba1d20cb4654d5e
  private var _queue: Array<Future<T>> = [];

  public var length(get, never): Int;
  function get_length(): Int {
    return this._queue.length;
  }

  public function enqueue(): Promise<T> {
    final future = new Future<T>();
    this._queue.push(future);
    return future.promise;
  }

  public function dequeue(value: T): Void {
    final future = this._queue.shift();
    future.resolve(value);
  }
}

/**
 * Semaphore allows you to limit the amount of async calls happening between `enter()` and `exit()`
 *
 * This can be useful when limiting the number of http calls, browser api calls, etc either for performance or to work
 * around browser limitations like max Image.decode() calls in chromium being 256.
 */
class Semaphore {
  private var _waitQueue = new AsyncWaitQueue();
  public function new(_count: Int) {}

  public var count(get, never): Int;
  function get_count() {
    return this._count;
  }

  public var waiting(get, never): Int;
  function get_waiting() {
    return this._waitQueue.length;
  }

  public function enter() {
    if (this._count !== 0) {
      this._count--;
      return Promise.resolve();
    }
    return this._waitQueue.enqueue();
  }

  public function exit(count: Int = 1) {
    if (count == 0) {
      return;
    }
    while (count != 0 && this._waitQueue.length != 0) {
      this._waitQueue.dequeue(null);
      count--;
    }
    this._count += count;
  }
}
