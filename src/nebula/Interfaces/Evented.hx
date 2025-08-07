package nebula.interfaces;

import nebula.EventEmitter;

interface Eventable {
  /**
   * Emits an event for target
   * @param eventName  The name of the event to publish
   * @param event      Optionally pass an event data object to the handler
   */
  function emit(eventName: String, event: Any): Void;

  /**
   * Subscribe an event handler to a particular event name, multiple handlers per event name are allowed.
   * @param eventName  The name of the event to subscribe to
   * @param handler    The handler callback to fire on this event
   */
  function on(eventName: String, handler: Handler<Any>): Void;

  /**
   * Unsubscribe an event handler(s) from an event. If a specific handler
   * is specified for an event, only that handler will be unsubscribed.
   * Otherwise all handlers will be unsubscribed for that event.
   * @param eventName  The name of the event to unsubscribe
   * @param handler    Optionally the specific handler to unsubscribe
   */
  function off(eventName: String, ?handler: Handler<Any>): Void;

  /**
   * Once listens to an event once then auto unsubscribes from that event
   * @param eventName The name of the event to subscribe to once
   * @param handler   The handler of the event that will be auto unsubscribed
   */
  function once(eventName: String, handler: Handler<Any>): Void;
}
