package nebula.input;

import nebula.Events;
import nebula.EventEmitter;

typedef TGamepadEvents = {
  var connect: GamepadConnectEvent;
  var disconnect: GamepadDisconnectEvent;
  var button: GamepadButtonEvent;
  var axis: GamepadAxisEvent;
};

final GamepadEvents = {
  GamepadConnect: 'connect',
  GamepadDisconnect: 'disconnect',
  GamepadButton: 'button',
  GamepadAxis: 'axis'
};

/**
 * Excalibur leverages the HTML5 Gamepad API [where it is supported](http://caniuse.com/#feat=gamepad)
 * to provide controller support for your games.
 */
class Gamepads {
  public var events = new EventEmitter<GamepadEvents>();
  /**
   * Whether or not to poll for Gamepad input (default: `false`)
   */
  public var enabled = false;

  /**
   * Whether or not Gamepad API is supported
   */
  public var supported = !!(navigator).getGamepads;

  /**
   * The minimum value an axis has to move before considering it a change
   */
  public static var MinAxisMoveThreshold = 0.05;

  private var _gamePadTimeStamps = [0, 0, 0, 0];
  private var _oldPads: Array<Gamepad> = [];
  private var _pads: Array<Gamepad> = [];
  private var _initSuccess: Bool = false;
  private var _navigator: NavigatorGamepads = navigator;
  private var _minimumConfiguration: Null<GamepadConfiguration> = null;
  private var _enabled = true;

  public function init() {
    if (!this.supported) {
      return;
    }
    if (this._initSuccess) {
      return;
    }

    // In Chrome, this will return 4 undefined items until a button is pressed
    // In FF, this will not return any items until a button is pressed
    this._oldPads = this._clonePads(this._navigator.getGamepads());
    if (this._oldPads.length && this._oldPads[0]) {
      this._initSuccess = true;
    }
  }

  public function toggleEnabled(enabled: Bool) {
    this._enabled = enabled;
  }

  /**
   * Sets the minimum gamepad configuration, for example {axis: 4, buttons: 4} means
   * this game requires at minimum 4 axis inputs and 4 buttons, this is not restrictive
   * all other controllers with more axis or buttons are valid as well. If no minimum
   * configuration is set all pads are valid.
   */
  public function setMinimumGamepadConfiguration(config: GamepadConfiguration): Void {
    this._enableAndUpdate(); // if config is used, implicitly enable
    this._minimumConfiguration = config;
  }

  /**
   * When implicitly enabled, set the enabled flag and run an update so information is updated
   */
  private function _enableAndUpdate() {
    if (!this.enabled) {
      this.enabled = true;
      this.update();
    }
  }

  /**
   * Checks a navigator gamepad against the minimum configuration if present.
   */
  private function _isGamepadValid(pad: NavigatorGamepad): Bool {
    if (!this._minimumConfiguration) {
      return true;
    }
    if (!pad) {
      return false;
    }
    final axesLength = pad.axes.filter((value) -> {
      return value != null;
    }).length;

    final buttonLength = pad.buttons.filter((value) -> {
      return value != null;
    }).length;
    return axesLength >= this._minimumConfiguration.axis && buttonLength >= this._minimumConfiguration.buttons && pad.connected;
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    this._enableAndUpdate(); // implicitly enable
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    this._enableAndUpdate(); // implicitly enable
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    this._enableAndUpdate(); // implicitly enable
    this.events.off(eventName, handler);
  }

