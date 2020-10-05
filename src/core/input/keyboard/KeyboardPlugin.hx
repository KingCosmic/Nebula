package core.input.keyboard;

import kha.input.KeyCode;
import kha.Scheduler;
import js.html.KeyboardEvent;
import core.scene.Settings;
import core.scene.Scene;

/**
 * The Keyboard Plugin is an input plugin that belongs to the Scene-owned Input system.
 *
 * Its role is to listen for native DOM Keyboard Events and then process them.
 *
 * You do not need to create this class directly, the Input system will create an instance of it automatically.
 *
 * You can access it from within a Scene using `this.input.keyboard`. For example, you can do:
 *
 * ```javascript
 * this.input.keyboard.on('keydown', callback, context);
 * ```
 *
 * Or, to listen for a specific key:
 *
 * ```javascript
 * this.input.keyboard.on('keydown-A', callback, context);
 * ```
 *
 * You can also create Key objects, which you can then poll in your game loop:
 *
 * ```javascript
 * var spaceBar = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
 * ```
 *
 * If you have multiple parallel Scenes, each trying to get keyboard input, be sure to disable capture on them to stop them from
 * stealing input from another Scene in the list. You can do this with `this.input.keyboard.enabled = false` within the
 * Scene to stop all input, or `this.input.keyboard.preventDefault = false` to stop a Scene halting input on another Scene.
 *
 * _Note_: Many keyboards are unable to process certain combinations of keys due to hardware limitations known as ghosting.
 * See http://www.html5gamedevs.com/topic/4876-impossible-to-use-more-than-2-keyboard-input-buttons-at-the-same-time/ for more details.
 *
 * Also please be aware that certain browser extensions can disable or override Phaser keyboard handling.
 * For example the Chrome extension vimium is known to disable Phaser from using the D key, while EverNote disables the backtick key.
 * And there are others. So, please check your extensions before opening Phaser issues about keys that don't work.
 */
class KeyboardPlugin extends EventEmitter {
  // A refernece to the core game, so we can listen for visibility events.
  public var game:Game;

  // A refernece to the Scene that this Input Plugin si responsible for.
  public var scene:Scene;

  // A reference to the Scene Systems Settings.
  public var settings:Settings;

  // A reference to the Scene Input Plugin that created this Keyboard Plugin.
  public var sceneInputPlugin:InputPlugin;

  // A reference to the global Keyboard Manager.
  public var manager:KeyboardManager;

  /**
   * A boolean that controls if this Keyboard Plugin is enabled or not.
   * Can be toggled on the fly.
   */
  public var enabled:Bool = true;

  // An array of Key objects to process.
  public var keys:Array<Key> = [];

  // An array of KeyCombo objects to process.
  public var combos:Array<Any> = [];

  // Internal repeat key flag.
  public var prevCode:KeyCode;

  // Internal repeat key flag.
  public var prevTime:Float = 0;

  public function new(inputPlugin:InputPlugin) {
    super();

    game = inputPlugin.systems.game;
    scene = inputPlugin.scene;
    settings = scene.sys.settings;
    sceneInputPlugin = inputPlugin;
    manager = inputPlugin.manager.keyboard;

    inputPlugin.pluginEvents.once('BOOT', boot);
    inputPlugin.pluginEvents.on('START', start);
  }

	/**
	 * This method is called automatically, only once, when the Scene is first created.
	 * Do not invoke it directly.
   */
  public function boot() {
    // TODO:

    sceneInputPlugin.pluginEvents.once('DESTROY', destroy);
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    sceneInputPlugin.manager.events.on('MANAGER_PROCESS', update);

    sceneInputPlugin.pluginEvents.once('SHUTDOWN', shutdown);

    game.events.on('BLUR', resetKeys);

    scene.sys.events.on('PAUSE', resetKeys);
    scene.sys.events.on('SLEEP', resetKeys);
  }

  /**
   * Checks to see if both this plugin and the Scene to which it belongs is active.
   */
  public function isActive() {
    return (enabled && scene.sys.isActive());
  }

  /**
   * A practical way to create an object containing user selected hotkeys.
   *
   * For example:
   *
   * ```javascript
   * this.input.keyboard.addKeys({ 'up': Phaser.Input.Keyboard.KeyCodes.W, 'down': Phaser.Input.Keyboard.KeyCodes.S });
   * ```
   *
   * would return an object containing the properties (`up` and `down`) mapped to W and S {@link Phaser.Input.Keyboard.Key} objects.
   *
   * You can also pass in a comma-separated string:
   *
   * ```javascript
   * this.input.keyboard.addKeys('W,S,A,D');
   * ```
   *
   * Which will return an object with the properties W, S, A and D mapped to the relevant Key objects.
   *
   * To use non-alpha numeric keys, use a string, such as 'UP', 'SPACE' or 'LEFT'.
   */
  public function addKeys(_keys:String, ?emitOnRepeat:Bool = false) {

    var splitKeys = _keys.split(',');

    var output = {};

    for (key in splitKeys) {
      if (key != '') {
        Reflect.setProperty(output, key, addKey(key, emitOnRepeat));
      }
    }

    return output;
  }

