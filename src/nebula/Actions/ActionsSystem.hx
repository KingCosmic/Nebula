package nebula.actions;

import nebula.entitycomponentsystem.System;
import nebula.actions.ActionsComponent;

class ActionsSystem extends System {
  static var priority = SystemPriority.Higher;

  var systemType = SystemType.Update;
  private var _actions: Array<ActionsComponent> = [];
  var query: Query;

  public function new(world: World) {
    super();
    this.query = this.world.query([ActionsComponent]);

    this.query.entityAdded.subscribe((e) -> this._actions.push(e.get(ActionsComponent)));
    this.query.entityRemoved.subscribe((e) -> {
      var action = e.get(ActionsComponent);
      var index = this._actions.indexOf(action);
      if (index > -1) {
        this._actions.splice(index, 1);
      }
    });
  }
  
  function update(elapsed: Int): Void {
    for (i in 0...this._actions.length) {
      var action = this._actions[i];
      action.update(elapsed);
    }
  }
}
