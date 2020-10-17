package core.input.keyboard;

import core.EventEmitter.Event;
import core.input.keyboard.KeyboardManager.KeyEvent;
import kha.Scheduler;

/**
 * A generic Key object which can be passed to the Process functions (and so on)
 * keycode must be an integer
 */
class Key extends EventEmitter {
  // The Keyboard Plugin that owns this Key object.
  public var plugin:KeyboardPlugin;

  // The keycode of this key.
  public var keyCode:Int;

  // Can this Key be processed?
  public var enabled:Bool = true;

  // The "down" state of the key. This will remain `true` for as long as the keyboard thinks this key is held down.
  public var isDown:Bool = false;

  // The "up" state of the key. This will remain `true` for as long as the keyboard thinks this key is up.
  public var isUp:Bool = true;

  // The down state of the ALT key, if pressed at the same time as this key.
  public var altKey:Bool = false;

  // The down state of the CTRL key, if pressed at the same time as this key.
  public var ctrlKey:Bool = false;

  // The down state of the SHIFT key, if pressed at the same time as this key.
  public var shiftKey:Bool = false;

  /**
   * The down state of the Meta key, if pressed at the same time as this key.
   * On a Mac the Meta Key is the Command key. On Windows keyboards, it's the Windows key.
   */
  public var metaKey:Bool = false;

  // The location of the modifier key. 0 for standard (or unknown), 1 for left, 2 for right, 3 for numpad.
  public var location:Int = 0;

  // The timestamp when the key was last pressed down.
  public var timeDown:Float = 0;

  // The last raw event processed by this key.
  public var lastEvent:KeyEvent;

  /**
   * The number of milliseconds this key was held down for in the previous down - up sequence.
   * This value isn't updated every game step, only when the Key changes state.
   * To get the current duration use the `getDuration` method.
   */
  public var duration:Float = 0;

  // The timestamp when the key was last released.
  public var timeUp:Float = 0;

  /**
   * When a key is held down should it continuously fire the `down` event each time it repeats?
   * 
   * By default it will emit the `down` event just once, but if you wish to receive the event
   * for each repeat as well, enable this property.
   */
  public var emitOnRepeat:Bool = false;

  // If a key is held down this holds down the number of times the key has 'repeated'.
  public var repeats:Int = 0;

  // True if the key has just been pressed (NOTE: requires to be reset, see justDown getter)
  public var _justDown:Bool = false;

  // True if the key has just been pressed (NOTE: requires to be reset, see justDown getter)
  public var _justUp:Bool = false;

  // Internal tick counter.
  public var _tick:Float = -1;

  public function new(_plugin:KeyboardPlugin, _keyCode:Int) {
    super();

    plugin = _plugin;
    keyCode = _keyCode;
  }

  /**
   * Controls if this Key will continuously emit a `down` event while being held down (true),
   * or emit the event just once, on first press, and then skip future events (false).
   */
  public function setEmitOnRepeat(value:Bool) {
    emitOnRepeat = value;

    return this;
  }

  /**
   * Processes the Key Down action for this Key.
   * Called automatically by the Keyboard Plugin.
   */
  public function onDown(event:KeyEvent) {
    lastEvent = event;

    if (!enabled) return;

    repeats++;

    if (!isDown) {
      isDown = true;
      isUp = false;
      timeDown = event.timeStamp;
      duration = 0;
      _justDown = true;
      _justUp = false;

      emit('DOWN', this);
    } else if (emitOnRepeat) {
      emit('DOWN', this);
    }
  }

  /**
   * Processes the Key Up action for this Key.
   * Called automatically by the Keyboard Plugin.
   */
  public function onUp(event:KeyEvent) {
    lastEvent = event;

    if (!enabled) return;

    isDown = false;
    isUp = true;
    timeUp = event.timeStamp;
    duration = timeUp - timeDown;
    repeats = 0;

    _justDown = false;
    _justUp = true;
    _tick = -1;

    emit('UP', this);
  }

  /**
   * Resets this Key object back to its default un-pressed state.
   */
  public function reset() {
    enabled = true;
    isDown = false;
    isUp = true;
    altKey = false;
    ctrlKey = false;
    shiftKey = false;
    metaKey = false;
    timeDown = 0;
    duration = 0;
    timeUp = 0;
    repeats = 0;
    _justDown = false;
    _justUp = false;
    _tick = -1;

    return this;
  }

  /**
   * Returns the duration, in ms, that the Key has been held down for.
   * 
   * If the key is not currently down it will return zero.
   * 
   * The get the duration the Key was held down for in the previous up-down cycle,
   * use the `Key.duration` property value instead.
   */
  public function getDuration():Float {
    if (!isDown) return 0;

    return (plugin.game.loop.time - timeDown);
  }

  /**
   * Removes any bound event handlers and removes local references.
   */
  public function destroy() {
    removeAllListeners();

    plugin = null;
  }
}