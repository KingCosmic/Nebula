package core.input;

import kha.Scheduler;
import core.math.Distance;
import kha.math.Vector2;
import core.cameras.Camera;

/**
 * @classdesc
 * A Pointer object encapsulates both mouse and touch input within Phaser.
 *
 * By default, Phaser will create 2 pointers for your game to use. If you require more, i.e. for a multi-touch
 * game, then use the `InputPlugin.addPointer` method to do so, rather than instantiating this class directly,
 * otherwise it won't be managed by the input system.
 *
 * You can reference the current active pointer via `InputPlugin.activePointer`. You can also use the properties
 * `InputPlugin.pointer1` through to `pointer10`, for each pointer you have enabled in your game.
 *
 * The properties of this object are set by the Input Plugin during processing. This object is then sent in all
 * input related events that the Input Plugin emits, so you can reference properties from it directly in your
 * callbacks.
 */
class Pointer {
  // A reference to the Input Manager.
  public var manager:InputManager;

  // The internal ID of this Pointer.
  public var id:Int;

  // The most recent native Event this Pointer has processed.
  public var event:Any;

  /**
   * The camera the Pointer interacted with during its last update.
   *
   * A Pointer can only ever interact with one camera at once, which will be the top-most camera
   * in the list should multiple cameras be positioned on-top of each other.
   */
  public var camera:Camera = null;

  /**
   * A read-only property that indicates which button was pressed, or released, on the pointer
   * during the most recent event. It is only set during `up` and `down` events.
   *
   * On Touch devices the value is always 0.
   *
   * Users may change the configuration of buttons on their pointing device so that if an event's button property
   * is zero, it may not have been caused by the button that is physically left–most on the pointing device;
   * however, it should behave as if the left button was clicked in the standard button layout.
   */
  public var button:Int = 0;

  /**
   * 0: No button or un-initialized
   * 1: Left button
   * 2: Right button
   * 4: Wheel button or middle button
   * 8: 4th button (typically the "Browser Back" button)
   * 16: 5th button (typically the "Browser Forward" button)
   *
   * For a mouse configured for left-handed use, the button actions are reversed.
   * In this case, the values are read from right to left.
   */
  public var buttons:Int = 0;

  // The position of the Pointer in screen space.
  public var position = new Vector2();

  /**
   * The previous position of the Pointer in screen space.
   *
   * The old x and y values are stored in here during the InputManager.transformPointer call.
   *
   * Use the properties `velocity`, `angle` and `distance` to create your own gesture recognition.
   */
  public var prevPosition = new Vector2();

	// An internal vector used for calculations of the pointer speed and angle.
  public var midPoint = new Vector2(-1, -1);

  /**
   * The current velocity of the Pointer, based on its current and previous positions.
   *
   * This value is smoothed out each frame, according to the `motionFactor` property.
   *
   * This property is updated whenever the Pointer moves, regardless of any button states. In other words,
   * it changes based on movement alone - a button doesn't have to be pressed first.
   */
  public var velocity = new Vector2();

  /**
   * The current angle the Pointer is moving, in radians, based on its previous and current position.
   *
   * The angle is based on the old position facing to the current position.
   *
   * This property is updated whenever the Pointer moves, regardless of any button states. In other words,
   * it changes based on movement alone - a button doesn't have to be pressed first.
   */
  public var angle:Float = 0;

  /**
   * The distance the Pointer has moved, based on its previous and current position.
   *
   * This value is smoothed out each frame, according to the `motionFactor` property.
   *
   * This property is updated whenever the Pointer moves, regardless of any button states. In other words,
   * it changes based on movement alone - a button doesn't have to be pressed first.
   *
   * If you need the total distance travelled since the primary buttons was pressed down,
   * then use the `Pointer.getDistance` method.
   */
  public var distance:Float = 0;

  /**
   * The smoothing factor to apply to the Pointer position.
   *
   * Due to their nature, pointer positions are inherently noisy. While this is fine for lots of games, if you need cleaner positions
   * then you can set this value to apply an automatic smoothing to the positions as they are recorded.
   *
   * The default value of zero means 'no smoothing'.
   * Set to a small value, such as 0.2, to apply an average level of smoothing between positions. You can do this by changing this
   * value directly, or by setting the `input.smoothFactor` property in the Game Config.
   *
   * Positions are only smoothed when the pointer moves. If the primary button on this Pointer enters an Up or Down state, then the position
   * is always precise, and not smoothed.
   */
  public var smoothFactor:Float = 0;

