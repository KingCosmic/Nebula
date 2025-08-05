package nebula.Actions.Action;

import nebula.EntityComponentSystem.Entity;
import nebula.Actions.Action;
import nebula.Actions.ActionsComponent;

class Die implements Action {
  id = nextActionId();
  private _entity: Entity;
  private _stopped = false;

  constructor(entity: Entity) {
    this._entity = entity;
  }

  public update(elapsed: Float) {
    this._entity.get(ActionsComponent).clearActions();
    this._entity.kill();
    this._stopped = true;
  }

  public isComplete(): Bool {
    return this._stopped;
  }

  public stop() {
    return;
  }

  public reset() {
    return;
  }
}
