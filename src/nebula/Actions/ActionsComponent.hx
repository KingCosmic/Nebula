package nebula.actions;

import nebula.actions.ActionContext;
import nebula.entitycomponentsystem.Component;
import nebula.entitycomponentsystem.Entity;
import nebula.Actor;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.util.EasingFunctions;
import nebula.actions.ActionQueue;
import nebula.actions.Action;
import nebula.Color;
import nebula.actions.action.CurveTo;
import nebula.actions.action.CurveBy;
import nebula.actions.action.MoveTo;

class ActionsComponent extends Component implements ActionContextMethods {
  var dependencies = [TransformComponent, MotionComponent];
  private var _ctx: Null<ActionContext> = null;

  function onAdd(entity: Entity) {
    this._ctx = new ActionContext(entity);
  }

  function onRemove() {
    this._ctx = null;
  }

  private function _getCtx() {
    if (!this._ctx) {
      throw new Error('Actions component not attached to an entity, no context available');
    }
    return this._ctx;
  }

  /**
   * Returns the internal action queue
   * @returns action queue
   */
  public function getQueue(): ActionQueue {
    if (!this._ctx) {
      throw new Error('Actions component not attached to an entity, no queue available');
    }
    return this._ctx.getQueue();
  }

  /**
   * Runs a specific action in the action queue
   * @param action
   */
  public function runAction(action: Action): ActionContext {
    if (!this._ctx) {
      throw new Error('Actions component not attached to an entity, cannot run action');
    }
    return this._ctx.runAction(action);
  }

  /**
   * Updates the internal action context, performing action and moving through the internal queue
   * @param elapsed
   */
  public function update(elapsed: Float): Void {
    return this._ctx.update(elapsed);
  }

  /**
   * Clears all queued actions from the Actor
   */
  public function clearActions(): Void {
    this._ctx.clearActions();
  }

  /**
   * Animates an actor with a specified bezier curve by an offset to the current position, the start point is assumed
   * to be the actors current position
   * @param options
   */
  public function curveBy(options: CurveByOptions): ActionContext {
    return this._getCtx().curveBy.apply(this._ctx, [options]);
  }

  /**
   * Animates an actor with a specified bezier curve to an absolute world space coordinate, the start point is assumed
   * to be the actors current position
   * @param options
   */
  public function curveTo(options: CurveToOptions): ActionContext {
    return this._getCtx().curveTo.apply(this._ctx, [options]);
  }

  /**
   * This method will move an actor to the specified `x` and `y` position over the
   * specified duration using a given {@apilink EasingFunctions} and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param x         The x location to move the actor to
   * @param y         The y location to move the actor to
   * @param duration  The time it should take the actor to move to the new location in milliseconds
   * @param easingFcn Use {@apilink EasingFunctions} or a custom function to use to calculate position, Default is {@apilink EasingFunctions.Linear}
   * @deprecated use new moveTo({pos: Vector, duration: number, easing: EasingFunction})
   */
  public function easeTo(...args: Array<Any>): ActionContext {
    return this._getCtx().easeTo.apply(this._ctx, args);
  }

  public function easeBy(...args: Array<Any>): ActionContext {
    return this._getCtx().easeBy.apply(this._ctx, args);
  }

  /**
   * This method will move an actor to the specified x and y position at the
   * speed specified (in pixels per second) and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param pos      The x location to move the actor to
   * @param speed  The speed in pixels per second to move
   */
  public function moveTo(posOrOptions: Vector, ?speed: Int): ActionContext {
    return this._getCtx().moveTo.apply(this._ctx, [posOrOptions, speed]);
  }

  /**
   * This method will move an actor by the specified x offset and y offset from its current position, at a certain speed.
   * This method is part of the actor 'Action' fluent API allowing action chaining.
   * @param xOffset     The x offset to apply to this actor
   * @param yOffset     The y location to move the actor to
   * @param speed  The speed in pixels per second the actor should move
   */
  public function moveBy(
    vector: Vector,
    speed: Null<Float>
  ): ActionContext {
    return this._getCtx().moveBy.apply(this._ctx, [vector, speed]);
  }

  /**
   * This method will rotate an actor to the specified angle at the speed
   * specified (in radians per second) and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param angle  The angle to rotate to in radians
   * @param speed         The angular velocity of the rotation specified in radians per second
   * @param rotationType  The {@apilink RotationType} to use for this rotation
   */
  public function rotateTo(angle: Float, ?speed: Float, ?rotationType: RotationType): ActionContext {
    return this._getCtx().rotateTo.apply(this._ctx, [angle, speed, rotationType]);
  }

  /**
   * This method will rotate an actor by the specified angle offset, from it's current rotation given a certain speed
   * in radians/sec and return back the actor. This method is part
   * of the actor 'Action' fluent API allowing action chaining.
   * @param angleRadiansOffset  The angle to rotate to in radians relative to the current rotation
   * @param speed          The speed in radians/sec the actor should rotate at
   * @param rotationType  The {@apilink RotationType} to use for this rotation, default is shortest path
   */
  public function rotateBy(angleRadiansOffset: Float, ?speed: Float, ?rotationType: RotationType): ActionContext {
    return this._getCtx().rotateBy.apply(this._ctx, [angleRadiansOffset, speed, rotationType]);
  }

  /**
   * This method will scale an actor to the specified size at the speed
   * specified (in magnitude increase per second) and return back the
   * actor. This method is part of the actor 'Action' fluent API allowing
   * action chaining.
   * @param sizeX   The scaling factor to apply on X axis
   * @param sizeY   The scaling factor to apply on Y axis
   * @param speedX  The speed of scaling specified in magnitude increase per second on X axis
   * @param speedY  The speed of scaling specified in magnitude increase per second on Y axis
   */
  public function scaleTo(
    vector: Vector,
    ?speed: Vector
  ): ActionContext {
    return this._getCtx().scaleTo.apply(this._ctx, [vector, speed]);
  }

