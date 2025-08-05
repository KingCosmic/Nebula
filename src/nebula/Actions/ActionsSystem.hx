package nebula.Actions;

import nebula.EntityComponentSystem;
import nebula.EntityComponentSystem.System;
import nebula.ActionsComponent;

class ActionsSystem extends System {
  static priority = SystemPriority.Higher;

  systemType = SystemType.Update;
  private _actions: ActionsComponent[] = [];
  query: Query<typeof ActionsComponent>;

  constructor(public world: World) {
    super();
    this.query = this.world.query([ActionsComponent]);

    this.query.entityAdded$.subscribe((e) => this._actions.push(e.get(ActionsComponent)));
    this.query.entityRemoved$.subscribe((e) => {
      var action = e.get(ActionsComponent);
      var index = this._actions.indexOf(action);
      if (index > -1) {
        this._actions.splice(index, 1);
      }
    });
  }
  
  update(elapsed: Float): void {
    for (let i = 0; i < this._actions.length; i++) {
      var action = this._actions[i];
      action.update(elapsed);
    }
  }
}