  /**
   * The factor applied to the motion smoothing each frame.
   *
   * This value is passed to the Smooth Step Interpolation that is used to calculate the velocity,
   * angle and distance of the Pointer. It's applied every frame, until the midPoint reaches the current
   * position of the Pointer. 0.2 provides a good average but can be increased if you need a
   * quicker update and are working in a high performance environment. Never set this value to
   * zero.
   */
  public var motionFactor:Float = 0.2;

  /**
   * The x position of this Pointer, translated into the coordinate space of the most recent Camera it interacted with.
   *
   * If you wish to use this value _outside_ of an input event handler then you should update it first by calling
   * the `Pointer.updateWorldPoint` method.
   */
  public var worldX:Float = 0;

  /**
   * The y position of this Pointer, translated into the coordinate space of the most recent Camera it interacted with.
   *
   * If you wish to use this value _outside_ of an input event handler then you should update it first by calling
   * the `Pointer.updateWorldPoint` method.
   */
  public var worldY:Float = 0;

  /**
   * Time when this Pointer was most recently moved (regardless of the state of its buttons, if any)
   */
  public var moveTime:Float = 0;

  // X coordinate of the Pointer when Button 1 (left button), or Touch, was pressed, used for dragging objects.
  public var downX:Float = 0;

	// Y coordinate of the Pointer when Button 1 (left button), or Touch, was pressed, used for dragging objects.
  public var downY:Float = 0;

  // The Event timestamp when the first button, or Touch input, was pressed. Used for dragging objects.
  public var downTime:Float = 0;

  // X coordinate of the Pointer when Button 1 (left button), or Touch, was released, used for dragging objects.
  public var upX:Float = 0;

  // Y coordinate of the Pointer when Button 1 (left button), or Touch, was released, used for dragging objects.
  public var upY:Float = 0;

  // The Event timestamp when the final button, or Touch input, was released. Used for dragging objects.
  public var upTime:Float = 0;

  // Is the primary button down? (usually button 0, the left mouse button)
  public var primaryDown:Bool = false;

  // Is _any_ button on this pointer considered as being down?
  public var isDown:Bool = false;

  // Did the previous input event come from a Touch input (true) or Mouse? (false)
  public var wasTouch:Bool = false;

  /**
   * Did this Pointer get canceled by a touchcancel event?
   *
   * Note: "canceled" is the American-English spelling of "cancelled". Please don't submit PRs correcting it!
   */
  public var wasCanceled:Bool = false;

  // If the mouse is locked, the horizontal relative movement of the Pointer in pixels since last frame.
  public var movementX:Float = 0;

  // If the mouse is locked, the vertical relative movement of the Pointer in pixels since last frame.
  public var movementY:Float = 0;

  // The identifier property of the Pointer as set by the DOM event when this Pointer is started.
  public var identifier:Float = 0;

  /**
   * The pointerId property of the Pointer as set by the DOM event when this Pointer is started.
   * The browser can and will recycle this value.
   */
  public var pointerId:Float = null;

  /**
   * An active Pointer is one that is currently pressed down on the display.
   * A Mouse is always considered as active.
   */
  public var active:Bool = false;

  /**
   * Is this pointer Pointer Locked?
   *
   * Only a mouse pointer can be locked and it only becomes locked when requested via
   * the browsers Pointer Lock API.
   *
   * You can request this by calling the `this.input.mouse.requestPointerLock()` method from
   * a `pointerdown` or `pointerup` event handler.
   */
  public var isLocked:Bool = false;

  /**
   * The vertical scroll amount that occurred due to the user moving a mouse wheel or similar input device.
   * This value will typically be less than 0 if the user scrolls up and greater than zero if scrolling down.
   */
  public var delta:Int = 0;

  public function new(_manager:InputManager, _id:Int) {
    manager = _manager;
    id = _id;

    active = (id == 0) ? true : false;
  }

  /**
   * Takes a Camera and updates this Pointer's `worldX` and `worldY` values so they are
   * the result of a translation through the given Camera.
   *
   * Note that the values will be automatically replaced the moment the Pointer is
   * updated by an input event, such as a mouse move, so should be used immediately.
   */
  public function updateWorldPoint(camera:Camera) {
    // Stores the world point inside of the tempPoint
    var temp = camera.getWorldPoint(x, y);

    worldX = temp.x;
    worldY = temp.y;

    return this;
  }

  /**
   * Takes a Camera and returns a Vector2 containing the translated position of this Pointer
   * within that Camera. This can be used to convert this Pointers position into camera space.
   */
  public function positionToCamera(camera:Camera, ?output:Vector2) {
    return camera.getWorldPoint(x, y, output);
  }

