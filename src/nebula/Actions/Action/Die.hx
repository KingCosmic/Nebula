package nebula.actions.action;

import nebula.entitycomponentsystem.Entity;
import nebula.actions.Action;
import nebula.actions.ActionsComponent;

class Die implements Action {
  var id = nextActionId();
  private var _entity: Entity;
  private var _stopped = false;

  public function new(entity: Entity) {
    this._entity = entity;
  }

  public function update(elapsed: Int) {
    this._entity.get(ActionsComponent).clearActions();
    this._entity.kill();
    this._stopped = true;
  }

  public function isComplete(): Bool {
    return this._stopped;
  }

  public function stop() {
    return;
  }

  public function reset() {
    return;
  }
}
