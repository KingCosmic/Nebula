package nebula.input;

import nebula.Engine;
import nebula.math.GlobalCoordinates;
import nebula.math.Vector;

import nebula.input.PointerEvent;
import nebula.input.WheelEvent;
import nebula.input.PointerAbstraction;
import nebula.input.WheelDeltaMode;
import nebula.input.PointerSystem;
import nebula.input.NativePointerButton;
import nebula.input.PointerButton;
import nebula.util.Util;
import nebula.input.PointerType;
import nebula.util.IFrame;
import nebula.EventEmitter;

typedef NativePointerEvent = globalThis.PointerEvent;
typedef NativeMouseEvent = globalThis.MouseEvent;
typedef NativeTouchEvent = globalThis.TouchEvent;
typedef NativeWheelEvent = globalThis.WheelEvent;

typedef TPointerEvents = {
  var move: PointerEvent;
  var down: PointerEvent;
  var up: PointerEvent;
  var wheel: WheelEvent;
};

final PointerEvents = {
  Move: 'move',
  Down: 'down',
  Up: 'up',
  Wheel: 'wheel'
};

/**
 * Is this event a native touch event?
 */
function isTouchEvent(value: Any) {
  // Guard for Safari <= 13.1
  return true;
}

/**
 * Is this event a native pointer event
 */
function isPointerEvent(value: Any) {
  // Guard for Safari <= 13.1
  return true;
}

interface PointerInitOptions {
  var grabWindowFocus: Null<Bool>;
}

/**
 * The PointerEventProcessor is responsible for collecting all the events from the canvas and transforming them into GlobalCoordinates
 */
class PointerEventReceiver {
  public var events = new EventEmitter<PointerEvents>();
  public var primary: PointerAbstraction = new PointerAbstraction();

  private var _activeNativePointerIdsToNormalized = new Map<Int, Int>();
  public var lastFramePointerCoords = new Map<Int, GlobalCoordinates>();
  public var currentFramePointerCoords = new Map<Int, GlobalCoordinates>();

  public var currentFramePointerDown = new Map<Int, Bool>();
  public var lastFramePointerDown = new Map<Int, Bool>();

  public var currentFrameDown: Array<PointerEvent> = [];
  public var currentFrameUp: Array<PointerEvent> = [];
  public var currentFrameMove: Array<PointerEvent> = [];
  public var currentFrameCancel: Array<PointerEvent> = [];
  public var currentFrameWheel: Array<PointerEvent> = [];

  private var _enabled = true;

  public function new(
    target: GlobalEventHandlers & EventTarget,
    engine: Engine
  ) {}

  public function toggleEnabled(enabled: Bool) {
    this._enabled = enabled;
  }

  /**
   * Creates a new PointerEventReceiver with a new target and engine while preserving existing pointer event
   * handlers.
   * @param target
   * @param engine
   */
  public function recreate(target: GlobalEventHandlers & EventTarget, engine: Engine) {
    final eventReceiver = new PointerEventReceiver(target, engine);
    eventReceiver.primary = this.primary;
    eventReceiver._pointers = this._pointers;
    return eventReceiver;
  }

  private var _pointers: Array<PointerAbstraction> = [this.primary];
  /**
   * Locates a specific pointer by id, creates it if it doesn't exist
   * @param index
   */
  public function at(index: Int): PointerAbstraction {
    if (index >= this._pointers.length) {
      // Ensure there is a pointer to retrieve
      for (i in this._pointers.length - 1...index) {
        this._pointers.push(new PointerAbstraction());
      }
    }
    return this._pointers[index];
  }

  /**
   * The number of pointers currently being tracked by excalibur
   */
  public function count(): Int {
    return this._pointers.length;
  }

  /**
   * Is the specified pointer id down this frame
   * @param pointerId
   */
  public function isDown(pointerId: Int) {
    if (!this._enabled) {
      return false;
    }
    return this.currentFramePointerDown.get(pointerId) ?? false;
  }

  /**
   * Was the specified pointer id down last frame
   * @param pointerId
   */
  public function wasDown(pointerId: Int) {
    if (!this._enabled) {
      return false;
    }
    return this.lastFramePointerDown.get(pointerId) ?? false;
  }

  /**
   * Whether the Pointer is currently dragging.
   */
  public function isDragging(pointerId: Int): Bool {
    if (!this._enabled) {
      return false;
    }
    return this.isDown(pointerId);
  }

