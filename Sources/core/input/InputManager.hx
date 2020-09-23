package core.input;

import js.html.PointerEvent;
import core.Game.GameConfig;
import core.scale.ScaleManager;

/**
 * The Input Manager is responsible for handling the pointer related systems in a single Phaser Game instance.
 *
 * Based on the Game Config it will create handlers for mouse and touch support.
 *
 * Keyboard and Gamepad are plugins, handled directly by the InputPlugin class.
 *
 * It then manages the events, pointer creation and general hit test related operations.
 *
 * You rarely need to interact with the Input Manager directly, and as such, all of its properties and methods
 * should be considered private. Instead, you should use the Input Plugin, which is a Scene level system, responsible
 * for dealing with all input events for a Scene.
 */
class InputManager {
  /**
   * The Game instance that owns the Input Manager.
   * A Game only maintains on instance of the Input Manager at any time.
   */
  public var game:Game;

  /**
   * A reference to the global Game Scale Manager.
   * Used for all bounds checks and pointer scaling.
   */
  public var scaleManager:ScaleManager;

  // The Game Configuration object, as set during the game boot.
  public var config:GameConfig;

  // If set, the Input Manager will run it's update loop every frame.
  public var enabled:Bool = true;

  // The Event Emitter instance that the Input Manager uses to emit events from.
  public var events:EventEmitter = new EventEmitter();

  /**
   * Are any mouse or touch pointers currently over the game canvas?
   * This is updated automatically by the canvas over and out handlers.
   */
  public var isOver:Bool = true;

  // A reference to the Keyboard Manager class, if enabled via the `input.keyboard` Game Config property.
  public var keyboard = null;

  // A reference to the Mouse Manager class, if enabled via the `input.mouse` Game Config property.
  public var mouse = null;

  // A reference to the Touch Manager class, if enabled via the `input.touch` Game Config property.
  public var touch = null;

  /**
   * An array of Pointers that have been added to the game.
   * The first entry is reserved for the Mouse Pointer, the rest are Touch Pointers.
   *
   * By default there is 1 touch pointer enabled. If you need more use the `addPointer` method to start them,
   * or set the `input.activePointers` property in the Game Config.
   */
  public var pointers = [];

  /**
   * The number of touch objects activated and being processed each update.
   *
   * You can change this by either calling `addPointer` at run-time, or by
   * setting the `input.activePointers` property in the Game Config.
   */
  public var pointersTotal:Int = 0;

  /**
   * The mouse has its own unique Pointer object, which you can reference directly if making a _desktop specific game_.
   * If you are supporting both desktop and touch devices then do not use this property, instead use `activePointer`
   * which will always map to the most recently interacted pointer.
   */
  public var mousePointer = null;

  /**
   * The most recently active Pointer object.
   *
   * If you've only 1 Pointer in your game then this will accurately be either the first finger touched, or the mouse.
   *
   * If your game doesn't need to support multi-touch then you can safely use this property in all of your game
   * code and it will adapt to be either the mouse or the touch, based on device.
   */
  public var activePointer = null;

  /**
   * If the top-most Scene in the Scene List receives an input it will stop input from
   * propagating any lower down the scene list, i.e. if you have a UI Scene at the top
   * and click something on it, that click will not then be passed down to any other
   * Scene below. Disable this to have input events passed through all Scenes, all the time.
   */
  public var globalTopOnly:Bool = true;

  /**
   * The time this Input Manager was last updated.
   * This value is populated by the Game Step each frame.
   */
  public var time:Float = 0;

  // A re-cycled point-like object to store hit test values in.
  public var _tempPoint = { x:0, y: 0 };

  // A re-cycled array to store hit results in.
  public var _tempHitTest = [];

  // A re-cycled matrix used in hit test calculations.
  public var _tempMatrix = null;

  // A re-cycled matrix used in hit test calculations.
  public var _tempMatrix2 = null;

  // An internal private var that records Scenes aborting event processing.
  public var _tempSkip:Bool = false;

  // An internal private array that avoids needing to create a new array on every DOM mouse event.
  public var mousePointerContainer = [];

  public function new(_game:Game) {
    game = _game;

    // keyboard = new Keyboard(this);
    // mouse = new Mouse(this);
    // touch = new Touch(this);

    /*
			if (config.inputTouch && this.pointersTotal === 1)
				{
					this.pointersTotal = 2;
				}

				for (var i = 0; i <= this.pointersTotal; i++)
				{
					var pointer = new Pointer(this, i);

					pointer.smoothFactor = config.inputSmoothFactor;

					this.pointers.push(pointer);
				}
    */

    game.events.once('BOOT', boot);
  }

