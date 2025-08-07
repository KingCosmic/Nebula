package nebula.actions.action;

import nebula.actions.Action;

/**
 * Action that can run multiple {@apilink Action}s or {@apilink ActionSequence}s at the same time
 */
class ParallelActions implements Action {
  var id = nextActionId();
  private var _actions: Array<Action>;

  public function new(parallelActions: Array<Action>) {
    this._actions = parallelActions;
  }

  function update(elapsed: Int) {
    for (action in this._actions) {
      action.update(elapsed);
    }
  }
  function isComplete(entity: Entity): Bool {
    return this._actions.every((a) -> a.isComplete(entity));
  }
  function reset() {
    this._actions.forEach((a) -> a.reset());
  }
  function stop() {
    this._actions.forEach((a) -> a.stop());
  }
}
