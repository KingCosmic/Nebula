package nebula.Util;

/**
 * Defines a generic message that can contain any data
 * @template T is the typescript Type of the data
 */
interface Message<T> {
  type: String;
  data: T;
}

/**
 * Defines an interface for an observer to receive a message via a notify() method
 */
interface Observer<T> {
  notify(message: T): Void;
}

/**
 * Defines an interface for something that might be an observer if a notify() is present
 */
type MaybeObserver<T> = Partial<Observer<T>>;

/**
 * Simple Observable implementation
 * @template T is the typescript Type that defines the data being observed
 */
class Observable<T> {
  public observers: Observer<T>[] = [];
  public subscriptions: ((val: T) => dynamic)[] = [];

  /**
   * Register an observer to listen to this observable
   * @param observer
   */
  register(observer: Observer<T>) {
    this.observers.push(observer);
  }

  /**
   * Register a callback to listen to this observable
   * @param func
   */
  subscribe(func: (val: T) => dynamic) {
    this.subscriptions.push(func);
  }

  /**
   * Remove an observer from the observable
   * @param observer
   */
  unregister(observer: Observer<T>) {
    final i = this.observers.indexOf(observer);
    if (i !== -1) {
      this.observers.splice(i, 1);
    }
  }

  /**
   * Remove a callback that is listening to this observable
   * @param func
   */
  unsubscribe(func: (val: T) => dynamic) {
    final i = this.subscriptions.indexOf(func);
    if (i !== -1) {
      this.subscriptions.splice(i, 1);
    }
  }

  /**
   * Broadcasts a message to all observers and callbacks
   * @param message
   */
  notifyAll(message: T) {
    final observersLength = this.observers.length;
    for (var i = 0; i < observersLength; i++) {
      this.observers[i].notify(message);
    }
    final subscriptionsLength = this.subscriptions.length;
    for (var i = 0; i < subscriptionsLength; i++) {
      this.subscriptions[i](message);
    }
  }

  /**
   * Removes all observers and callbacks
   */
  clear() {
    this.observers.length = 0;
    this.subscriptions.length = 0;
  }
}
