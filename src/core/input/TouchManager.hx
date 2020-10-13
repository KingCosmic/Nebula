package core.input;

import kha.input.Surface;

/**
 * The Touch Manager is a helper class that belongs to the Input Manager.
 * 
 * Its role is to listen for native DOM Touch Events and then pass them onto the Input Manager for further processing.
 * 
 * You do not need to create this class directly, the Input Manager will create an instance of it automatically.
 */
class TouchManager {
  // A reference to the Input Manager.
  public var manager:InputManager;

  // A boolean that controls if the Touch Manager is enabled or not.
  // can be toggled on the fly
  public var enabled:Bool = false;

  public function new(_inputManager:InputManager) {
    manager = _inputManager;

    manager.events.once('MANAGER_BOOT', boot);
  }

  // The Touch Manager boot process.
  public function boot() {
    enabled = true;

    if (enabled) startListeners();
  }

  public function onTouchStart(id:Int, x:Int, y:Int) {
    if (enabled && manager != null && manager.enabled) {
      manager.onTouchStart(id, x, y);
    }
  }

  public function onTouchMove(id:Int, x:Int, y:Int) {
    if (enabled && manager != null && manager.enabled) {
      manager.onTouchMove(id, x, y);
    }
  }

  public function onTouchEnd(id:Int, x:Int, y:Int) {
		if (enabled && manager != null && manager.enabled) {
			manager.onTouchEnd(id, x, y);
		}
  }

  /**
   * Starts the Touch Event listeners running.
   * 
   * This method is called automatically if Touch Input is enabled in the game config,
   * which it is by default. However, you can call it manually should you need to
   * delay input capturing until later in the game.
   */
  public function startListeners() {
    Surface.get().notify(onTouchStart, onTouchEnd, onTouchMove);

    enabled = true;
  }

  /**
   * Stops the Touch Event listeners.
   * This is called automatically and does not need to be manually invoked.
   */
  public function stopListeners() {
    Surface.get().remove(onTouchStart, onTouchEnd, onTouchMove);

    enabled = false;
  }

  public function destroy() {
    stopListeners();

    manager = null;
  }
}