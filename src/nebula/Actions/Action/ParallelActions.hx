package nebula.Actions.Action;

import nebula.EntityComponentSystem;
import nebula.Actions.Action;

/**
 * Action that can run multiple {@apilink Action}s or {@apilink ActionSequence}s at the same time
 */
class ParallelActions implements Action {
  id = nextActionId();
  private _actions: Action[];

  constructor(parallelActions: Action[]) {
    this._actions = parallelActions;
  }

  update(elapsed: Float) {
    for (let i = 0; i < this._actions.length; i++) {
      this._actions[i].update(elapsed);
    }
  }
  isComplete(entity: Entity): Bool {
    return this._actions.every((a) => a.isComplete(entity));
  }
  reset() {
    this._actions.forEach((a) => a.reset());
  }
  stop() {
    this._actions.forEach((a) => a.stop());
  }
}