  /**
   * Updates Gamepad state and publishes Gamepad events
   */
  public function update() {
    if (!this.enabled || !this.supported) {
      return;
    }
    if (!this._enabled) {
      return;
    }
    this.init();

    final gamepads = this._navigator.getGamepads();
    for (i in 0...gamepads.length) {
      if (!gamepads[i]) {
        final gamepad = this.at(i);
        // If was connected, but now isn't emit the disconnect event
        if (gamepad.connected) {
          this.events.emit('disconnect', new GamepadDisconnectEvent(i, gamepad));
          gamepad.events.unpipe(this.events);
        }
        // Reset connection status
        gamepad.connected = false;
        continue;
      } else {
        final gamepad = this.at(i);
        if (!this.at(i).connected && this._isGamepadValid(gamepads[i])) {
          gamepad.events.pipe(this.events);
          this.events.emit('connect', new GamepadConnectEvent(i, this.at(i)));
        }
        // Set connection status
        this.at(i).connected = true;
      }

      this.at(i).update();

      // Only supported in Chrome
      if (gamepads[i].timestamp && gamepads[i].timestamp == this._gamePadTimeStamps[i]) {
        continue;
      }

      this._gamePadTimeStamps[i] = gamepads[i].timestamp;

      // Add reference to navigator gamepad
      this.at(i).navigatorGamepad = gamepads[i];

      // Buttons

      final gamepad = gamepads[i];
      // gamepads are a list that might be null
      if (gamepad) {
        for (buttonIndex in 0...gamepad.buttons.length) {
          final button = gamepad.buttons[buttonIndex];
          final value = button?.value;
          if (value != this._oldPads[i]?.getButton(buttonIndex)) {
            if (button?.pressed) {
              this.at(i).updateButton(buttonIndex, value);
              // Fallback to unknown if not mapped
              // prettier-ignore
              this.at(i).events.emit('button', new GamepadButtonEvent(
                buttonIndex in Buttons ? buttonIndex : Buttons.Unknown,
                buttonIndex,
                value,
                this.at(i))
              );
            } else {
              this.at(i).updateButton(buttonIndex, 0);
            }
          }
        }

        for (axesIndex in 0...gamepad.axes.length) {
          final axis = gamepad.axes[axesIndex];
          if (axis != this._oldPads[i]?.getAxes(axesIndex)) {
            this.at(i).updateAxes(axesIndex, axis);
            this.at(i).events.emit('axis', new GamepadAxisEvent(axesIndex, axis, this.at(i)));
          }
        }
      }
      this._oldPads[i] = this._clonePad(gamepads[i]);
    }
  }

  /**
   * Safely retrieves a Gamepad at a specific index and creates one if it doesn't yet exist
   */
  public function at(index: Int): Gamepad {
    this._enableAndUpdate(); // implicitly enable gamepads when at() is called
    if (index >= this._pads.length) {
      // Ensure there is a pad to retrieve
      for (i in this._pads.length - 1...index) {
        this._pads.push(new Gamepad());
        this._oldPads.push(new Gamepad());
      }
    }

    return this._pads[index];
  }

  /**
   * Returns a list of all valid gamepads that meet the minimum configuration requirement.
   */
  public function getValidGamepads(): Array<Gamepad> {
    this._enableAndUpdate();
    final result: Array<Gamepad> = [];
    for (i in 0...this._pads.length) {
      if (this._isGamepadValid(this.at(i).navigatorGamepad) && this.at(i).connected) {
        result.push(this.at(i));
      }
    }
    return result;
  }

  /**
   * Gets the number of connected gamepads
   */
  public function count() {
    return this._pads.filter((p) -> p.connected).length;
  }

  private function _clonePads(pads: Array<NavigatorGamepad>): Array<Gamepad> {
    final arr = [];
    for (i in 0...pads.length) {
      arr.push(this._clonePad(pads[i]));
    }
    return arr;
  }

  /**
   * Fastest way to clone a known object is to do it yourself
   */
  private function _clonePad(pad: NavigatorGamepad): Gamepad {
    var i, len;
    final clonedPad = new Gamepad();

    if (!pad) {
      return clonedPad;
    }

    for (i in 0...pad.buttons.length) {
      if (pad.buttons[i]) {
        clonedPad.updateButton(i, pad.buttons[i].value);
      }
    }
    for (i in 0...pad.axes.length) {
      clonedPad.updateAxes(i, pad.axes[i]);
    }

    return clonedPad;
  }
}

/**
 * Gamepad holds state information for a connected controller. See {@apilink Gamepads}
 * for more information on handling controller input.
 */
class Gamepad {
  public var events = new EventEmitter<GamepadEvents>();
  public var connected = false;
  public var navigatorGamepad: NavigatorGamepad;
  private var _axes: Array<Int> = new Array(4);
  private var _buttons: Array<Int> = new Array(16);
  private var _buttonsUp: Array<Int> = new Array(16);
  private var _buttonsDown: Array<Int> = new Array(16);

  public function new() {
    for (i in 0...this._buttons.length) {
      this._buttons[i] = 0;
    }
    for (i in 0...this._axes.length) {
      this._axes[i] = 0;
    }
  }

  public function update() {
    // Reset buttonsDown and buttonsUp after update is complete
    this._buttonsDown = new Array(16);
    this._buttonsUp = new Array(16);
  }

  /**
   * Whether or not the given button is pressed
   * @deprecated will be removed in v0.28.0. Use isButtonHeld instead
   * @param button     The button to query
   * @param threshold  The threshold over which the button is considered to be pressed
   */
  public function isButtonPressed(button: Int, threshold: Float = 1) {
    return this._buttons[button] >= threshold;
  }

  /**
   * Tests if a certain button is held down. This is persisted between frames.
   * @param button     The button to query
   * @param threshold  The threshold over which the button is considered to be pressed
   */
  public function isButtonHeld(button: Int, threshold: Float = 1) {
    return this._buttons[button] >= threshold;
  }

