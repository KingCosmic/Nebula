package nebula.input;

import nebula.Events;
import nebula.util.IFrame;
import nebula.EventEmitter;

/**
 * Enum representing physical input key codes
 *
 * Spec: https://w3c.github.io/uievents-code/#key-alphanumeric-section
 */
enum abstract Keys(String) {
  // Writing System Keys https://w3c.github.io/uievents-code/#key-alphanumeric-writing-system
  public static inline var Backquote = 'Backquote';
  public static inline var Backslash = 'Backslash';
  public static inline var BracketLeft = 'BracketLeft';
  public static inline var BracketRight = 'BracketRight';
  public static inline var Comma = 'Comma';

  // NUMBERS
  public static inline var Key0 = 'Digit0';
  public static inline var Key1 = 'Digit1';
  public static inline var Key2 = 'Digit2';
  public static inline var Key3 = 'Digit3';
  public static inline var Key4 = 'Digit4';
  public static inline var Key5 = 'Digit5';
  public static inline var Key6 = 'Digit6';
  public static inline var Key7 = 'Digit7';
  public static inline var Key8 = 'Digit8';
  public static inline var Key9 = 'Digit9';
  public static inline var Digit0 = 'Digit0';
  public static inline var Digit1 = 'Digit1';
  public static inline var Digit2 = 'Digit2';
  public static inline var Digit3 = 'Digit3';
  public static inline var Digit4 = 'Digit4';
  public static inline var Digit5 = 'Digit5';
  public static inline var Digit6 = 'Digit6';
  public static inline var Digit7 = 'Digit7';
  public static inline var Digit8 = 'Digit8';
  public static inline var Digit9 = 'Digit9';

  public static inline var Equal = 'Equal';

  public static inline var IntlBackslash = 'IntlBackslash';
  public static inline var IntlRo = 'IntlRo';
  public static inline var IntlYen = 'IntlYen';

  // LETTERS
  public static inline var A = 'KeyA';
  public static inline var B = 'KeyB';
  public static inline var C = 'KeyC';
  public static inline var D = 'KeyD';
  public static inline var E = 'KeyE';
  public static inline var F = 'KeyF';
  public static inline var G = 'KeyG';
  public static inline var H = 'KeyH';
  public static inline var I = 'KeyI';
  public static inline var J = 'KeyJ';
  public static inline var K = 'KeyK';
  public static inline var L = 'KeyL';
  public static inline var M = 'KeyM';
  public static inline var N = 'KeyN';
  public static inline var O = 'KeyO';
  public static inline var P = 'KeyP';
  public static inline var Q = 'KeyQ';
  public static inline var R = 'KeyR';
  public static inline var S = 'KeyS';
  public static inline var T = 'KeyT';
  public static inline var U = 'KeyU';
  public static inline var V = 'KeyV';
  public static inline var W = 'KeyW';
  public static inline var X = 'KeyX';
  public static inline var Y = 'KeyY';
  public static inline var Z = 'KeyZ';
  public static inline var KeyA = 'KeyA';
  public static inline var KeyB = 'KeyB';
  public static inline var KeyC = 'KeyC';
  public static inline var KeyD = 'KeyD';
  public static inline var KeyE = 'KeyE';
  public static inline var KeyF = 'KeyF';
  public static inline var KeyG = 'KeyG';
  public static inline var KeyH = 'KeyH';
  public static inline var KeyI = 'KeyI';
  public static inline var KeyJ = 'KeyJ';
  public static inline var KeyK = 'KeyK';
  public static inline var KeyL = 'KeyL';
  public static inline var KeyM = 'KeyM';
  public static inline var KeyN = 'KeyN';
  public static inline var KeyO = 'KeyO';
  public static inline var KeyP = 'KeyP';
  public static inline var KeyQ = 'KeyQ';
  public static inline var KeyR = 'KeyR';
  public static inline var KeyS = 'KeyS';
  public static inline var KeyT = 'KeyT';
  public static inline var KeyU = 'KeyU';
  public static inline var KeyV = 'KeyV';
  public static inline var KeyW = 'KeyW';
  public static inline var KeyX = 'KeyX';
  public static inline var KeyY = 'KeyY';
  public static inline var KeyZ = 'KeyZ';

