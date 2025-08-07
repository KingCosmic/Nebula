package nebula.input;

import nebula.EventEmitter;
import nebula.input.PointerEvent;
import nebula.input.PointerEventReceiver;

import nebula.math.GlobalCoordinates;
import nebula.util.RentalPool;

/**
 * Signals that an object has nested pointer events on nested objects that are not an Entity with
 * a PointerComponent. For example TileMap Tiles
 */
interface HasNestedPointerEvents {
  function _dispatchPointerEvents(receiver: PointerEventReceiver): Void;
  function _processPointerToObject(receiver: PointerEventReceiver): Void;
}

/**
 *
 */
function hasNestedEvents(object: Any) {
  return object && object._dispatchPointerEvents && object._processPointerToObject;
}

class PointerTargetObjectProxy<TObject> {
  public var object: TObject;
  public var contains: (point: GlobalCoordinates) -> Bool;
  public var active: () -> Bool;
  public var events(get, never): EventEmitter;
  function get_events(): EventEmitter {
    return this.object.events;
  }
  public function init(object: TObject, contains: (point: GlobalCoordinates) -> Bool, active: () -> Bool): Void {
    this.object = object;
    this.contains = contains;
    this.active = active;
  }
}

class PointerEventsToObjectDispatcher<TObject> {
  private var _proxyPool = new RentalPool(
    () -> new PointerTargetObjectProxy<TObject>(),
    (p) -> p,
    100
  );
  private var _objectToProxy = new Map<TObject, PointerTargetObjectProxy<TObject>>();
  private var _proxies: Array<PointerTargetObjectProxy<TObject>> = [];

  /**
   * Tracks an object to associate with pointers and their events
   * @param object
   * @param contains
   * @param active
   */
  public function addObject(object: TObject, contains: (point: GlobalCoordinates) -> Bool, active: () -> Bool): Void {
    final proxy = this._proxyPool.rent(false);
    proxy.init(object, contains, active);
    this._proxies.push(proxy);
    this._objectToProxy.set(object, proxy);
  }

  private function _getProxy(object: TObject): PointerTargetObjectProxy<TObject> {
    final proxy = this._objectToProxy.get(object);
    if (proxy) {
      return proxy;
    }
    throw new Error('No PointerTargetProxy for object');
  }

  /**
   * Untracks an object associated with pointers and their events
   * @param object
   */
  public function removeObject(object: TObject): Void {
    final proxy = this._objectToProxy.get(object);
    if (proxy) {
      final index = this._proxies.indexOf(proxy);
      if (index > -1) {
        this._proxies.splice(index, 1);
      }
      this._proxyPool.restore(proxy);
    }
  }
  private var _lastFrameObjectToPointers = new Map<PointerTargetObjectProxy<Any>, Array<Int>>();
  private var _currentFrameObjectToPointers = new Map<PointerTargetObjectProxy<Any>, Array<Int>>();
  private function _objectCurrentlyUnderPointer(object: PointerTargetObjectProxy<Any>, pointerId: Int): Bool {
    return !!(this._currentFrameObjectToPointers.has(object) && this._currentFrameObjectToPointers.get(object)!.includes(pointerId));
  }

  private function _objectWasUnderPointer(object: PointerTargetObjectProxy<Any>, pointerId: Int): Bool {
    return !!(this._lastFrameObjectToPointers.has(object) && this._lastFrameObjectToPointers.get(object)!.includes(pointerId));
  }

  private function _entered(object: PointerTargetObjectProxy<Any>, pointerId: Int): Bool {
    return this._objectCurrentlyUnderPointer(object, pointerId) && !this._lastFrameObjectToPointers.has(object);
  }

  private function _left(object: PointerTargetObjectProxy<Any>, pointerId: Int): Bool {
    return !this._currentFrameObjectToPointers.has(object) && this._objectWasUnderPointer(object, pointerId);
  }

  /**
   * Manually associate a pointer id with an object.
   *
   * This assumes you've checked that the pointer is indeed over the object.
   */
  public function addPointerToObject(object: TObject, pointerId: Int): Void {
    final maybeProxy = this._objectToProxy.get(object);
    if (maybeProxy) {
      this._addPointerToProxy(maybeProxy, pointerId);
    }
  }

  private function _addPointerToProxy(object: PointerTargetObjectProxy<Any>, pointerId: Int): Void {
    if (!this._currentFrameObjectToPointers.has(object)) {
      this._currentFrameObjectToPointers.set(object, [pointerId]);
      return;
    }
    final pointers = this._currentFrameObjectToPointers.get(object)!;
    this._currentFrameObjectToPointers.set(object, pointers.concat(pointerId));
  }

  /**
   * Dispatches the appropriate pointer events in sortedObject order on tracked objects
   * @param receiver
   * @param sortedObjects
   */
  public function dispatchEvents(receiver: PointerEventReceiver, sortedObjects: Array<TObject>) {
    final lastFrameEntities = new Set(this._lastFrameObjectToPointers.keys());
    final currentFrameEntities = new Set(this._currentFrameObjectToPointers.keys());
    // Filter preserves z order
    var lastMovePerPointer: Map<Int, PointerEvent>;
    var lastUpPerPointer: Map<Int, PointerEvent>;
    var lastDownPerPointer: Map<Int, PointerEvent>;
    // Dispatch events in proxy z order
    for (object in sortedObjects) {
      final proxy = this._getProxy(object);
      if (hasNestedEvents(object)) {
        object._dispatchPointerEvents(receiver);
      }
      if (lastFrameEntities.has(proxy) || currentFrameEntities.has(proxy)) {
        lastDownPerPointer = this._processDownAndEmit(receiver, proxy);

        lastUpPerPointer = this._processUpAndEmit(receiver, proxy);

        lastMovePerPointer = this._processMoveAndEmit(receiver, proxy);

        final lastUpDownMoveEvents = [...lastMovePerPointer.values(), ...lastDownPerPointer.values(), ...lastUpPerPointer.values()];
        this._processEnterLeaveAndEmit(receiver, proxy, lastUpDownMoveEvents);

        this._processCancelAndEmit(receiver, proxy);

        this._processWheelAndEmit(receiver, proxy);
      }
    }
  }

