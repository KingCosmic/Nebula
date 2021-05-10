package nebula.input;

import kha.input.Mouse;

/**
 * The MouseManager emits events to all our MousePointers in the games.
 * 
 * Pointers will not recieve events if their scene is paused or otherwise not active.
 */
class MouseManager {
	/**
	 * A boolean that controls if the Mouse Manager is enabled or not.
	 * Can be toggled on the fly.
	 */
	static public var enabled:Bool = false;

	/**
	 * If the mouse has been pointer locked successfully this will be set to true.
	 */
	static public var locked:Bool = false;

	/**
	 * update some flags and start our listeners.
	 */
	public function new() {
		enabled = true;

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
    // if we can't lock this mouse just return.
    if (!Mouse.get().canLock()) return;

    // lock the mouse.
		Mouse.get().lock();
	}

	/**
	 * If the browser supports pointer lock, this will request that the pointer lock is released. If
	 * the browser successfully enters a locked state, a 'POINTER_LOCK_CHANGE_EVENT' will be
	 * dispatched - from the game's input manager - with an `isPointerLocked` property.
	 */
	public function releasePointerLock() {
    // if we're not locked just return.
		if (!Mouse.get().isLocked()) return;

    // unlock the mouse.
    Mouse.get().unlock();
	}

	/**
	 * Starts the Mouse Event listeners running.
	 * This is called automatically and does not need to be manually invoked.
	 */
	public function startListeners() {
		Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
    Mouse.get().notifyOnLockChange(onLockChange, () -> {});
	}

  public function onLockChange() {
    locked = Mouse.get().isLocked();
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
}