  /**
   * This method will scale an actor by an amount relative to the current scale at a certain speed in scale units/sec
   * and return back the actor. This method is part of the
   * actor 'Action' fluent API allowing action chaining.
   * @param sizeOffsetX   The scaling factor to apply on X axis
   * @param sizeOffsetY   The scaling factor to apply on Y axis
   * @param speed    The speed to scale at in scale units/sec
   */
  public function scaleBy(
    size: Vector,
    ?speed: Vector
  ): ActionContext {
    return this._getCtx().scaleBy.apply(this._ctx, [size, speed]);
  }

  /**
   * This method will cause an actor to blink (become visible and not
   * visible). Optionally, you may specify the number of blinks. Specify the amount of time
   * the actor should be visible per blink, and the amount of time not visible.
   * This method is part of the actor 'Action' fluent API allowing action chaining.
   * @param timeVisible     The amount of time to stay visible per blink in milliseconds
   * @param timeNotVisible  The amount of time to stay not visible per blink in milliseconds
   * @param numBlinks       The number of times to blink
   */
  public function blink(timeVisible: Int, timeNotVisible: Int, ?numBlinks: Int): ActionContext {
    return this._getCtx().blink(timeVisible, timeNotVisible, numBlinks);
  }

  /**
   * This method will cause an actor's opacity to change from its current value
   * to the provided value by a specified time (in milliseconds). This method is
   * part of the actor 'Action' fluent API allowing action chaining.
   * @param opacity  The ending opacity
   * @param duration     The time it should take to fade the actor (in milliseconds)
   */
  public function fade(opacity: Float, duration: Int): ActionContext {
    return this._getCtx().fade(opacity, duration);
  }

  /**
   * This will cause an actor to flash a specific color for a period of time
   * @param color
   * @param duration The duration in milliseconds
   */
  public function flash(color: Color, duration: Int = 1000) {
    return this._getCtx().flash(color, duration);
  }

  /**
   * This method will delay the next action from executing for a certain
   * amount of time (in milliseconds). This method is part of the actor
   * 'Action' fluent API allowing action chaining.
   * @param duration  The amount of time to delay the next action in the queue from executing in milliseconds
   */
  public function delay(duration: Int): ActionContext {
    return this._getCtx().delay(duration);
  }

  /**
   * This method will add an action to the queue that will remove the actor from the
   * scene once it has completed its previous  Any actions on the
   * action queue after this action will not be executed.
   */
  public function die(): ActionContext {
    return this._getCtx().die();
  }

  /**
   * This method allows you to call an arbitrary method as the next action in the
   * action queue. This is useful if you want to execute code in after a specific
   * action, i.e An actor arrives at a destination after traversing a path
   */
  public function callMethod(method: () -> Any): ActionContext {
    return this._getCtx().callMethod(method);
  }

  /**
   * This method will cause the actor to repeat all of the actions built in
   * the `repeatBuilder` callback. If the number of repeats
   * is not specified it will repeat forever. This method is part of
   * the actor 'Action' fluent API allowing action chaining
   *
   * ```typescript
   * // Move up in a zig-zag by repeated moveBy's
   * actor.actions.repeat(repeatCtx => {
   * repeatCtx.moveBy(10, 0, 10);
   * repeatCtx.moveBy(0, 10, 10);
   * }, 5);
   * ```
   * @param repeatBuilder The builder to specify the repeatable list of actions
   * @param times  The number of times to repeat all the previous actions in the action queue. If nothing is specified the actions
   * will repeat forever
   */
  public function repeat(repeatBuilder: (repeatContext: ActionContext) -> Any, ?times: Int): ActionContext {
    return this._getCtx().repeat(repeatBuilder, times);
  }

  /**
   * This method will cause the actor to repeat all of the actions built in
   * the `repeatBuilder` callback. If the number of repeats
   * is not specified it will repeat forever. This method is part of
   * the actor 'Action' fluent API allowing action chaining
   *
   * ```typescript
   * // Move up in a zig-zag by repeated moveBy's
   * actor.actions.repeat(repeatCtx => {
   * repeatCtx.moveBy(10, 0, 10);
   * repeatCtx.moveBy(0, 10, 10);
   * }, 5);
   * ```
   * @param repeatBuilder The builder to specify the repeatable list of actions
   */
  public function repeatForever(repeatBuilder: (repeatContext: ActionContext) -> Any): ActionContext {
    return this._getCtx().repeatForever(repeatBuilder);
  }

  /**
   * This method will cause the entity to follow another at a specified distance
   * @param entity           The entity to follow
   * @param followDistance  The distance to maintain when following, if not specified the actor will follow at the current distance.
   */
  public function follow(entity: Actor, ?followDistance: Float): ActionContext {
    return this._getCtx().follow(entity, followDistance);
  }

  /**
   * This method will cause the entity to move towards another until they
   * collide "meet" at a specified speed.
   * @param entity  The entity to meet
   * @param speed  The speed in pixels per second to move, if not specified it will match the speed of the other actor
   */
  public function meet(entity: Actor, ?speed: Int): ActionContext {
    return this._getCtx().meet(entity, speed);
  }

  /**
   * Returns a promise that resolves when the current action queue up to now
   * is finished.
   */
  public function toPromise(): Promise<Void> {
    return this._getCtx().toPromise();
  }
}
