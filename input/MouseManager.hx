package core.input;

import kha.input.Mouse;

/**
 * The Mouse Manager is a helper class that belongs to the Input Manager.
 *
 * Its role is to listen for native Mouse Events and then pass them onto the Input Manager for further processing.
 *
 * You do not need to create this class directly, the Input Manager will create an instance of it automatically.
 */
class MouseManager {
  // A reference to the Input Manager.
  public var manager:InputManager;

  // If `true` the DOM `mousedown` event will have `preventDefault` set.
  public var preventDefaultDown:Bool = true;

  // If `true` the DOM `mouseup` event will have `preventDefault` set.
  public var preventDefaultUp:Bool = true;

	// If `true` the DOM `mousemove` event will have `preventDefault` set.
  public var preventDefaultMove:Bool = true;

  /**
   * A boolean that controls if the Mouse Manager is enabled or not.
   * Can be toggled on the fly.
   */
  public var enabled:Bool = false;

  public var passive:Bool = false;

  // If the mouse has been pointer locked successfully this will be set to true.
  public var locked:Bool = false;

  public function new(_manager:InputManager) {
    manager = _manager;

    manager.events.once('MANAGER_BOOT', boot);
  }

  /**
   * The Touch Manager boot process.
   */
  public function boot() {
    var config = manager.config;

    enabled = true;
    passive = true;
    
    startListeners();
  }

  /**
   * If the browser supports it, you can request that the pointer be locked to the browser window.
   *
   * This is classically known as 'FPS controls', where the pointer can't leave the browser until
   * the user presses an exit key.
   *
   * If the browser successfully enters a locked state, a `POINTER_LOCK_CHANGE_EVENT` will be dispatched,
   * from the games Input Manager, with an `isPointerLocked` property.
   *
   * It is important to note that pointer lock can only be enabled after an 'engagement gesture',
   * see: https://w3c.github.io/pointerlock/#dfn-engagement-gesture.
   *
   * Note for Firefox: There is a bug in certain Firefox releases that cause native DOM events like
   * `mousemove` to fire continuously when in pointer lock mode. You can get around this by setting
   * `this.preventDefaultMove` to `false` in this class. You may also need to do the same for
   * `preventDefaultDown` and/or `preventDefaultUp`. Please test combinations of these if you encounter
   * the error.
   */
  public function requestPointerLock() {
    // TODO:
  }

  /**
   * If the browser supports pointer lock, this will request that the pointer lock is released. If
   * the browser successfully enters a locked state, a 'POINTER_LOCK_CHANGE_EVENT' will be
   * dispatched - from the game's input manager - with an `isPointerLocked` property.
   */
  public function releasePointerLock() {
    // TODO:
  }

  /**
   * Starts the Mouse Event listeners running.
   * This is called automatically and does not need to be manually invoked.
   */
  public function startListeners() {
    Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, onMouseWheel, onMouseLeave);
  }

  public function onMouseDown(button:Int, x:Int, y:Int) {
    manager.onMouseDown(button, x, y);
  }

  public function onMouseUp(button:Int, x:Int, y:Int) {
    manager.onMouseUp(button, x, y);
  }

  public function onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
    manager.onMouseMove(x, y, moveX, moveY);
  }

  public function onMouseWheel(delta:Int) {
    // manager.onMouseWheel(delta);
  }

  public function onMouseLeave() {

  }

  // Destroys this Mouse Manager instance.
  public function destroy() {
    // TODO: stopListeners
    enabled = false;
    manager = null;
  }
}