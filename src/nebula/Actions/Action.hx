package nebula.Actions;

import nebula.EntityComponentSystem.Entity;

/**
 * Used for implementing actions for the {@apilink ActionContext | `Action API`}.
 */
interface Action {
  id: Int;
  update(elapsed: Float): void;
  isComplete(entity: Entity): Bool;
  reset(): void;
  stop(): void;
}

var _ACTION_ID = 0;
/**
 *
 */
function nextActionId(): Int {
  return _ACTION_ID++;
}