  // SYMBOLS
  public static inline var Minus = 'Minus';
  public static inline var Period = 'Period';
  public static inline var Quote = 'Quote';
  public static inline var Semicolon = 'Semicolon';
  public static inline var Slash = 'Slash';

  // Functional keys https://w3c.github.io/uievents-code/#key-alphanumeric-functional
  public static inline var AltLeft = 'AltLeft';
  public static inline var AltRight = 'AltRight';
  public static inline var Alt = 'Alt';
  public static inline var AltGraph = 'AltGraph';
  public static inline var Backspace = 'Backspace';
  public static inline var CapsLock = 'CapsLock';
  public static inline var ContextMenu = 'ContextMenu';
  public static inline var ControlLeft = 'ControlLeft';
  public static inline var ControlRight = 'ControlRight';
  public static inline var Enter = 'Enter';
  public static inline var MetaLeft = 'MetaLeft';
  public static inline var MetaRight = 'MetaRight';
  public static inline var ShiftLeft = 'ShiftLeft';
  public static inline var ShiftRight = 'ShiftRight';
  public static inline var Space = 'Space';
  public static inline var Tab = 'Tab';

  public static inline var Convert = 'Convert';
  public static inline var KanaMode = 'KanaMode';
  public static inline var NonConvert = 'NonConvert';

  // Control Pad https://w3c.github.io/uievents-code/#key-controlpad-section
  public static inline var Delete = 'Delete';
  public static inline var End = 'End';
  public static inline var Help = 'Help';
  public static inline var Home = 'Home';
  public static inline var Insert = 'Insert';
  public static inline var PageDown = 'PageDown';
  public static inline var PageUp = 'PageUp';

  // Arrow Pad https://w3c.github.io/uievents-code/#key-arrowpad-section
  public static inline var Up = 'ArrowUp';
  public static inline var Down = 'ArrowDown';
  public static inline var Left = 'ArrowLeft';
  public static inline var Right = 'ArrowRight';

  public static inline var ArrowUp = 'ArrowUp';
  public static inline var ArrowDown = 'ArrowDown';
  public static inline var ArrowLeft = 'ArrowLeft';
  public static inline var ArrowRight = 'ArrowRight';

  // Numpad Section https://w3c.github.io/uievents-code/#key-numpad-section
  public static inline var NumLock = 'NumLock';
  public static inline var Numpad0 = 'Numpad0';
  public static inline var Numpad1 = 'Numpad1';
  public static inline var Numpad2 = 'Numpad2';
  public static inline var Numpad3 = 'Numpad3';
  public static inline var Numpad4 = 'Numpad4';
  public static inline var Numpad5 = 'Numpad5';
  public static inline var Numpad6 = 'Numpad6';
  public static inline var Numpad7 = 'Numpad7';
  public static inline var Numpad8 = 'Numpad8';
  public static inline var Numpad9 = 'Numpad9';
  public static inline var Num0 = 'Numpad0';
  public static inline var Num1 = 'Numpad1';
  public static inline var Num2 = 'Numpad2';
  public static inline var Num3 = 'Numpad3';
  public static inline var Num4 = 'Numpad4';
  public static inline var Num5 = 'Numpad5';
  public static inline var Num6 = 'Numpad6';
  public static inline var Num7 = 'Numpad7';
  public static inline var Num8 = 'Numpad8';
  public static inline var Num9 = 'Numpad9';

  public static inline var NumAdd = 'NumpadAdd';
  public static inline var NumpadAdd = 'NumpadAdd';

  public static inline var NumDecimal = 'NumpadDecimal';
  public static inline var NumpadDecimal = 'NumpadDecimal';

