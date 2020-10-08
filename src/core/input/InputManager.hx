package core.input;

import core.gameobjects.RenderableGameObject;
import core.input.keyboard.KeyboardManager;
import kha.math.Vector2;
import core.cameras.Camera;
import core.gameobjects.GameObject;
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
  public var keyboard:KeyboardManager = null;

  // A reference to the Mouse Manager class, if enabled via the `input.mouse` Game Config property.
  public var mouse:MouseManager = null;

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
  public var pointersTotal:Int = 2;

  /**
   * The mouse has its own unique Pointer object, which you can reference directly if making a _desktop specific game_.
   * If you are supporting both desktop and touch devices then do not use this property, instead use `activePointer`
   * which will always map to the most recently interacted pointer.
   */
  public var mousePointer:Pointer = null;

  /**
   * The most recently active Pointer object.
   *
   * If you've only 1 Pointer in your game then this will accurately be either the first finger touched, or the mouse.
   *
   * If your game doesn't need to support multi-touch then you can safely use this property in all of your game
   * code and it will adapt to be either the mouse or the touch, based on device.
   */
  public var activePointer:Pointer = null;

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
  public var _tempPoint = new Vector2();

  // A re-cycled array to store hit results in.
  public var _tempHitTest = [];

  // A re-cycled matrix used in hit test calculations.
  public var _tempMatrix = null;

  // An internal private var that records Scenes aborting event processing.
  public var _tempSkip:Bool = false;

  // An internal private array that avoids needing to create a new array on every DOM mouse event.
  public var mousePointerContainer:Array<Pointer> = [];

  public function new(_game:Game, _config:GameConfig) {
    game = _game;

    keyboard = new KeyboardManager(this);
    mouse = new MouseManager(this);
    // touch = new Touch(this);

    
    /*if (config.inputTouch && this.pointersTotal == 1) {
      this.pointersTotal = 2;
    }*/

    for (i in 0...pointersTotal) {
      var pointer = new Pointer(this, i);

      // TODO: pointer.smoothFactor = config.inputSmoothFactor;

      pointers.push(pointer);
    }

    mousePointer = pointers[0];
    mousePointerContainer = [ mousePointer ];

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
  public function updateInputPlugins(type:Int, pointers:Array<Pointer>) {
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
  /*
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

    updateInputPlugins(INPUT_CONST.TOUCH_START, changed);
  }*/

  /**
   * Processes a touch move event, as passed in by the TouchManager.
   */
  /*public function onTouchMove(event) {
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

    updateInputPlugins(INPUT_CONST.TOUCH_MOVE, changed);
  }*/

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
  public function onMouseDown(button:Int, x:Int, y:Int) {
    mousePointer.down(button, x, y);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_DOWN, mousePointerContainer);
  }

  /**
   * Processes a mouse move event, as passed in by the MouseManager.
   */
  public function onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
    mousePointer.move(x, y, moveX, moveY);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_MOVE, mousePointerContainer);
  }

  /**
   * Processes a mouse up event, as passed in by the MouseManager.
   */
  public function onMouseUp(button:Int, x:Int, y:Int) {
    mousePointer.up(button, x, y);

    mousePointer.updateMotion();

    activePointer = mousePointer;

    updateInputPlugins(INPUT_CONST.MOUSE_UP, mousePointerContainer);
  }

  /**
   * Processes a pointer lock change event, as passed in by the MouseManager.
   */
  public function onPointerLockChange(event) {
    /* TODO: 
    var isLocked:Bool = mouse.locked;

    mousePointer.locked = isLocked;

    events.emit('POINTERLOCK_CHANGE', event, isLocked);*/
  }

  /**
   * Checks if the given Game Object should be considered as a candidate for input or not.
   *
   * Checks if the Game Object has an input component that is enabled, that it will render,
   * and finally, if it has a parent, that the parent parent, or any ancestor, is visible or not.
   */
  public function isInputCandidate(gameObject:RenderableGameObject, camera:Camera) {
    var input = gameObject.input;

		if (input == null || !input.enabled || (!input.alwaysEnabled && !gameObject.willRender(camera))) {
      return false;
    }

    var visible = true;
    // var parent = gameObject.parentContainer;

    /*
      // TODO: add parent code
    */

    return visible;
  }

  /**
   * Performs a hit test using the given Pointer and camera, against an array of interactive Game Objects.
   *
   * The Game Objects are culled against the camera, and then the coordinates are translated into the local camera space
   * and used to determine if they fall within the remaining Game Objects hit areas or not.
   *
   * If nothing is matched an empty array is returned.
   *
   * This method is called automatically by InputPlugin.hitTestPointer and doesn't usually need to be invoked directly.
   */
	public function hitTest(pointer:Pointer, gameObjects:Array<RenderableGameObject>, camera:Camera, ?output:Array<RenderableGameObject>) {
    if (output == null) output = _tempHitTest;

    var csx = camera.scrollX;
    var csy = camera.scrollY;

    output = [];

    var x = pointer.x;
    var y = pointer.y;

    // Stores the world point inside of tempPoint
    camera.getWorldPoint(x, y, _tempPoint);

    pointer.worldX = _tempPoint.x;
    pointer.worldY = _tempPoint.y;

    var point = new Vector2();

    for (go in gameObjects) {
			// Checks if the Game Object can receive input (isn't being ignored by the camera, invisible, etc)
      // and also checks all of its parents, if any
      if (!isInputCandidate(go, camera))
        continue;

      var px = _tempPoint.x + (csx * go.scrollFactorX) - csx;
      var py = _tempPoint.y + (csy * go.scrollFactorY) - csy;

      // TODO: add in parentContainer code
      transformXY(px, py, go.x, go.y, go.rotation, go.scaleX, go.scaleY, point);
      
      if (isPointWithinHitArea(go, point.x, point.y)) {
        output.push(go);
      }
    }

    return output;
  }

	/**
   * Checks if the given x and y coordinate are within the hit area of the Game Object.
   *
   * This method assumes that the coordinate values have already been translated into the space of the Game Object.
   *
   * If the coordinates are within the hit area they are set into the Game Objects Input `localX` and `localY` properties.
   */
	public function isPointWithinHitArea(go:RenderableGameObject, x:Float, y:Float) {
    // Normalize the origin
    x += go.displayOriginX;
    y += go.displayOriginY;

    var input = go.input;

    if (input != null && input.hitAreaCallback(input.hitArea, x, y, go)) {
      input.localX = x;
      input.localY = y;

      return true;
    }

    return false;
  }

	/**
   * Checks if the given x and y coordinate are within the hit area of the Interactive Object.
   *
   * This method assumes that the coordinate values have already been translated into the space of the Interactive Object.
   *
   * If the coordinates are within the hit area they are set into the Interactive Objects Input `localX` and `localY` properties.
   */
  public function isPointWithinInteractiveObject(object:InteractiveObject, x:Float, y:Float) {
    if (object.hitArea == null) return false;

    // Normalize the origin
    x += object.gameObject.displayOriginX;
    y += object.gameObject.displayOriginY;

    object.localX = x;
    object.localY = y;

		return object.hitAreaCallback(object.hitArea, x, y, object.gameObject);
  }

	/**
	 * Transforms the pageX and pageY values of a Pointer into the scaled coordinate space of the Input Manager.
   */
  public function transformPointer(pointer:Pointer, pageX:Float, pageY:Float, wasMove:Bool) {
    var p0 = pointer.position;
    var p1 = pointer.prevPosition;

    // Store the previous position;
    p1.x = p0.x;
    p1.y = p0.y;

    // Translate coordinates
    var x = scaleManager.transformX(pageX);
    var y = scaleManager.transformY(pageY);

    var a = pointer.smoothFactor;

    if (!wasMove || a == 0) {
      // Set immediately
      p0.x = x;
      p0.y = y;
    } else {
      // Apply smoothing
      p0.x = x * a + p1.x * (1 - a);
      p0.y = y * a + p1.y * (1 - a);
    }
  }

  /**
   * Destroys the Input Manager and all of its systems.
   *
   * There is no way to recover from doing this.
   */
  public function destroy() {
    events.removeAllListeners();

    game.events.removeListener('PRE_RENDER', preRender);

    if (keyboard != null)
      keyboard.destroy();

    if (mouse != null)
      mouse.destroy();

    if (touch != null)
      touch.destroy();

    for (pointer in pointers) {
      pointer.destroy();
    }

    pointers = [];
    _tempHitTest = [];
    _tempMatrix.destroy();
    game = null;
  }

	/**
	 * Takes the `x` and `y` coordinates and transforms them into the same space as
	 * defined by the position, rotation and scale values.
	 */
	public function transformXY(x:Float, y:Float, posX:Float, posY:Float, rotation:Float, scaleX:Float, scaleY:Float, ?output:Vector2) {
    if (output == null) output = new Vector2();

    var radianSin = Math.sin(rotation);
    var radianCos = Math.cos(rotation);

    // Rotate and Scale
    var a = radianCos * scaleX;
    var b = radianSin * scaleX;
    var c = -radianSin * scaleY;
    var d = radianCos * scaleY;

    // Invert
    var id = 1 / ((a * d) + c * -b);

		output.x = (d * id * x) + (-c * id * y) + (((posY * c) - (posX * d)) * id);
		output.y = (a * id * y) + (-b * id * x) + (((-posY * a) + (posX * b)) * id);

		return output;
  }
}