  /**
   * Tests if a certain button was just pressed this frame. This is cleared at the end of the update frame.
   * @param button Test whether a button was just pressed
   * @param threshold  The threshold over which the button is considered to be pressed
   */
  public function wasButtonPressed(button: Int, threshold: Float = 1) {
    return this._buttonsDown[button] >= threshold;
  }

  /**
   * Tests if a certain button was just released this frame. This is cleared at the end of the update frame.
   * @param button  Test whether a button was just released
   */
  public function wasButtonReleased(button: Int) {
    return Boolean(this._buttonsUp[button]);
  }

  /**
   * Gets the given button value between 0 and 1
   */
  public function getButton(button: Int) {
    return this._buttons[button];
  }

  /**
   * Gets the given axis value between -1 and 1. Values below
   * {@apilink MinAxisMoveThreshold} are considered 0.
   */
  public function getAxes(axes: Int) {
    final value = this._axes[axes];

    if (Math.abs(value) < Gamepads.MinAxisMoveThreshold) {
      return 0;
    } else {
      return value;
    }
  }

  public function updateButton(buttonIndex: Int, value: Float) {
    // button was just released
    if (value == 0 && this._buttons[buttonIndex]) {
      this._buttonsUp[buttonIndex] = 1;

      // button was just pressed
    } else {
      this._buttonsDown[buttonIndex] = value;
    }

    this._buttons[buttonIndex] = value;
  }

  public function updateAxes(axesIndex: Int, value: Float) {
    this._axes[axesIndex] = value;
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
}

/**
 * Gamepad Buttons enumeration
 */
enum abstract Buttons(Int) from Int to Int {
  /**
   * Any button that isn't explicity known by excalibur
   */
  public static inline var Unknown       = -1;
  /**
   * Face 1 button (e.g. A)
   */
  public static inline var Face1         = 0;
  /**
   * Face 2 button (e.g. B)
   */
  public static inline var Face2         = 1;
  /**
   * Face 3 button (e.g. X)
   */
  public static inline var Face3         = 2;
  /**
   * Face 4 button (e.g. Y)
   */
  public static inline var Face4         = 3;
  /**
   * Left bumper button
   */
  public static inline var LeftBumper    = 4;
  /**
   * Right bumper button
   */
  public static inline var RightBumper   = 5;
  /**
   * Left trigger button
   */
  public static inline var LeftTrigger   = 6;
  /**
   * Right trigger button
   */
  public static inline var RightTrigger  = 7;
  /**
   * Select button
   */
  public static inline var Select        = 8;
  /**
   * Start button
   */
  public static inline var Start         = 9;
  /**
   * Left analog stick press (e.g. L3)
   */
  public static inline var LeftStick     = 10;
  /**
   * Right analog stick press (e.g. R3)
   */
  public static inline var RightStick    = 11;
  /**
   * D-pad up
   */
  public static inline var DpadUp        = 12;
  /**
   * D-pad down
   */
  public static inline var DpadDown      = 13;
  /**
   * D-pad left
   */
  public static inline var DpadLeft      = 14;
  /**
   * D-pad right
   */
  public static inline var DpadRight     = 15;
  /**
   * Center button (e.g. the Nintendo Home Button)
   */
  public static inline var CenterButton  = 16;
  /**
   * Misc button 1 (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button)
   * defacto standard not listed on the w3c spec for a standard gamepad https://w3c.github.io/gamepad/#dfn-standard-gamepad
   */
  public static inline var MiscButton1   = 17;
}

/**
 * Gamepad Axes enumeration
 */
enum abstract Axes(Int) from Int to Int {
  /**
   * Left analogue stick X direction
   */
  public static inline var LeftStickX    = 0;
  /**
   * Left analogue stick Y direction
   */
  public static inline var LeftStickY    = 1;
  /**
   * Right analogue stick X direction
   */
  public static inline var RightStickX   = 2;
  /**
   * Right analogue stick Y direction
   */
  public static inline var RightStickY   = 3;
}

/**
 * @internal
 */
interface NavigatorGamepads {
  function getGamepads(): Array<Null<NavigatorGamepad>>;
}

/**
 * @internal
 */
interface NavigatorGamepad {
  var axes: Array<Int>;
  var buttons: Array<NavigatorGamepadButton>;
  var connected: Bool;
  var id: String;
  var index: Int;
  var mapping: String;
  var timestamp: Int;
}

/**
 * @internal
 */
interface NavigatorGamepadButton {
  var pressed: Bool;
  var value: Float;
}

/**
 * @internal
 */
interface NavigatorGamepadEvent {
  var gamepad: NavigatorGamepad;
}

/**
 * @internal
 */
interface GamepadConfiguration {
  var axis: Int;
  var buttons: Int;
}