  /**
   * Whether the Pointer just started dragging.
   */
  public function isDragStart(pointerId: Int): Bool {
    if (!this._enabled) {
      return false;
    }
    return this.isDown(pointerId) && !this.wasDown(pointerId);
  }

  /**
   * Whether the Pointer just ended dragging.
   */
  public function isDragEnd(pointerId: Int): Bool {
    if (!this._enabled) {
      return false;
    }
    return !this.isDown(pointerId) && this.wasDown(pointerId);
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    this.events.off(eventName, handler);
  }

  /**
   * Called internally by excalibur
   *
   * Updates the current frame pointer info and emits raw pointer events
   *
   * This does not emit events to entities, see PointerSystem
   * @internal
   */
  public function update() {
    this.lastFramePointerDown = new Map(this.currentFramePointerDown);
    this.lastFramePointerCoords = new Map(this.currentFramePointerCoords);

    for (event in this.currentFrameDown) {
      if (!event.active) {
        continue;
      }
      this.emit('down', event);
      final pointer = this.at(event.pointerId);
      pointer.emit('down', event);
      this.primary.emit('pointerdown', event);
    }

    for (event in this.currentFrameUp) {
      if (!event.active) {
        continue;
      }
      this.emit('up', event);
      final pointer = this.at(event.pointerId);
      pointer.emit('up', event);
    }

    for (event in this.currentFrameMove) {
      if (!event.active) {
        continue;
      }
      this.emit('move', event);
      final pointer = this.at(event.pointerId);
      pointer.emit('move', event);
    }

    for (event in this.currentFrameCancel) {
      if (!event.active) {
        continue;
      }
      this.emit('cancel', event);
      final pointer = this.at(event.pointerId);
      pointer.emit('cancel', event);
    }

    for (event in this.currentFrameWheel) {
      if (!event.active) {
        continue;
      }
      this.emit('pointerwheel', event);
      this.emit('wheel', event);
      this.primary.emit('pointerwheel', event);
      this.primary.emit('wheel', event);
    }

    if (this.engine.currentScene.camera.hasChanged()) {
      for (pointer in this._pointers) {
        pointer._updateWorldPosition(this.engine);
      }
    }
  }

  /**
   * Clears the current frame event and pointer data
   */
  public function clear() {
    for (event in this.currentFrameUp) {
      this.currentFramePointerCoords.delete(event.pointerId);
      for (native => normalized in this._activeNativePointerIdsToNormalized) {
        if (normalized == event.pointerId) {
          this._activeNativePointerIdsToNormalized.delete(native);
        }
      }
    }
    this.currentFrameDown.length = 0;
    this.currentFrameUp.length = 0;
    this.currentFrameMove.length = 0;
    this.currentFrameCancel.length = 0;
    this.currentFrameWheel.length = 0;
  }

  private var _boundHandle = this._handle.bind(this);
  private var _boundWheel = this._handleWheel.bind(this);
  /**
   * Initializes the pointer event receiver so that it can start listening to native
   * browser events.
   */
  public function init(?options: PointerInitOptions) {
    if (this.engine.isDisposed()) {
      return;
    }
    // Disabling the touch action avoids browser/platform gestures from firing on the canvas
    // It is important on mobile to have touch action 'none'
    // https://stackoverflow.com/questions/48124372/pointermove-event-not-working-with-touch-why-not
    if (this.target == this.engine.canvas) {
      this.engine.canvas.style.touchAction = 'none';
    } else {
      document.body.style.touchAction = 'none';
    }
    // Preferred pointer events
    if (window.PointerEvent) {
      this.target.addEventListener('pointerdown', this._boundHandle);
      this.target.addEventListener('pointerup', this._boundHandle);
      this.target.addEventListener('pointermove', this._boundHandle);
      this.target.addEventListener('pointercancel', this._boundHandle);
    } else {
      // Touch Events
      this.target.addEventListener('touchstart', this._boundHandle);
      this.target.addEventListener('touchend', this._boundHandle);
      this.target.addEventListener('touchmove', this._boundHandle);
      this.target.addEventListener('touchcancel', this._boundHandle);

      // Mouse Events
      this.target.addEventListener('mousedown', this._boundHandle);
      this.target.addEventListener('mouseup', this._boundHandle);
      this.target.addEventListener('mousemove', this._boundHandle);
    }

    // MDN MouseWheelEvent
    final wheelOptions = {
      passive: !(
        this.engine.pageScrollPreventionMode == ScrollPreventionMode.All ||
        this.engine.pageScrollPreventionMode == ScrollPreventionMode.Canvas
      )
    };
    if ('onwheel' in document.createElement('div')) {
      // Modern Browsers
      this.target.addEventListener('wheel', this._boundWheel, wheelOptions);
    } else if (document.onmousewheel != null) {
      // Webkit and IE
      this.target.addEventListener('mousewheel', this._boundWheel, wheelOptions);
    } else {
      // Remaining browser and older Firefox
      this.target.addEventListener('MozMousePixelScroll', this._boundWheel, wheelOptions);
    }

    final grabWindowFocus = options?.grabWindowFocus ?? true;
    // Handle cross origin iframe
    if (grabWindowFocus && (isCrossOriginIframe() || isIframe())) {
      final grabFocus = () -> {
        window.focus();
      };
      // Preferred pointer events
      if (window.PointerEvent) {
        this.target.addEventListener('pointerdown', grabFocus);
      } else {
        // Touch Events
        this.target.addEventListener('touchstart', grabFocus);

        // Mouse Events
        this.target.addEventListener('mousedown', grabFocus);
      }
    }
  }

