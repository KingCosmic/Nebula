package nebula.input.gamepad;

import nebula.scene.Scene;

/**
 * The Gamepad Plugin is an input plugin that belongs to the Scene-owned Input system.
 *
 * Its role is to listen for native DOM Gamepad Events and then process them.
 *
 * To listen for a gamepad being connected:
 *
 * ```haxe
 * gamepad.once('connected', (pad) -> {
 *  // 'pad' is a reference to the gamepad that was just connected
 * });
 * ```
 *
 * Note that the browser may require you to press a button on a gamepad before it will allow you to access it,
 * this is for security reasons. However, it may also trust the page already, in which case you won't get the
 * 'connected' event and instead should check `GamepadPlugin.total` to see if it thinks there are any gamepads
 * already connected.
 *
 * Once you have received the connected event, or polled the gamepads and found them enabled, you can access
 * them via the built-in properties `GamepadPlugin.pad1` to `pad4`, for up to 4 game pads. With a reference
 * to the gamepads you can poll its buttons and axis sticks. See the properties and methods available on
 * the `Gamepad` class for more details.
 */
class GamepadPlugin extends EventEmitter {
  // A reference to the Scene that this Input Plugin is responsible for.
  public var scene:Scene;

  // A boolean that controls if the Gamepad Plugin is enabled or not.
  // Can be toggled on the fly.
  public var enabled:Bool;

  // A map of the connected Gamepads.
  public var gamepads:Map<Int, Pad> = new Map();

  /* internal Pad references */
  public var pad1(get, null):Pad;

  function get_pad1() {
    return gamepads.get(0);
  }

	public var pad2(get, null):Pad;

	function get_pad2() {
		return gamepads.get(1);
  }
  
	public var pad3(get, null):Pad;

	function get_pad3() {
		return gamepads.get(2);
  }
  
	public var pad4(get, null):Pad;

	function get_pad4() {
		return gamepads.get(3);
	}

  public function new(_scene:Scene, ?_enabled:Bool = true) {
    super();

    scene = _scene;
    enabled = _enabled;

    scene.events.once('DESTROY', destroy);

    start();
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    if (enabled) {
      startListeners();
    }

    // Go ahead and create 4 Pad objects for our usage.
    for (i in 0...3) {
			// Make our Pad object that holds all of the current info.
			var pad = new Pad(i);

			// add it to our internal list.
			gamepads.set(i, pad);
    }

    scene.events.on('SHUTDOWN', shutdown);
  }

  // Checks to see if both this plugin and the Scene to which is belongs
  // is active.
  public function isActive() {
    return (enabled && scene.sys.isActive());
  }

  // Starts the Gamepad Event listeners running.
  // This is called automatically and does not need to be manually invoked.
	public function startListeners() {
    kha.input.Gamepad.notifyOnConnect(onGamepadConnected, onGamepadDisconnected);
  }

  // Stops the Gamepad listeners.
  // This is called automatically and does not need to be manually invoked.
  public function stopListeners() {
		kha.input.Gamepad.removeConnect(onGamepadConnected, onGamepadDisconnected);

    for (pad in gamepads) {
      pad.removeAllListeners();
    }
  }

  /**
   * A new Gamepad is connected! let's setup our stuff for it.
   */
  public function onGamepadConnected(index:Int) {
    // Make our Pad object that holds all of the current info.
		var pad = new Pad(index);

    // add it to our internal list.
		gamepads.set(index, pad);

    // emit that we got a new Gamepad!
    emit('GAMEPAD_CONNECTED', pad);
  }

  /**
   * A Gamepad was disconnected, remove it from our internal list.
   */
  public function onGamepadDisconnected(index:Int) {
    var pad = gamepads.get(index);

    pad.destroy();

    gamepads.remove(index);

    emit('GAMEPAD_DISCONNECTED', pad);
  }

  /**
   * A new Gamepad is connected!
   */

  /**
   * Returns a map of the currently connected Gamepads
   * 
   * This is not a copy, mutating this will effect the plugin.
   */
  public function getAll() {
    return gamepads;
  }

  /**
   * Looks-up a single Gamepad based on the given index value.
   */
  public function getPad(index:Int) {
    return gamepads.get(index);
  }

  /**
   * Shuts the Gamepad Plugin down.
   * All this does is remove any listeners bound to it.
   */
  public function shutdown() {
    // stop our listeners.
    stopListeners();

    // remove any listeners listening to our events.
    removeAllListeners();
  }

  /**
   * Destroys this Gamepad Plugin, disconnecting all Gamepads
   * and releasing internal references.
   */
  public function destroy() {
    shutdown();

    for (pad in gamepads.iterator()) {
      pad.destroy();
    }

    gamepads.clear();

    scene = null;
  }

  public var total(get, null):Int;

  function get_total() {
    var total = 0;

    for (pad in gamepads.iterator()) {
      total++;
    }

    return total;
  }
}