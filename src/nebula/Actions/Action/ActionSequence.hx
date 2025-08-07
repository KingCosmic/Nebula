package nebula.actions.action;

import nebula.actions.ActionContext;
import nebula.actions.ActionQueue;

/**
 * Action that can represent a sequence of actions, this can be useful in conjunction with
 * {@apilink ParallelActions} to run multiple sequences in parallel.
 */
class ActionSequence implements Action {
  var id = nextActionId();
  private var _actionQueue: ActionQueue;
  private var _stopped: Bool = false;
  private var _sequenceContext: ActionContext;
  private var _sequenceBuilder: (actionContext: ActionContext) -> Any;
  public function new(entity: Entity, actionBuilder: (actionContext: ActionContext) -> Any) {
    this._sequenceBuilder = actionBuilder;
    this._sequenceContext = new ActionContext(entity);
    this._actionQueue = this._sequenceContext.getQueue();
    this._sequenceBuilder(this._sequenceContext);
  }

  public function update(elapsed: Float): void {
    this._actionQueue.update(elapsed);
  }

  public function isComplete(): Bool {
    return this._stopped || this._actionQueue.isComplete();
  }

  public function stop(): Void {
    this._stopped = true;
  }

  public function reset(): Void {
    this._stopped = false;
    this._actionQueue.reset();
  }

  public function clone(entity: Entity) {
    return new ActionSequence(entity, this._sequenceBuilder);
  }
}