  public function detach() {
    // Preferred pointer events
    if (window.PointerEvent) {
      this.target.removeEventListener('pointerdown', this._boundHandle);
      this.target.removeEventListener('pointerup', this._boundHandle);
      this.target.removeEventListener('pointermove', this._boundHandle);
      this.target.removeEventListener('pointercancel', this._boundHandle);
    } else {
      // Touch Events
      this.target.removeEventListener('touchstart', this._boundHandle);
      this.target.removeEventListener('touchend', this._boundHandle);
      this.target.removeEventListener('touchmove', this._boundHandle);
      this.target.removeEventListener('touchcancel', this._boundHandle);

      // Mouse Events
      this.target.removeEventListener('mousedown', this._boundHandle);
      this.target.removeEventListener('mouseup', this._boundHandle);
      this.target.removeEventListener('mousemove', this._boundHandle);
    }

    if ('onwheel' in document.createElement('div')) {
      // Modern Browsers
      this.target.removeEventListener('wheel', this._boundWheel);
    } else if (document.onmousewheel != undefined) {
      // Webkit and IE
      this.target.addEventListener('mousewheel', this._boundWheel);
    } else {
      // Remaining browser and older Firefox
      this.target.addEventListener('MozMousePixelScroll', this._boundWheel);
    }
  }

  /**
   * Take native pointer id and map it to index in active pointers
   * @param nativePointerId
   */
  private function _normalizePointerId(nativePointerId: Int) {
    // Add to the the native pointer set id
    this._activeNativePointerIdsToNormalized.set(nativePointerId, -1);

    // Native pointer ids in ascending order
    final currentPointerIds = Array.from(this._activeNativePointerIdsToNormalized.keys()).sort((a, b) -> a - b);

    // The index into sorted ids will be the new id, will always have an id
    final id = currentPointerIds.findIndex((p) -> p == nativePointerId);

    // Save the mapping so we can reverse it later
    this._activeNativePointerIdsToNormalized.set(nativePointerId, id);

    // ignore pointer because game isn't watching
    return id;
  }

  /**
   * Responsible for handling and parsing pointer events
   */
  private function _handle(ev: Any) {
    if (!this._enabled) {
      return;
    }
    ev.preventDefault();
    final eventCoords = new Map<Int, GlobalCoordinates>();
    var button: PointerButton;
    var pointerType: PointerType;
    if (isTouchEvent(ev)) {
      button = PointerButton.Unknown;
      pointerType = PointerType.Touch;
      // https://developer.mozilla.org/en-US/docs/Web/API/TouchEvent
      for (i in 0...ev.changedTouches.length) {
        final touch = ev.changedTouches[i];
        final coordinates = GlobalCoordinates.fromPagePosition(touch.pageX, touch.pageY, this.engine);
        final nativePointerId = i + 1;
        final pointerId = this._normalizePointerId(nativePointerId);
        this.currentFramePointerCoords.set(pointerId, coordinates);
        eventCoords.set(pointerId, coordinates);
      }
    } else {
      button = this._nativeButtonToPointerButton(ev.button);
      pointerType = PointerType.Mouse;
      final coordinates = GlobalCoordinates.fromPagePosition(ev.pageX, ev.pageY, this.engine);
      var nativePointerId = 1;
      if (isPointerEvent(ev)) {
        nativePointerId = ev.pointerId;
        pointerType = this._stringToPointerType(ev.pointerType);
      }
      final pointerId = this._normalizePointerId(nativePointerId);
      this.currentFramePointerCoords.set(pointerId, coordinates);
      eventCoords.set(pointerId, coordinates);
    }

    for (pointerId => coord in eventCoords) {
      switch (ev.type) {
        case 'mousedown':
        case 'pointerdown':
        case 'touchstart':
          this.currentFrameDown.push(new PointerEvent('down', pointerId, button, pointerType, coord, ev));
          this.currentFramePointerDown.set(pointerId, true);
          break;
        case 'mouseup':
        case 'pointerup':
        case 'touchend':
          this.currentFrameUp.push(new PointerEvent('up', pointerId, button, pointerType, coord, ev));
          this.currentFramePointerDown.set(pointerId, false);
          break;
        case 'mousemove':
        case 'pointermove':
        case 'touchmove':
          this.currentFrameMove.push(new PointerEvent('move', pointerId, button, pointerType, coord, ev));
          break;
        case 'touchcancel':
        case 'pointercancel':
          this.currentFrameCancel.push(new PointerEvent('cancel', pointerId, button, pointerType, coord, ev));
          break;
      }
    }
  }

