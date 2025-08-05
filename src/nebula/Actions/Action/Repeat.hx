package nebula.Actions.Action;

import nebula.EntityComponentSystem.Entity;
import nebula.Actions.ActionContext;
import nebula.Actions.ActionQueue;

import nebula.Actions.Action;

class Repeat implements Action {
  id = nextActionId();
  private _actionQueue: ActionQueue;
  private _repeat: Float;
  private _originalRepeat: Float;
  private _stopped: Bool = false;
  private _repeatContext: ActionContext;
  private _repeatBuilder: (repeatContext: ActionContext) => any;
  constructor(entity: Entity, repeatBuilder: (repeatContext: ActionContext) => any, repeat: Int) {
    this._repeatBuilder = repeatBuilder;
    this._repeatContext = new ActionContext(entity);
    this._actionQueue = this._repeatContext.getQueue();

    this._repeat = repeat;
    this._originalRepeat = repeat;

    this._repeatBuilder(this._repeatContext);
    this._repeat--; // current execution is the first repeat
  }

  public update(elapsed: Float) {
    if (this._actionQueue.isComplete()) {
      this._actionQueue.clearActions();
      this._repeatBuilder(this._repeatContext);
      this._repeat--;
    }
    this._actionQueue.update(elapsed);
  }

  public isComplete(): Bool {
    return this._stopped || (this._repeat <= 0 && this._actionQueue.isComplete());
  }

  public stop() {
    this._stopped = true;
  }

  public reset() {
    this._repeat = this._originalRepeat;
  }
}
