package nebula.actions.action;

import nebula.entitycomponentsystem.Entity;
import nebula.actions.ActionContext;
import nebula.actions.ActionQueue;

import nebula.actions.Action;

class Repeat implements Action {
  var id = nextActionId();
  private var _actionQueue: ActionQueue;
  private var _repeat: Float;
  private var _originalRepeat: Float;
  private var _stopped: Bool = false;
  private var _repeatContext: ActionContext;
  private var _repeatBuilder: (repeatContext: ActionContext) -> Any;
  public function new(entity: Entity, repeatBuilder: (repeatContext: ActionContext) -> Any, repeat: Int) {
    this._repeatBuilder = repeatBuilder;
    this._repeatContext = new ActionContext(entity);
    this._actionQueue = this._repeatContext.getQueue();

    this._repeat = repeat;
    this._originalRepeat = repeat;

    this._repeatBuilder(this._repeatContext);
    this._repeat--; // current execution is the first repeat
  }

  public function update(elapsed: Int) {
    if (this._actionQueue.isComplete()) {
      this._actionQueue.clearActions();
      this._repeatBuilder(this._repeatContext);
      this._repeat--;
    }
    this._actionQueue.update(elapsed);
  }

  public function isComplete(): Bool {
    return this._stopped || (this._repeat <= 0 && this._actionQueue.isComplete());
  }

  public function stop() {
    this._stopped = true;
  }

  public function reset() {
    this._repeat = this._originalRepeat;
  }
}
