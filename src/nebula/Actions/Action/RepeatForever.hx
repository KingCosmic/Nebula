package nebula.Actions.Action;

import nebula.EntityComponentSystem.Entity;

import nebula.Actions.ActionContext;
import nebula.Actions.ActionQueue;

import nebula.Actions.Action;

/**
 * RepeatForever Action implementation, it is recommended you use the fluent action
 * context API.
 */
class RepeatForever implements Action {
  id = nextActionId();
  private _actionQueue: ActionQueue;
  private _stopped: boolean = false;
  private _repeatContext: ActionContext;
  private _repeatBuilder: (repeatContext: ActionContext) => any;
  public function new(entity: Entity, repeatBuilder: (repeatContext: ActionContext) => any) {
    this._repeatBuilder = repeatBuilder;
    this._repeatContext = new ActionContext(entity);
    this._actionQueue = this._repeatContext.getQueue();

    this._repeatBuilder(this._repeatContext);
  }

  public update(elapsed: Float) {
    if (this._stopped) {
      return;
    }

    if (this._actionQueue.isComplete()) {
      this._actionQueue.clearActions();
      this._repeatBuilder(this._repeatContext);
    }

    this._actionQueue.update(elapsed);
  }

  public isComplete(): Bool {
    return this._stopped;
  }

  public stop() {
    this._stopped = true;
    this._actionQueue.clearActions();
  }

  public reset() {
    return;
  }
}
