package nebula.actions.action;

import nebula.entitycomponentsystem.Entity;

import nebula.actions.ActionContext;
import nebula.actions.ActionQueue;

import nebula.actions.Action;

/**
 * RepeatForever Action implementation, it is recommended you use the fluent action
 * context API.
 */
class RepeatForever implements Action {
  var id = nextActionId();
  private var _actionQueue: ActionQueue;
  private var _stopped: Bool = false;
  private var _repeatContext: ActionContext;
  private var _repeatBuilder: (repeatContext: ActionContext) -> Any;
  public function new(entity: Entity, repeatBuilder: (repeatContext: ActionContext) -> Any) {
    this._repeatBuilder = repeatBuilder;
    this._repeatContext = new ActionContext(entity);
    this._actionQueue = this._repeatContext.getQueue();

    this._repeatBuilder(this._repeatContext);
  }

  public function update(elapsed: Int) {
    if (this._stopped) {
      return;
    }

    if (this._actionQueue.isComplete()) {
      this._actionQueue.clearActions();
      this._repeatBuilder(this._repeatContext);
    }

    this._actionQueue.update(elapsed);
  }

  public function isComplete(): Bool {
    return this._stopped;
  }

  public function stop() {
    this._stopped = true;
    this._actionQueue.clearActions();
  }

  public function reset() {
    return;
  }
}
