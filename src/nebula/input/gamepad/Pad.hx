package nebula.input.gamepad;

import kha.input.Gamepad;
import nebula.input.gamepad.GamepadPlugin;
import kha.Scheduler;

/**
 * A single Gamepad.
 *
 * These are created, updated, and managed by the Gamepad Plugin.
 */
class Pad extends EventEmitter {
  /**
   * A reference to the Gamepad Plugin.
   */
	public var manager:GamepadPlugin;

  /**
   * The id of this pad.
   */
  public var id:String;

  /**
   * An integer that is unique for each Gamepad currently connected to the system.
   * This can be used to distinguish multiple controllers.
   * 
   * Note that disconnecting a device and then connecting a new
   * device may reuse the previous index.
   */
  public var index:Int;

  /**
   * The vendor of this Gamepad (PS4, Switch, etc).
   */
  public var vendor:String;

	/**
	 * A Joystick object containing the most recent values
	 * from the Gamepad's left axis stick.
	 *
	 * The H Axis is mapped to the `Joystick.x` property,
	 * and the V Axis to the `Joystick.y` property.
	 *
	 * The values are based on the Axis thresholds.
	 *
	 * If the Gamepad does not have a left axis stick, the values will always be zero.
	 */
  public var leftStick:Joystick;

  /**
   * A Joystick object containing the most recent values
   * from the Gamepad's right axis stick. 
   * 
   * The H Axis is mapped to the `Joystick.x` property,
   * and the V Axis to the `Joystick.y` property.
   * 
   * The values are based on the Axis thresholds.
   * 
   * If the Gamepad does not have a right axis stick, the values will always be zero.
   */
  public var rightStick:Joystick;

  /**
   * The buttons this pad has.
   */
  public var buttons:Map<Int, Button> = new Map();

  /**
	 * When was this Gamepad created? Used to avoid duplicate event spamming in the update loop.
   */
  public var createdAt:Float = Scheduler.realTime();

  /**
   * The native Gamepad object this Pad represents.
   */
  public var khapad:kha.input.Gamepad;

  public function new(_index:Int) {
    super();

    index = _index;
    khapad = Gamepad.get(index);
    vendor = khapad.vendor;
    id = khapad.id;

    // Let's create our axis values.
    leftStick = new Joystick(this);
    rightStick = new Joystick(this);

    // Now we create some buttons.
    for (i in 0...14) {
      var button = new Button(this, i);

      buttons.set(i, button);
    }

    startListeners();
  }

  /**
   * Start our event listeners so we know when this gamepad is updated.
   */
  public function startListeners() {
    khapad.notify(axisListener, buttonListener);
  }

  /**
   * Remove our listeners when the gamepad is disconnected.
   */
  public function removeListeners() {
    khapad.remove(axisListener, buttonListener);
  }

	/**
	 * Our Axis listener.
	 */
  public function axisListener(id:Int, value:Float) {

    // Modify our joysticks based on the axis id.
    switch (id) {
      case 0:
        leftStick.x = value;
      case 1:
        leftStick.y = value;
      case 2:
        // TODO: LEFT TRIGGER.
      case 3:
        rightStick.x = value;
      case 4:
        rightStick.y = value;
      case 5:
        // TODO: RIGHT TRIGGER.
    }

    // TODO: emit events.
  }
  
	/**
	 * Our Button listener.
	 */
	public function buttonListener(id:Int, value:Float) {

    // Switch based on our button id.
    switch (id) {
      case 0:
        trace('A');
      case 1:
        trace('B');
      case 2:
        trace('X');
      case 3:
        trace('Y');
      case 4:
        trace('LEFT BUMPER');
      case 5:
        trace('RIGHT BUMPER');
      case 6:
        trace('LEFT ANALOG PRESS');
      case 7:
        trace('RIGHT ANALOG PRESS');
      case 8:
        trace('START');
      case 9:
        trace('BACK');
      case 10:
        trace('HOME');
      case 11:
        trace('DPAD UP');
      case 12:
        trace('DPAD DOWN');
      case 13:
        trace('DPAD LEFT');
      case 14:
        trace('DPAD RIGHT');
    }
  }

  /**
   * Destroys this Gamepad instance, its buttons and axes, and releases external references it holds.
   */
  public function destroy() {
    // remove all event listeners.
    removeAllListeners();

    // remove our references.
    manager = null;

    // destroy our buttons
    for (button in buttons.iterator()) {
      button.destroy();
    }

    buttons.clear();
  }
}