  /**
   * Adds a Key object to this Keyboard Plugin.
   *
   * The given argument can be either an existing Key object, a string, such as `A` or `SPACE`, or a key code value.
   *
   * If a Key object is given, and one already exists matching the same key code, the existing one is replaced with the new one.
   */
  public function addKey(key:String, ?emitOnRepeat:Bool = false) {
    var keyCode:Int = Reflect.getProperty(KeyCodes, key.toUpperCase());

		if (keys[keyCode] == null) {
			keys[keyCode] = new Key(this, keyCode);

			keys[keyCode].setEmitOnRepeat(emitOnRepeat);
    }

		return keys[keyCode];
  }

  /**
   * Removes a Key object from this Keyboard Plugin.
   *
   * The given argument can be either a Key object, a string, such as `A` or `SPACE`, or a key code value.
   */
  public function removeKey(code:String, ?destroy:Bool = false) {

    var keyCode:Int = Reflect.getProperty(KeyCodes, code);
    var ref:Key = null;

    if (keys[keyCode] != null) {
      ref = keys[keyCode];

      keys[keyCode] = null;
    }

    if (ref != null) {
      ref.plugin = null;

      if (destroy) ref.destroy();
    }

    return this;
  }

  /**
   * Removes all Key objects created by _this_ Keyboard Plugin.
   */
  public function removeAllKeys(?destroy:Bool = false) {
    for (i in 0...keys.length) {
      var key = keys[i];

      if (key != null) {
        keys[i] = null;

        if (destroy) key.destroy();
      }
    }

    return this;
  }

  /**
   * Checks if the given Key object is currently being held down.
   *
   * The difference between this method and checking the `Key.isDown` property directly is that you can provide
   * a duration to this method. For example, if you wanted a key press to fire a bullet, but you only wanted
   * it to be able to fire every 100ms, then you can call this method with a `duration` of 100 and it
   * will only return `true` every 100ms.
   *
   * If the Keyboard Plugin has been disabled, this method will always return `false`.
   */
  public function checkDown(key:Key, ?duration:Float = 0) {
    if (!enabled && !key.isDown) return false;

    // TODO: HIGH_PRIO add in code for duration check.

    return true;
  }

  /**
   * Internal update handler called by the Input Plugin, which is in turn invoked by the Game step.
   */
  public function update() {
    if (!isActive() || manager.queue.length == 0) return;

		// Process the event queue, dispatching all of the events that have stored up
    for (event in manager.queue) {
      
      var code = event.code;
      var key = keys[code];
      var repeat = false;

      prevCode = code;
      prevTime = event.timeStamp;

      if (event.type == 'keydown') {
        // is our key event still around
        if (key != null) {
          repeat = key.isDown;

          key.onDown(event);
        }

        if (key == null || !repeat) {
          // TODO: make key events work.
        }
      } else {
        // Key specific callback first
        if (key != null) {
          key.onUp(event);
        }

        // TODO: make key events work.
      }
    }
  }

  /**
   * Resets all Key objects created by _this_ Keyboard Plugin back to their default un-pressed states.
   * This can only reset keys created via the `addKey`, `addKeys` or `createCursorKeys` methods.
   * If you have created a Key object directly you'll need to reset it yourself.
   *
   * This method is called automatically when the Keyboard Plugin shuts down, but can be
   * invoked directly at any time you require.
   */
  public function resetKeys() {
    for (key in keys) {
      // Because it's a sparsely populated array
      if (key == null) continue;

      key.reset();
    }

    return this;
  }

  /**
   * Shuts this Keyboard Plugin down. This performs the following tasks:
   *
   * 1 - Resets all keys created by this Keyboard plugin.
   * 2 - Stops and removes the keyboard event listeners.
   * 3 - Clears out any pending requests in the queue, without processing them.
   */
  public function shutdown() {
    resetKeys();

    sceneInputPlugin.manager.events.removeListener('MANAGER_PROCESS', update);
    
    game.events.removeListener('BLUR', resetKeys);

    scene.sys.events.removeListener('PAUSE', resetKeys);
    scene.sys.events.removeListener('SLEEP', resetKeys);

    removeAllListeners();
  }

  /**
   * Destroys this Keyboard Plugin instance and all references it holds, plus clears out local arrays.
   */
  public function destroy() {
    shutdown();

    removeAllKeys(true);

    keys = [];
    combos = [];

    scene = null;
    settings = null;
    sceneInputPlugin = null;
    manager = null;
  }

  // Internal time value
  public var time(get, null):Float;

  function get_time() {
    return sceneInputPlugin.manager.time;
  }
}