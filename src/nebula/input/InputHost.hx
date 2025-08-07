package nebula.input;

import nebula.Engine;
import nebula.input.Gamepad;
import nebula.input.InputMapper;
import nebula.input.Keyboard;
import nebula.input.PointerEventReceiver;

interface InputHostOptions {
  var pointerTarget: Any;
  var grabWindowFocus: Bool;
  var global: Null<GlobalEventHandlers>;
  var engine: Engine;
}

class InputHost {
  private var _enabled = true;

  var keyboard: Keyboard;
  var pointers: PointerEventReceiver;
  var gamepads: Gamepads;
  var inputMapper: InputMapper;

  public function new(options: InputHostOptions) {
    final pointerTarget = options.pointerTarget,
          grabWindowFocus = options.grabWindowFocus,
          engine = options.engine,
          global = options.global;
    
    this.keyboard = new Keyboard();
    this.pointers = new PointerEventReceiver(pointerTarget, engine);
    this.gamepads = new Gamepads();

    this.keyboard.init({ global: global, grabWindowFocus: grabwindowFocus });
    this.pointers.init({ grabWindowFocus: grabWindowFocus });
    this.gamepads.init();
    this.inputMapper = new InputMapper({
      keyboard: this.keyboard,
      pointers: this.pointers,
      gamepads: this.gamepads
    });
  }

  public var enabled(get, never): Bool;
  function get_enabled() {
    return this._enabled;
  }

  function toggleEnabled(enabled: Bool) {
    this._enabled = enabled;
    this.keyboard.toggleEnabled(this._enabled);
    this.pointers.toggleEnabled(this._enabled);
    this.gamepads.toggleEnabled(this._enabled);
  }

  function update() {
    if (this._enabled) {
      this.inputMapper.execute();
      this.keyboard.update();
      this.gamepads.update();
    }
  }

  function clear() {
    this.keyboard.clear();
    this.pointers.clear();
    // this.gamepads.clear();
  }
}