  /**
   * Given the tracked objects, update pointer containment given the provided contains()
   * @param receiver
   * @param objects
   */
  public function processPointerToObject(receiver: PointerEventReceiver, objects: Array<TObject>) {
    // Pre-process find entities under pointers
    for (object in objects) {
      final proxy = this._getProxy(object);
      if (hasNestedEvents(object)) {
        object._processPointerToObject(receiver);
      }
      for (pointerId => pos in receiver.currentFramePointerCoords) {
        if (proxy.contains(pos)) {
          this._addPointerToProxy(proxy, pointerId);
        }
      }
    }
  }

  /**
   * Clear current frames pointer-object associations and track last frame pointer-object associations
   */
  public function clear() {
    this._lastFrameObjectToPointers.clear();
    this._lastFrameObjectToPointers = new Map<PointerTargetObjectProxy<Any>, Array<Int>>(this._currentFrameObjectToPointers);
    this._currentFrameObjectToPointers.clear();
  }

  private function _processDownAndEmit(receiver: PointerEventReceiver, object: PointerTargetObjectProxy<Any>): Map<Int, PointerEvent> {
    final lastDownPerPointer = new Map<Int, PointerEvent>();
    // Loop through down and dispatch to entities
    for (event in receiver.currentFrameDown) {
      if (event.active && this._objectCurrentlyUnderPointer(object, event.pointerId)) {
        object.events.emit('pointerdown', event);
        if (receiver.isDragStart(event.pointerId)) {
          object.events.emit('pointerdragstart', event);
        }
      }
      lastDownPerPointer.set(event.pointerId, event);
    }
    return lastDownPerPointer;
  }

  private function _processUpAndEmit(receiver: PointerEventReceiver, object: PointerTargetObjectProxy<Any>): Map<Int, PointerEvent> {
    final lastUpPerPointer = new Map<Int, PointerEvent>();
    // Loop through up and dispatch to entities
    for (event in receiver.currentFrameUp) {
      if (event.active && this._objectCurrentlyUnderPointer(object, event.pointerId)) {
        object.events.emit('pointerup', event);
        if (receiver.isDragEnd(event.pointerId)) {
          object.events.emit('pointerdragend', event);
        }
      }
      lastUpPerPointer.set(event.pointerId, event);
    }
    return lastUpPerPointer;
  }

  private function _processMoveAndEmit(receiver: PointerEventReceiver, object: PointerTargetObjectProxy<Any>): Map<Int, PointerEvent> {
    final lastMovePerPointer = new Map<Int, PointerEvent>();
    // Loop through move and dispatch to entities
    for (event in receiver.currentFrameMove) {
      if (event.active && object.active() && this._objectCurrentlyUnderPointer(object, event.pointerId)) {
        // move
        object.events.emit('pointermove', event);

        if (receiver.isDragging(event.pointerId)) {
          object.events.emit('pointerdragmove', event);
        }
      }
      lastMovePerPointer.set(event.pointerId, event);
    }
    return lastMovePerPointer;
  }

  private function _processEnterLeaveAndEmit(
    receiver: PointerEventReceiver,
    object: PointerTargetObjectProxy<Any>,
    lastUpDownMoveEvents: Array<PointerEvent>
  ) {
    // up, down, and move are considered for enter and leave
    for (event in lastUpDownMoveEvents) {
      // enter
      if (event.active && object.active() && this._entered(object, event.pointerId)) {
        object.events.emit('pointerenter', event);
        if (receiver.isDragging(event.pointerId)) {
          object.events.emit('pointerdragenter', event);
        }
        break;
      }
      if (
        event.active &&
        object.active() &&
        // leave can happen on move
        (this._left(object, event.pointerId) ||
          // or leave can happen on pointer up
          (this._objectCurrentlyUnderPointer(object, event.pointerId) && event.type == 'up'))
      ) {
        object.events.emit('pointerleave', event);
        if (receiver.isDragging(event.pointerId)) {
          object.events.emit('pointerdragleave', event);
        }
        break;
      }
    }
  }

  private function _processCancelAndEmit(receiver: PointerEventReceiver, object: PointerTargetObjectProxy<Any>) {
    // cancel
    for (event in receiver.currentFrameCancel) {
      if (event.active && object.active() && this._objectCurrentlyUnderPointer(object, event.pointerId)) {
        object.events.emit('pointercancel', event);
      }
    }
  }

  private function _processWheelAndEmit(receiver: PointerEventReceiver, object: PointerTargetObjectProxy<Any>) {
    // wheel
    for (event in receiver.currentFrameWheel) {
      // Currently the wheel only fires under the primary pointer '0'
      if (event.active && object.active() && this._objectCurrentlyUnderPointer(object, 0)) {
        object.events.emit('pointerwheel', event);
      }
    }
  }
}
