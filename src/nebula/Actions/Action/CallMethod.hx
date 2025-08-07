package nebula.actions.action;

import nebula.actions.Action;

class CallMethod implements Action {
  var id = nextActionId();
  private var _method: () -> Any;
  private var _hasBeenCalled: Bool = false;
  public function new(method: () -> Any) {
    this._method = method;
  }

  public function update(elapsed: Int) {
    this._method();
    this._hasBeenCalled = true;
  }
  public function isComplete() {
    return this._hasBeenCalled;
  }
  public function reset() {
    this._hasBeenCalled = false;
  }
  public function stop() {
    this._hasBeenCalled = true;
  }
}
