package nebula.Actions.Action;

import nebula.Actions.Action;

class CallMethod implements Action {
  id = nextActionId();
  private _method: () => any;
  private _hasBeenCalled: Bool = false;
  constructor(method: () => any) {
    this._method = method;
  }

  public update(elapsed: Float) {
    this._method();
    this._hasBeenCalled = true;
  }
  public isComplete() {
    return this._hasBeenCalled;
  }
  public reset() {
    this._hasBeenCalled = false;
  }
  public stop() {
    this._hasBeenCalled = true;
  }
}
