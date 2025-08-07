package nebula.actions;

import nebula.entitycomponentsystem.Entity;

/**
 * Used for implementing actions for the {@apilink ActionContext | `Action API`}.
 */
interface Action {
  var id: Int;
  function update(elapsed: Float): Void;
  function isComplete(entity: Entity): Bool;
  function reset(): Void;
  function stop(): Void;
}

var _ACTION_ID = 0;
/**
 *
 */
function nextActionId(): Int {
  return _ACTION_ID++;
}
