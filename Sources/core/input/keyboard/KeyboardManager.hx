package core.input.keyboard;

import kha.Scheduler;
import kha.input.KeyCode;
import kha.input.Keyboard;

typedef KeyEvent = {
	type:String,
	timeStamp:Float,
	code:KeyCode
} 

/**
 * The Keyboard Manager is a helper class that belongs to the global Input Manager.
 *
 * Its role is to listen for native DOM Keyboard Events and then store them for further processing by the Keyboard Plugin.
 *
 * You do not need to create this class directly, the Input Manager will create an instance of it automatically if keyboard
 * input has been enabled in the Game Config.
 */
class KeyboardManager {
  // A reference to the Input Manager.
  public var manager:InputManager;

  // An internal event queue.
	public var queue:Array<KeyEvent> = [];

  /**
   * An array of Key Code values
   *
   * By default the array is empty.
   *
   * The key must be non-modified when pressed in order to be captured.
   *
   * A non-modified key is one that doesn't have a modifier key held down with it. The modifier keys are
   * shift, control, alt and the meta key (Command on a Mac, the Windows Key on Windows).
   * Therefore, if the user presses shift + r, it won't prevent this combination, because of the modifier.
   * However, if the user presses just the r key on its own, it will have its event prevented.
   *
   * If you wish to stop capturing the keys, for example switching out to a DOM based element, then
   * you can toggle the `KeyboardManager.preventDefault` boolean at run-time.
   *
   * If you need more specific control, you can create Key objects and set the flag on each of those instead.
   *
   * This array can be populated via the Game Config by setting the `input.keyboard.capture` array, or you
   * can call the `addCapture` method. See also `removeCapture` and `clearCaptures`.
   */
  public var captures:Array<Int> = [];

  /**
   * A boolean that controls if the Keyboard Manager is enabled or not.
   * Can be toggled on the fly.
   */
  public var enabled:Bool = true;

  public function new(_manager:InputManager) {
    manager = _manager;

    manager.events.once('MANAGER_BOOT', boot);
  }

  /**
   * The Keyboard Manager boot process.
   */
  public function boot() {
    // enabled = config.inputKeyboard;

    if (enabled)
      startListeners();

    manager.game.events.on('POST_STEP', postUpdate);
  }

  /**
   * Starts the Keyboard Event listeners running.
   * This is called automatically and does not need to be manually invoked.
   */
  public function startListeners() {
    Keyboard.get().notify(onKeyDown, onKeyUp);

    enabled = true;
  }

  public function onKeyDown(code:KeyCode) {
    // Do nothing if we're not supposed to.
    if (!enabled || manager == null) return;

    queue.push({
      type: 'keydown',
      timeStamp: Scheduler.realTime(),
      code: code
    });

    manager.events.emit('MANAGER_PROCESS');
  }

	public function onKeyUp(code:KeyCode) {
    // Do nothing if we're not supposed to.
    if (!enabled || manager == null) return;

		queue.push({
			type: 'keyup',
			timeStamp: Scheduler.realTime(),
			code: code
		});

    manager.events.emit('MANAGER_PROCESS');
  }

  /**
   * Stops the Key Event listeners.
   * This is called automatically and does not need to be manually invoked.
   */
  public function stopListeners() {
    // TODO: get rid of the events.

    enabled = false;
  }

  /**
   * Clears the event queue.
   * Called automatically by the Input Manager.
   */
  public function postUpdate() {
    queue = [];
  }

  /**
   * Destroys this Keyboard Manager instance.
   */
  public function destroy() {
    stopListeners();

    queue = [];

    manager.game.events.removeListener('POST_RENDER', postUpdate);

    enabled = false;
    manager = null;
  }
}