  /**
   * Calculates the motion of this Pointer, including its velocity and angle of movement.
   * This method is called automatically each frame by the Input Manager.
   */
  public function updateMotion() {
    var cx = position.x;
    var cy = position.y;

    var mx = midPoint.x;
    var my = midPoint.y;

    // Nothing to do here.
    if (cx == mx && cy == my) return;

    // Moving towards our goal...
    var vx = smoothStepInterpolation(motionFactor, mx, cx);
    var vy = smoothStepInterpolation(motionFactor, mx, cx);

    if (Math.abs(vx - cx) < 0.1) vx = cx;
    
    if (Math.abs(vy - cy) < 0.1) vy = cy;
    
    midPoint.x = vx;
    midPoint.y = vy;

    var dx = cx - vx;
    var dy = cy - vy;

    velocity.x = dx;
    velocity.y = dy;

		angle = Math.atan2(cy - vy, cx - vx);
    distance = Math.sqrt(dx * dx + dy * dy);
  }

  // Internal method to handle a Mouse Up Event.
  public function up(_button:Int, x:Int, y:Int) {
    // TODO: buttons

    button = _button;

    // Sets the local x/y properties
    manager.transformPointer(this, x, y, false);

		// 0: Main button pressed, usually the left button or the un-initialized state
    if (button == 0) {
      primaryDown = false;
      upX = x;
      upY = y;
    }

    if (buttons == 0) {
      // No more buttons are still down
      isDown = false;

      upTime = Scheduler.realTime();

      wasTouch = false;
    }
  }

  // Internal method to handle a Mouse Down Event.
  public function down(_button:Int, x:Int, y:Int) {
    // TODO: Buttons

    button = _button;

    // Sets the local x/y properties
    manager.transformPointer(this, x, y, false);

    // 0: Main button pressed, usually the left button or the un-initialized state
    if (button == 0) {
      primaryDown = true;
      downX = x;
      downY = y;
    }

    #if kha_mac
      if (event.ctrlKey) {
        // Override button settings on macOs
        buttons = 2;
        primaryDown = false;
      }
    #end

    if (!isDown) {
      isDown = true;
      downTime = Scheduler.realTime();
    }

    wasTouch = false;
  }

  // Internal method to handle a Mouse Move Event
  public function move(x:Int, y:Int, moveX:Int, moveY:Int) {
    // TODO: Buttons

    // Sets teh local x/y properties
    manager.transformPointer(this, x, y, true);

    if (isLocked) {
      movementX = moveX | 0;
      movementY = moveY | 0;
    }

    moveTime = Scheduler.realTime();

    wasTouch = false;
  }

  // Internal method to handle a Mouse Wheel Event.
  public function wheel(_delta:Int) {
    // TODO: Buttons

    // Sets the local x/y properties
    manager.transformPointer(this, x, y, false);

    delta = _delta;

    wasTouch = false;
  }

  // Internal method to handle a Touch Start Event.
  public function touchStart() {
    // TODO:
  }

  // Internal method to handle a Touch Move Event.
  public function touchMove() {
    // TODO:
  }

  // Internal method to handle a Touch End Event.
  public function touchEnd() {
    // TODO:
  }

  // Internal method to handle a Touch Cancel Event.
  public function touchCancel() {
    // TODO:
  }

  /**
   * Checks to see if any buttons are being held down on this Pointer.
   */
  public function isNoButtonDown() {
    return (buttons == 0);
  }

	/**
   * Checks to see if the left button is being held down on this Pointer.
   */
  public function isLeftButtonDown() {
    return ((buttons & 1) == 1) ? true : false;
  }

	/**
	 * Checks to see if the right button is being held down on this Pointer.
   */
  public function isRightButtonDown() {
    return ((buttons & 2) == 2) ? true : false;
  }

	/**
	 * Checks to see if the middle button is being held down on this Pointer.
   */
  public function isMiddleButtonDown() {
    return ((buttons & 4) == 4) ? true : false;
  }

	/**
	 * Checks to see if the back button is being held down on this Pointer.
   */
  public function isBackButtonDown() {
    return ((buttons & 8) == 8) ? true : false;
  }

	/**
	 * Checks to see if the forward button is being held down on this Pointer.
   */
  public function isForwardButtonDown() {
    return ((buttons & 16) == 16) ? true : false;
  }

	/**
   * Checks to see if the left button was just released on this Pointer.
   */
  public function isLeftButtonReleased() {
    return (button == 0 && !isDown);
  }

	/**
	 * Checks to see if the right button was just released on this Pointer.
   */
  public function isRightButtonReleased() {
    return (button == 2 && !isDown);
  }

  /**
   * Checks to see if the middle button was just released on this Pointer.
   */
  public function isMiddleButtonReleased() {
    return (button == 1 && !isDown);
  }