  public static inline var NumDivide = 'NumpadDivide';
  public static inline var NumpadDivide = 'NumpadDivide';

  public static inline var NumEnter = 'NumpadEnter';
  public static inline var NumpadEnter = 'NumpadEnter';

  public static inline var NumMultiply = 'NumpadMultiply';
  public static inline var NumpadMultiply = 'NumpadMultiply';

  public static inline var NumSubtract = 'NumpadSubtract';
  public static inline var NumpadSubtract = 'NumpadSubtract';
  // NumComma = 'NumpadComma', // not x-browser
  // NumpadComma = 'NumpadComma', // not x-browser

  // Function section https://w3c.github.io/uievents-code/#key-function-section
  public static inline var Esc = 'Escape';
  public static inline var Escape = 'Escape';
  public static inline var F1 = 'F1';
  public static inline var F2 = 'F2';
  public static inline var F3 = 'F3';
  public static inline var F4 = 'F4';
  public static inline var F5 = 'F5';
  public static inline var F6 = 'F6';
  public static inline var F7 = 'F7';
  public static inline var F8 = 'F8';
  public static inline var F9 = 'F9';
  public static inline var F10 = 'F10';
  public static inline var F11 = 'F11';
  public static inline var F12 = 'F12';
  public static inline var F13 = 'F13';
  public static inline var F14 = 'F14';
  public static inline var F15 = 'F15';
  public static inline var F16 = 'F16';
  public static inline var F17 = 'F17';
  public static inline var F18 = 'F18';
  public static inline var F19 = 'F19';
  public static inline var F20 = 'F20';
  public static inline var PrintScreen = 'PrintScreen';
  public static inline var ScrollLock = 'ScrollLock';
  public static inline var Pause = 'Pause';

  public static inline var Unidentified = 'Unidentified';
}

/**
 * Event thrown on a game object for a key event
 */
class KeyEvent extends Events.GameEvent<Any> {
  /**
   * @param key  The key responsible for throwing the event
   * @param value The key's typed value the browser detected
   * @param originalEvent The original keyboard event that Excalibur handled
   */
  public function new(
    key: Keys,
    ?value: String,
    ?originalEvent: KeyboardEvent
  ) {
    super();
  }
}

interface KeyboardInitOptions {
  var global: GlobalEventHandlers;
  var grabWindowFocus: Null<Bool>;
}

typedef TKeyEvents = {
  var press: KeyEvent;
  var hold: KeyEvent;
  var release: KeyEvent;
};

final KeyEvents = {
  Press: 'press',
  Hold: 'hold',
  Release: 'release'
};

/**
 * Provides keyboard support for Excalibur.
 */
class Keyboard {
  public var events = new EventEmitter<KeyEvents>();
  private var _enabled = true;
  /**
   * Keys that are currently held down
   */
  private var _keys: Array<Keys> = [];
  /**
   * Keys up in the current frame
   */
  private var _keysUp: Array<Keys> = [];
  /**
   * Keys down in the current frame
   */
  private var _keysDown: Array<Keys> = [];

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
   * Initialize Keyboard event listeners
   */
  function init(?keyboardOptions: KeyboardInitOptions): Void {
    var global = keyboardOptions.global;
    final grabWindowFocus = keyboardOptions.grabWindowFocus;
    if (!global) {
      global = getDefaultGlobal();
    }

    // Workaround for iframes like for itch.io or codesandbox
    // https://www.reddit.com/r/gamemaker/comments/kfs5cs/keyboard_inputs_no_longer_working_in_html5_game/
    // https://forum.gamemaker.io/index.php?threads/solved-keyboard-issue-on-itch-io.87336/
    if (grabWindowFocus) {
      global.focus();
    }

    global.addEventListener('blur', () -> {
      this._keys.length = 0; // empties array efficiently
    });

    // key up is on window because canvas cannot have focus
    global.addEventListener('keyup', this._handleKeyUp);

    // key down is on window because canvas cannot have focus
    global.addEventListener('keydown', this._handleKeyDown);
  }

