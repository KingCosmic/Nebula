package nebula.Util;

import nebula.Util.Future;

class AsyncWaitQueue<T> {
  // Code from StephenCleary https://gist.github.com/StephenCleary/ba50b2da419c03b9cba1d20cb4654d5e
  private _queue: Future<T>[] = [];

  public get length(): Int {
    return this._queue.length;
  }

  public enqueue(): Promise<T> {
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
  private _waitQueue = new AsyncWaitQueue();
  public function new(private _count: Int) {}

  public get count() {
    return this._count;
  }

  public get waiting() {
    return this._waitQueue.length;
  }

  // eslint-disable-next-line require-await
  public async enter() {
    if (this._count !== 0) {
      this._count--;
      return Promise.resolve();
    }
    return this._waitQueue.enqueue();
  }

  public exit(count: Int = 1) {
    if (count === 0) {
      return;
    }
    while (count !== 0 && this._waitQueue.length !== 0) {
      this._waitQueue.dequeue(null);
      count--;
    }
    this._count += count;
  }
}
