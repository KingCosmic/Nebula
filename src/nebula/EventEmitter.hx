package nebula;

typedef EventMap = Map<String, Dynamic>;
typedef EventKey<T:EventMap> = String;
typedef Handler<EventType> = EventType -> Void;

/**
 * Interface that represents a handle to a subscription that can be closed
 */
typedef Subscription = {
  /**
   * Removes the associated event handler, synonymous with events.off(...);
   */
  function close(): Void;
}

enum Either<A, B> {
  First(a: A);
  Second(b: B);
}

typedef EventNameOrString = Either<EventKey<EventMap>, String>;

/**
 * Excalibur's typed event emitter, this allows events to be sent with any string to Type mapping
 */
class EventEmitter {
  private var _paused = false;
  private var _empty = true;
  private var _listeners: Map<String, Array<Handler<Dynamic>>> = new Map();
  private var _listenersOnce: Map<String, Array<Handler<Dynamic>>> = new Map();
  private var _pipes: Array<EventEmitter> = [];

  /**
   * Removes all listeners and pipes
   */
  function clear() {
    this._listeners = new Map();
    this._listenersOnce = new Map();
    this._pipes = [];
    this._empty = true;
  }

  function on(eventName: EventKey<EventMap>, handler: Handler<EventKey<EventMap>>): Subscription {
    this._empty = false;
    
    var listeners = this._listeners.get(eventName) ?? [];
    listeners.push(handler);

    this._listeners.set(eventName, listeners);
    return {
      close: () -> this.off(eventName, handler)
    };
  }

  function once(eventName: EventKey<EventMap>, handler: Handler<EventKey<EventMap>>): Subscription {
    this._empty = false;

    var listeners = this._listeners.get(eventName) ?? [];
    listeners.push(handler);

    this._listeners.set(eventName, listeners);
    return {
      close: () -> this.off(eventName, handler)
    };
  }


  function off(eventName: EventKey<EventMap>, ?handler: Handler<EventKey<EventMap>>): Void {
    if (handler != null) {
      final newListeners = this._listeners.get(eventName)?.filter((h) -> h != handler);
      this._listeners.set(eventName, newListeners);

      final newOnceListeners = this._listenersOnce[eventName]?.filter((h) -> h != handler);
      this._listenersOnce[eventName] = newOnceListeners;
    } else {
      this._listeners.remove(eventName);
    }
  }

  function emit(eventName: EventKey<EventMap>, ?event: EventKey<EventMap>): Void {
    if (this._empty) {
      return;
    }
    if (this._paused) {
      return;
    }
    final listeners = this._listeners.get(eventName);
    if (listeners != null) {
      for (listener in listeners) {
        listener(event);
      }
    }
    final onces = this._listenersOnce.get(eventName);
    this._listenersOnce.set(eventName, []);
    if (onces != null) {
      for (listener in onces) {
        listener(event);
      }
    }
    for (pipe in this._pipes) {
      pipe.emit(eventName, event);
    }
  }

  /**
   * Replay events from this emitter to another
   * @param emitter
   */
  function pipe(emitter: EventEmitter): Subscription {
    if (this == emitter) {
      // throw Error('Cannot pipe to self');
    }
    this._empty = false;
    this._pipes.push(emitter);

    return {
      close: () -> {
        final i = this._pipes.indexOf(emitter);
        if (i > -1) {
          this._pipes.splice(i, 1);
        }
      }
    };
  }

  /**
   * Remove any piped emitters
   * @param emitter
   */
  function unpipe(emitter: EventEmitter): Void {
    final i = this._pipes.indexOf(emitter);
    if (i > -1) {
      this._pipes.splice(i, 1);
    }
  }

  /**
   * Paused event emitters do not emit events
   */
  function pause(): Void {
    this._paused = true;
  }

  /**
   * Unpaused event emitter do emit events
   */
  function unpause(): Void {
    this._paused = false;
  }
}
