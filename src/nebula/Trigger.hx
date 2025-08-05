package nebula;

import nebula.Events;
import nebula.Actor;
import nebula.EventEmitter;

interface ITriggerEvents extends ActorEvents {
  var exit: ExitTriggerEvent;
  var enter: EnterTriggerEvent;
}

final TriggerEvents = {
  ExitTrigger: 'exit',
  EnterTrigger: 'enter'
};

/**
 * TriggerOptions
 */
interface TriggerOptions {
  // position of the trigger
  var pos: Null<Vector>;
  // width of the trigger
  var width: Null<Int>;
  // height of the trigger
  var height: Null<Int>;
  // whether the trigger is visible or not
  var visible: Null<Bool>;
  // action to take when triggered
  var action: Null<(entity: Entity) -> Void>;
  // if specified the trigger will only fire on a specific entity and overrides any filter
  var target: Null<Entity>;
  // Returns true if the triggers should fire on the collided entity
  var filter: Null<(entity: Entity) -> Bool>;
  // -1 if it should repeat forever
  var repeat: Null<Int>;
}

/**
 * Triggers are a method of firing arbitrary code on collision. These are useful
 * as 'buttons', 'switches', or to trigger effects in a game. By default triggers
 * are invisible, and can only be seen when {@apilink Trigger.visible} is set to `true`.
 */
class Trigger extends Actor {
  public var events = new EventEmitter<ITriggerEvents & ActorEvents>();
  public var target: Null<Entity>;
  /**
   * Action to fire when triggered by collision
   */
  public function action(entity: Entity): Void;
  /**
   * Filter to add additional granularity to action dispatch, if a filter is specified the action will only fire when
   * filter return true for the collided entity.
   */
  public function filter(entity: Entity): Bool;
  /**
   * Number of times to repeat before killing the trigger,
   */
  public var repeat: Int;

  /**
   * @param options Trigger options
   */
  public function new(options: TriggerOptions & ActorArgs) {
    super(options);

    this.filter = options.filter ?? (() -> true);
    this.repeat = options.repeat ?? -1;
    this.action = options.action ?? (() -> undefined);
    this.target = options.target;

    this.graphics.isVisible = options.visible ?? false;
    this.body.collisionType = CollisionType.Passive;

    this.events.on('collisionstart', (event: CollisionStartEvent) -> {
      var collider = event.other;

      if (!this._matchesTarget(collider.owner)) {
        return;
      }

      this.events.emit('enter', new EnterTriggerEvent(this, collider.owner));
      this._dispatchAction(collider.owner);
      // remove trigger if its done, -1 repeat forever
      if (this.repeat == 0) {
        this.kill();
      }
    });

    this.events.on('collisionend', (event: CollisionEndEvent) -> {
      var collider = event.other;

      if (this._matchesTarget(collider.owner)) {
        this.events.emit('exit', new ExitTriggerEvent(this, collider.owner));
      }
    });
  }

  private function _matchesTarget(entity: Entity): Bool {
    return this.filter(entity) && (this.target == undefined || this.target == entity);
  }

  private function _dispatchAction(target: Entity) {
    if (this.repeat != 0) {
      this.action.call(this, target);
      this.repeat--;
    }
  }
}