  private function _handleWheel(ev: NativeWheelEvent) {
    if (!this._enabled) {
      return;
    }
    // Should we prevent page scroll because of this event
    if (
      this.engine.pageScrollPreventionMode == ScrollPreventionMode.All ||
      (this.engine.pageScrollPreventionMode == ScrollPreventionMode.Canvas && ev.target == this.engine.canvas)
    ) {
      ev.preventDefault();
    }
    final screen = this.engine.screen.pageToScreenCoordinates(vec(ev.pageX, ev.pageY));
    final world = this.engine.screen.screenToWorldCoordinates(screen);

    /**
     * A constant used to normalize wheel events across different browsers
     *
     * This normalization factor is pulled from
     * https://developer.mozilla.org/en-US/docs/Web/Events/wheel#Listening_to_this_event_across_browser
     */
    final ScrollWheelNormalizationFactor = -1 / 40;

    final deltaX = ev.deltaX || ev.wheelDeltaX * ScrollWheelNormalizationFactor || 0;
    final deltaY =
      ev.deltaY || ev.wheelDeltaY * ScrollWheelNormalizationFactor || ev.wheelDelta * ScrollWheelNormalizationFactor || ev.detail || 0;
    final deltaZ = ev.deltaZ || 0;
    var deltaMode = WheelDeltaMode.Pixel;

    if (ev.deltaMode) {
      if (ev.deltaMode == 1) {
        deltaMode = WheelDeltaMode.Line;
      } else if (ev.deltaMode == 2) {
        deltaMode = WheelDeltaMode.Page;
      }
    }

    final we = new WheelEvent(world.x, world.y, ev.pageX, ev.pageY, screen.x, screen.y, 0, deltaX, deltaY, deltaZ, deltaMode, ev);
    this.currentFrameWheel.push(we);
  }

  /**
   * Triggers an excalibur pointer event in a world space pos
   *
   * Useful for testing pointers in excalibur
   * @param type
   * @param pos
   */
  public function triggerEvent(type: String, pos: Vector) {
    final page = this.engine.screen.worldToPageCoordinates(pos);
    // Send an event to the event receiver
    if (window.PointerEvent) {
      this._handle(
        new window.PointerEvent('pointer' + type, {
          pointerId: 0,
          clientX: page.x,
          clientY: page.y
        })
      );
    } else {
      // Safari hack
      this._handle(
        new window.MouseEvent('mouse' + type, {
          clientX: page.x,
          clientY: page.y
        })
      );
    }

    // Force update pointer system
    final pointerSystem = this.engine.currentScene.world.get(PointerSystem);
    pointerSystem.preupdate(this.engine.currentScene, 1);
    pointerSystem.update(1);
  }

  private function _nativeButtonToPointerButton(s: NativePointerButton): PointerButton {
    switch (s) {
      case NativePointerButton.NoButton:
        return PointerButton.NoButton;
      case NativePointerButton.Left:
        return PointerButton.Left;
      case NativePointerButton.Middle:
        return PointerButton.Middle;
      case NativePointerButton.Right:
        return PointerButton.Right;
      case NativePointerButton.Unknown:
        return PointerButton.Unknown;
      default:
        return fail(s);
    }
  }

  private function _stringToPointerType(s: String) {
    switch (s) {
      case 'touch':
        return PointerType.Touch;
      case 'mouse':
        return PointerType.Mouse;
      case 'pen':
        return PointerType.Pen;
      default:
        return PointerType.Unknown;
    }
  }
}
