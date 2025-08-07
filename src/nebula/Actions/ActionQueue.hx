package nebula.actions;

import nebula.Events;
import nebula.entitycomponentsystem.Entity;
import nebula.actions.Action;

/**
 * Action Queues represent an ordered sequence of actions
 *
 * Action queues are part of the {@apilink ActionContext | `Action API`} and
 * store the list of actions to be executed for an {@apilink Actor}.
 *
 * Actors implement {@apilink Actor.actions} which can be manipulated by
 * advanced users to adjust the actions currently being executed in the
 * queue.
 */
class ActionQueue {
  private var _entity: Entity;
  private var _actions: Array<Action> = [];
  private var _currentAction: Null<Action> = null;
  private var _completedActions: Array<Action> = [];
  public function new(entity: Entity) {
    this._entity = entity;
  }

  /**
   * Add an action to the sequence
   * @param action
   */
  public function add(action: Action) {
    this._actions.push(action);
  }

  /**
   * Remove an action by reference from the sequence
   * @param action
   */
  public function remove(action: Action) {
    final index = this._actions.indexOf(action);
    this._actions.splice(index, 1);
  }

  /**
   * Removes all actions from this sequence
   */
  public function clearActions(): Void {
    this._actions.length = 0;
    this._completedActions.length = 0;
    if (this._currentAction) {
      this._currentAction.stop();
    }
  }

  /**
   *
   * @returns The total list of actions in this sequence complete or not
   */
  public function getActions(): Array<Action> {
    return this._actions.concat(this._completedActions);
  }

  public function getIncompleteActions(): Array<Action> {
    return this._actions;
  }

  public function getCurrentAction(): Null<Action> {
    return this._currentAction;
  }

  /**
   *
   * @returns `true` if there are more actions to process in the sequence
   */
  public function hasNext(): Bool {
    return this._actions.length > 0;
  }

  /**
   * @returns `true` if the current sequence of actions is done
   */
  public function isComplete(): Bool {
    return this._actions.length == 0;
  }

  /**
   * Resets the sequence of actions, this is used to restart a sequence from the beginning
   */
  public function reset(): Void {
    this._actions = this.getActions();

    for (action in this._actions) {
      this._actions[i].reset();
    }
    this._completedActions = [];
  }

  /**
   * Update the queue which updates actions and handles completing actions
   * @param elapsed
   */
  public function update(elapsed: Int) {
    if (this._actions.length > 0) {
      if (this._currentAction != this._actions[0]) {
        this._currentAction = this._actions[0];
        this._entity.emit('actionstart', new ActionStartEvent(this._currentAction, this._entity));
      }

      this._currentAction.update(elapsed);

      if (this._currentAction.isComplete(this._entity)) {
        this._entity.emit('actioncomplete', new ActionCompleteEvent(this._currentAction, this._entity));
        final complete = this._actions.shift();
        if (complete) {
          this._completedActions.push(complete);
        }
      }
    }
  }
}