	/**
	 * Checks to see if the back button was just released on this Pointer.
   */
  public function isBackButtonReleased() {
    return (button == 3 && !isDown);
  }

	/**
	 * Checks to see if the forward button was just released on this Pointer.
   */
  public function isForwardButtonReleased() {
    return (button == 4 && !isDown);
  }

	/**
	 * If the Pointer has a button pressed down at the time this method is called, it will return the
	 * distance between the Pointer's `downX` and `downY` values and the current position.
	 *
	 * If no button is held down, it will return the last recorded distance, based on where
	 * the Pointer was when the button was released.
	 *
	 * If you wish to get the distance being travelled currently, based on the velocity of the Pointer,
	 * then see the `Pointer.distance` property.
   */
  public function getDistance() {
    if (isDown) {
      return Distance.distanceBetween(downX, downY, x, y);
    } else {
      return Distance.distanceBetween(downX, downY, upX, upY);
    }
  }

  /**
   * If the Pointer has a button pressed down at the time this method is called, it will return the
   * horizontal distance between the Pointer's `downX` and `downY` values and the current position.
   *
   * If no button is held down, it will return the last recorded horizontal distance, based on where
   * the Pointer was when the button was released.
   */
  public function getDistanceX() {
    if (isDown) {
      return Math.abs(downX - x);
    } else {
      return Math.abs(downX - upX);
    }
  }

  /**
   * If the Pointer has a button pressed down at the time this method is called, it will return the
   * vertical distance between the Pointer's `downX` and `downY` values and the current position.
   *
   * If no button is held down, it will return the last recorded vertical distance, based on where
   * the Pointer was when the button was released.
   */
  public function getDistanceY() {
    if (isDown) {
      return Math.abs(downY - y);
    } else {
      return Math.abs(downY - upY);
    }
  }

	/**
   * If the Pointer has a button pressed down at the time this method is called, it will return the
   * duration since the button was pressed down.
   *
   * If no button is held down, it will return the last recorded duration, based on the time
   * the last button on the Pointer was released.
   */
  public function getDuration() {
    if (isDown) {
      return (manager.time - downTime);
    } else {
      return (upTime - downTime);
    }
  }

	/**
	 * If the Pointer has a button pressed down at the time this method is called, it will return the
	 * angle between the Pointer's `downX` and `downY` values and the current position.
	 *
	 * If no button is held down, it will return the last recorded angle, based on where
	 * the Pointer was when the button was released.
	 *
	 * The angle is based on the old position facing to the current position.
	 *
	 * If you wish to get the current angle, based on the velocity of the Pointer, then
	 * see the `Pointer.angle` property.
   */
  public function getAngle() {
    if (isDown) {
			return Math.atan2(y - downY, x - downX);
    } else {
			return Math.atan2(upY - downY, x - upX);
    }
  }

	/**
	 * Destroys this Pointer instance and resets its external references.
   */
  public function destroy() {
    camera = null;
    manager = null;
    position = null;
  }

	/**
	 * The x position of this Pointer.
	 * The value is in screen space.
	 * See `worldX` to get a camera converted position.
   */
  public var x(get, set):Float;

  function get_x() {
    return position.x;
  }

  function set_x(value:Float) {
    position.x = value;

    return value;
  }

	/**
	 * The y position of this Pointer.
	 * The value is in screen space.
	 * See `worldY` to get a camera converted position.
   */
  public var y(get, set):Float;

  function get_y() {
    return position.y;
  }

  function set_y(value:Float) {
    position.y = value;

    return position.y;
  }

	/**
	 * Time when this Pointer was most recently updated by a DOM Event.
	 * This comes directly from the `event.timeStamp` property.
	 * If no event has yet taken place, it will return zero.
   */
  public var time(get, null):Float;

  function get_time() {
    return (event != null) ? Scheduler.realTime() : 0;
  }

  // TODO: Remove for math helpers (all functions below this comment)

  /**
   * Calculate a smooth interpolation percentage of `x` between `min` and `max`.
   *
   * The function receives the number `x` as an argument and returns 0 if `x` is less than or equal to the left edge,
   * 1 if `x` is greater than or equal to the right edge, and smoothly interpolates, using a Hermite polynomial,
   * between 0 and 1 otherwise.
   */
  public function smoothStep(x:Float, min:Float, max:Float):Float {
    if (x <= min) return 0;

    if (x >= max) return 1;

    x = (x - min) / (max - min);

    return x * x * (3 - 2 * x);
  }

	// A Smooth Step interpolation method.
  public function smoothStepInterpolation(t:Float, min:Float, max:Float) {
    return min + (max - min) * smoothStep(t, 0, 1);
  }
}