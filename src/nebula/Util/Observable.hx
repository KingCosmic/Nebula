package nebula.util;

/**
 * Defines a generic message that can contain any data
 * @template T is the typescript Type of the data
 */
interface Message<T> {
  var type: String;
  var data: T;
}

/**
 * Defines an interface for an observer to receive a message via a notify() method
 */
interface Observer<T> {
  function notify(message: T): Void;
}

/**
 * Defines an interface for something that might be an observer if a notify() is present
 */
typedef MaybeObserver<T> = Partial<Observer<T>>;

/**
 * Simple Observable implementation
 * @template T is the typescript Type that defines the data being observed
 */
class Observable<T> {
  public var observers: Array<Observer<T>> = [];
  public var subscriptions: Array<((val: T) -> Any)> = [];

  /**
   * Register an observer to listen to this observable
   * @param observer
   */
  function register(observer: Observer<T>) {
    this.observers.push(observer);
  }

  /**
   * Register a callback to listen to this observable
   * @param func
   */
  function subscribe(func: (val: T) -> Any) {
    this.subscriptions.push(func);
  }

  /**
   * Remove an observer from the observable
   * @param observer
   */
  function unregister(observer: Observer<T>) {
    final i = this.observers.indexOf(observer);
    if (i != -1) {
      this.observers.splice(i, 1);
    }
  }

  /**
   * Remove a callback that is listening to this observable
   * @param func
   */
  function unsubscribe(func: (val: T) -> Any) {
    final i = this.subscriptions.indexOf(func);
    if (i != -1) {
      this.subscriptions.splice(i, 1);
    }
  }

  /**
   * Broadcasts a message to all observers and callbacks
   * @param message
   */
  function notifyAll(message: T) {
    for (observer in this.observers) {
      observer.notify(message);
    }
    for (subscription in this.subscriptions) {
      subscription(message);
    }
  }

  /**
   * Removes all observers and callbacks
   */
  function clear() {
    this.observers = [];
    this.subscriptions = [];
  }
}
