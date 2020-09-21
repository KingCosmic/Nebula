package core;

typedef Event = {
	fn:Any->Any->Any->Any->Any->Void,
	context:Any,
	once:Bool
}

class EventEmitter {
  private var _events:Map<String, Array<Event>> = new Map();

  private var _eventsCount:Int = 0;

  public function new() {}

	// Return an array listing the events for which the emitter has registered listeners.
  public function eventNames(): Array<String> {
    var names: Array<String> = [];

    if (_eventsCount == 0) return names;

    for (name in _events.keys()) {
      if (_events.exists(name)) {
        names.push(name);
      }
    }

    return names;
  }

  // Return the listeners registered for a given event.
	public function listeners(event:String): Array<Any->Any->Any->Any->Any->Void> {
		var handlers: Array<Event> = _events.get(event);
		var items: Array<Any->Any->Any->Any->Any->Void> = [];

    if (handlers == null) return items;

    for (handler in handlers) {
      items.push(handler.fn);
    }

    return items;
  }

  // Return the number of listeners listening to a given event.
  public function listenerCount(event: String): Int {
    var listeners: Array<Event> = _events.get(event);

    if (listeners == null) return 0;

    return listeners.length;
  }

  // Calls each of the listeners registered for a given event.
  public function emit(event: String, ?a1, ?a2, ?a3, ?a4, ?a5): Bool {
    var listeners: Array<Event> = _events.get(event);

    if (listeners == null) return false;

    for (listener in listeners) {
      if (listener.once) this.removeListener(event, listener.fn, null, true);

      listener.fn(a1, a2, a3, a4, a5);
    }

    return true;
  }

  private function addListener(event: String, fn: Any, context: Any, once: Bool) {
    var listeners: Array<Event> = _events.get(event); 
    
    if (context == null) context = this;
    
    var listener: Event = {
      fn: fn,
      context: context,
      once: once
    }

    if (listeners == null) {
      _events.set(event, [listener]);
      _eventsCount = _eventsCount + 1;
    } else {
      listeners.push(listener);
      _events.set(event, listeners);
    }

    return this;
  }

  public function clearEvent(event: String) {
    if (--_eventsCount == 0) {
      _events = new Map();
    } else {
      _events.remove(event);
    }
  }

  // Add a listener for a given event.
  public function on(event: String, fn: Any, ?context: Any): EventEmitter {
		return this.addListener(event, fn, context, false);
  }

	// Add a one-time listener for a given event.
	public function once(event: String, fn: Any, ?context: Any): EventEmitter {
		return this.addListener(event, fn, context, true);
  }

  public function removeListener(event: String, ?fn: Any, ?context: Any, ?once: Bool): EventEmitter {
    var listeners: Array<Event> = _events.get(event);
    var events: Array<Event> = [];

    if (listeners == null) return this;
    if (fn == null) {
      clearEvent(event);
      return this;
    }

    for (listener in listeners) {
      if (listener.fn != fn || (once && !listener.once) || (context != null && listener.context != context)) {
        events.push(listener);
      }
    }

    // Reset the array, or remove it completely if we have no more listeners.
    if (events.length > 0) {
      _events.set(event, events);
    } else {
      clearEvent(event);
    }

    return this;
  }

  // Remove all listeners, or those of the specified event.
  public function removeAllListeners(?event: String): EventEmitter {
    if (event == null) {
      clearEvent(event);
    } else {
      _events = new Map();
      _eventsCount = 0;
    }

    return this;
  }
}