  /**
   * The Boot handler is called by Phaser.Game when it first starts up.
   * The renderer is available by now.
   */
  public function boot() {
    scaleManager = game.scale;

    events.emit('MANAGER_BOOT');

    game.events.on('PRE_RENDER', preRender);

    game.events.once('DESTROY', destroy);
  }

  // Internal canvas state change, called automatically by the Mouse Manager.
  public function setCanvasOver() {
    isOver = true;

    events.emit('GAME_OVER');
  }

  // Internal canvas state change, called automatically by the Mouse Manager.
  public function setCanvasOut() {
    isOver = false;

    events.emit('GAME_OUT');
  }

  // Internal update, called automatically by the Game Step right at the start.
  public function preRender() {
    var _time = game.loop.now;
    var delta = game.loop.delta;
    var scenes = game.scene.getScenes(true, true);

    time = _time;

    events.emit('MANAGER_UPDATE');

    for (scene in scenes) {
			if (scene.sys.input != null && scene.sys.input.updatePoll(time, delta) && globalTopOnly) {
				// If the Scene returns true, it means it captured some input that no other Scene should get, so we bail out
        return;
      }
    }
  }

  /**
   * Adds new Pointer objects to the Input Manager.
   *
   * By default Phaser creates 2 pointer objects: `mousePointer` and `pointer1`.
   *
   * You can create more either by calling this method, or by setting the `input.activePointers` property
   * in the Game Config, up to a maximum of 10 pointers.
   *
   * The first 10 pointers are available via the `InputPlugin.pointerX` properties, once they have been added
   * via this method.
   */
  public function addPointer(quantity:Int = 1) {
    var output = [];

    if (pointersTotal + quantity > 10) {
      quantity = 10 - pointersTotal;
    }

    for (i in 0...quantity) {
      var id = pointers.length;

      var pointer = new Pointer(this, id);

      pointers.push(pointer);

      pointersTotal++;

      output.push(pointer);
    }

    return output;
  }

  /**
   * Internal method that gets a list of all the active Input Plugins in the game
   * and updates each of them in turn, in reverse order (top to bottom), to allow
   * for DOM top-level event handling simulation.
   */
  public function updateInputPlugins(type:Int, pointers:Array<Any>) {
    var scenes = game.scene.getScenes(true, true);

    _tempSkip = false;

    for (scene in scenes) {

      if (scene.sys.input != null) {
        var capture = scene.sys.input.update(type, pointers);

        if ((capture != null && globalTopOnly) || _tempSkip) {
					// If the Scene returns true, or called stopPropagation, it means it captured some input that no other Scene should get, so we bail out
					return;
        }
      }
    }
  }

  // Processes a touch start event, as passed in by the TouchManager.
  public function onTouchStart(event:Any) {
    var changed = [];

    for (changedTouch in event.changedTouches) {

      for (i in 1...pointersTotal) {
        var pointer = pointers[i];

        if (!pointer.active) {
          pointer.touchStart(changedTouch, event);

          activePointer = pointer;

          changed.push(pointer);

          break;
        }
      }
    }

    updateInputPlugins(TOUCH_CONST.START, changed);
  }

  /**
   * Processes a touch move event, as passed in by the TouchManager.
   */
  public function onTouchMove(event) {
    var changed = [];

    for (changedTouch in event.changedTouches) {

      for (i in 1...pointersTotal) {
        var pointer = pointers[i];

        if (pointer.active && pointer.identifier == changedTouch.identifier) {
          pointer.touchMove(changedTouch, event);

          activePointer = pointer;

          changed.push(pointer);

          break;
        }
      }
    }

    updateInputPlugins(TOUCH_CONST.TOUCH_MOVE, changed);
  }

  /**
   * Processes a touch end event, as passed in by the TouchManager.
   */
  public function onTouchEnd(event) {
    // TODO:
  }

  /**
   * Processes a touch cancel event, as passed in by the TouchManager.
   */
  public function onTouchCancel(event) {
    // TODO:
  }

  /**
   * Processes a mouse down event, as passed in by the MouseManager.
   */
  public function onMouseDown(event) {
    mousePointer.down(event);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_DOWN, mousePointerContainer);
  }

  /**
   * Processes a mouse move event, as passed in by the MouseManager.
   */
  public function onMouseMove(event) {
    mousePointer.move(event);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_MOVE, mousePointerContainer);
  }

  /**
   * Processes a mouse up event, as passed in by the MouseManager.
   */
  public function onMouseUp(event) {
    mousePointer.up(event);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_UP, mousePointerContainer);
  }

  /**
   * Processes a pointer lock change event, as passed in by the MouseManager.
   */
  public function onPointerLockChange(event) {
    var isLocked:Bool = mouse.locked;

    mousePointer.locked = isLocked;

    events.emit('POINTERLOCK_CHANGE', event, isLocked);
  }


}