  function toggleEnabled(enabled: Bool) {
    this._enabled = enabled;
  }

  private function _releaseAllKeys(ev: KeyboardEvent) {
    for (code in this._keys) {
      final keyEvent = new KeyEvent(code, ev.key, ev);
      this.events.emit('up', keyEvent);
      this.events.emit('release', keyEvent);
    }
    this._keysUp = Array.from(new Set(this._keys.concat(this._keysUp)));
    this._keys.length = 0;
  };

  public function clear() {
    this._keysDown.length = 0;
    this._keysUp.length = 0;
    this._keys.length = 0;
  }

  private function _handleKeyDown(ev: KeyboardEvent) {
    if (!this._enabled) {
      return;
    }

    // handle macos meta key issue
    // https://github.com/excaliburjs/Excalibur/issues/2608
    if (!ev.metaKey && (this._keys.includes(Keys.MetaLeft) || this._keys.includes(Keys.MetaRight))) {
      this._releaseAllKeys(ev);
    }

    final code = ev.code;
    if (this._keys.indexOf(code) == -1) {
      this._keys.push(code);
      this._keysDown.push(code);
      final keyEvent = new KeyEvent(code, ev.key, ev);
      this.events.emit('down', keyEvent);
      this.events.emit('press', keyEvent);
    }
  };

  private function _handleKeyUp(ev: KeyboardEvent) {
    if (!this._enabled) {
      return;
    }
    final code = ev.code;
    final key = this._keys.indexOf(code);
    this._keys.splice(key, 1);
    this._keysUp.push(code);
    final keyEvent = new KeyEvent(code, ev.key, ev);

    // alias the old api, we may want to deprecate this in the future
    this.events.emit('up', keyEvent);
    this.events.emit('release', keyEvent);

    // handle macos meta key issue
    // https://github.com/excaliburjs/Excalibur/issues/2608
    if (ev.key == 'Meta') {
      this._releaseAllKeys(ev);
    }
  };

  public function update() {
    // Reset keysDown and keysUp after update is complete
    this._keysDown.length = 0;
    this._keysUp.length = 0;

    // Emit synthetic "hold" event
    for (i in 0...this._keys.length) {
      this.events.emit('hold', new KeyEvent(this._keys[i]));
    }
  }

  /**
   * Gets list of keys being pressed down
   */
  public function getKeys(): Array<Keys> {
    return this._keys;
  }

  /**
   * Tests if a certain key was just pressed this frame. This is cleared at the end of the update frame.
   * @param key Test whether a key was just pressed
   */
  public function wasPressed(key: Keys): Bool {
    if (!this._enabled) {
      return false;
    }
    return this._keysDown.indexOf(key) > -1;
  }

  /**
   * Tests if a certain key is held down. This is persisted between frames.
   * @param key  Test whether a key is held down
   */
  public function isHeld(key: Keys): Bool {
    if (!this._enabled) {
      return false;
    }
    return this._keys.indexOf(key) > -1;
  }

  /**
   * Tests if a certain key was just released this frame. This is cleared at the end of the update frame.
   * @param key  Test whether a key was just released
   */
  public function wasReleased(key: Keys): Bool {
    if (!this._enabled) {
      return false;
    }
    return this._keysUp.indexOf(key) > -1;
  }

  /**
   * Trigger a manual key event
   * @param type
   * @param key
   * @param character
   */
  public function triggerEvent(type: String, key: Keys, ?character: String) {
    if (type == 'down') {
      this._handleKeyDown(
        new KeyboardEvent('keydown', {
          code: key,
          key: character ?? null
        })
      );
    }
    if (type == 'up') {
      this._handleKeyUp(
        new KeyboardEvent('keyup', {
          code: key,
          key: character ?? null
        })
      );
    }
  }
}
