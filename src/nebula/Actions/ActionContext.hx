package nebula.actions;

import nebula.util.EasingFunctions;
import nebula.actions.ActionQueue;
import nebula.actions.action.Repeat;
import nebula.actions.action.RepeatForever;
import nebula.actions.action.MoveBy;
import nebula.actions.action.MoveTo;
import nebula.actions.action.RotateTo;
import nebula.actions.action.RotateBy;
import nebula.actions.action.ScaleTo;
import nebula.actions.action.ScaleBy;
import nebula.actions.action.CallMethod;
import nebula.actions.action.EaseTo;
import nebula.actions.action.EaseBy;
import nebula.actions.action.Blink;
import nebula.actions.action.Fade;
import nebula.actions.action.Delay;
import nebula.actions.action.Die;
import nebula.actions.action.Follow;
import nebula.actions.action.Meet;

import nebula.entitycomponentsystem.Entity;
import nebula.Color;
import nebula.actions.action.Flash;
import nebula.actions.action.CurveTo;
import nebula.actions.action.CurveBy;

/**
 * The fluent Action API allows you to perform "actions" on
 * {@apilink Actor | `actors`} such as following, moving, rotating, and
 * more. You can implement your own actions by implementing
 * the {@apilink Action} interface.
 */
class ActionContext {
  private var _entity: Entity;
  private var _queue: ActionQueue;

  public function new(entity: Entity) {
    this._entity = entity;
    this._queue = new ActionQueue(entity);
  }

  public function getQueue(): ActionQueue {
    return this._queue;
  }

  public function update(elapsed: Int) {
    this._queue.update(elapsed);
  }

  /**
   * Clears all queued actions from the Actor
   */
  public function clearActions(): Void {
    this._queue.clearActions();
  }

  public function runAction(action: Action) {
    action.reset();
    this._queue.add(action);
    return this;
  }

  /**
   * Animates an actor with a specified bezier curve by an offset to the current position, the start point is assumed
   * to be the actors current position
   * @param options
   */
  public function curveBy(options: CurveByOptions): ActionContext {
    this._queue.add(new CurveBy(this._entity, options));
    return this;
  }

  /**
   * Animates an actor with a specified bezier curve to an absolute world space coordinate, the start point is assumed
   * to be the actors current position
   * @param options
   */
  public function curveTo(options: CurveToOptions): ActionContext {
    this._queue.add(new CurveTo(this._entity, options));
    return this;
  }

  /**
   * This method will move an actor to the specified `x` and `y` position over the
   * specified duration using a given {@apilink EasingFunctions} and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param x         The x location to move the actor to
   * @param y         The y location to move the actor to
   * @param duration  The time it should take the actor to move to the new location in milliseconds
   * @param easingFcn Use {@apilink EasingFunction} or a custom function to use to calculate position, Default is {@apilink EasingFunctions.Linear}
   * @deprecated use new moveTo({pos: Vector, duration: number, easing: EasingFunction})
   */
  public function easeTo(vector: Vector, duration: Int, easeFn: EasingFunctions = EasingFunctions.Linear): ActionContext {
    var x = vector.x;
    var y = vector.y;

    this._queue.add(new EaseTo(this._entity, x, y, duration, easingFcn));
    return this;
  }

  /**
   * This method will move an actor by a specified x and y offset relative to the current position given
   * a duration and a {@apilink EasingFunction}. This method is part of the actor 'Action' fluent API allowing action chaining.
   * @param offset Vector offset relative to the current position
   * @param duration The duration in milliseconds
   * @param easingFcn Use {@apilink EasingFunction} or a custom function to use to calculate position, Default is {@apilink EasingFunctions.Linear}
   * @deprecated use new moveBy({offset: Vector, duration: number, easing: EasingFunction})
   */
  public function easeBy(offset: Vector, duration: Float, ?easingFcn: EasingFunction = EasingFunctions.Linear): ActionContext {
    var offsetX = offset.x;
    var offsetY = offset.y;

    this._queue.add(new EaseBy(this._entity, offsetX, offsetY, duration, easingFcn));
    return this;
  }

  /**
   * This method will move an actor to the specified x and y position at the
   * speed specified (in pixels per second) and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param pos    The x,y vector location to move the actor to
   * @param speed  The speed in pixels per second to move
   */
  public function moveTo(pos: Vector, speed: Int): ActionContext {
    var x = pos.x;
    var y = pos.y;
    this._queue.add(new MoveTo(this._entity, x, y, speed));
    return this;
  }

  /**
   * This method will move an actor by the specified x offset and y offset from its current position, at a certain speed.
   * This method is part of the actor 'Action' fluent API allowing action chaining.
   * @param xOffset     The x offset to apply to this actor
   * @param yOffset     The y location to move the actor to
   * @param speed  The speed in pixels per second the actor should move
   */
  public function moveBy(
    offset: Vector,
    ?speed: Float
  ): ActionContext {
    var xOffset = offset.x;
    var yOffset = offset.y;
    this._queue.add(new MoveBy(this._entity, xOffset, yOffset, speed));
    return this;
  }

  /**
   * This method will rotate an actor to the specified angle at the speed
   * specified (in radians per second) and return back the actor. This
   * method is part of the actor 'Action' fluent API allowing action chaining.
   * @param angle  The angle to rotate to in radians
   * @param speed         The angular velocity of the rotation specified in radians per second
   * @param rotationType  The {@apilink RotationType} to use for this rotation
   */
  public function rotateTo(angleRadians: Float, ?speed: Float, ?rotationType: RotationType): ActionContext {
    this._queue.add(new RotateTo(this._entity, angleRadians, speed, rotationType));
    return this;
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
    this._queue.add(new RotateBy(this._entity, angleRadiansOffset, speed, rotationType));
    return this;
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
    ?speed: Vector,
  ): ActionContext {
    var sizeX = vector.x;
    var sizeY = vector.y;
    var speedX = speed.x;
    var speedY = speed.y;

    this._queue.add(new ScaleTo(this._entity, sizeX, sizeY, speedX, speedY));
    return this;
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
    vector: Vector,
    ?speed: Float,
  ): ActionContext {
    var sizeOffsetX = vector.x;
    var sizeOffsetY = vector.y;

    this._queue.add(new ScaleBy(this._entity, sizeOffsetX, sizeOffsetY, speed));
    return this;
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
  public function blink(timeVisible: Int, timeNotVisible: Int, numBlinks: Int = 1): ActionContext {
    this._queue.add(new Blink(this._entity, timeVisible, timeNotVisible, numBlinks));
    return this;
  }

  /**
   * This method will cause an actor's opacity to change from its current value
   * to the provided value by a specified time (in milliseconds). This method is
   * part of the actor 'Action' fluent API allowing action chaining.
   * @param opacity  The ending opacity
   * @param duration     The time it should take to fade the actor (in milliseconds)
   */
  public function fade(opacity: Float, duration: Int): ActionContext {
    this._queue.add(new Fade(this._entity, opacity, duration));
    return this;
  }

  /**
   * This will cause an actor to flash a specific color for a period of time
   * @param color
   * @param duration The duration in milliseconds
   */
  public function flash(color: Color, duration: Int = 1000) {
    this._queue.add(new Flash(this._entity, color, duration));
    return this;
  }

  /**
   * This method will delay the next action from executing for a certain
   * amount of time (in milliseconds). This method is part of the actor
   * 'Action' fluent API allowing action chaining.
   * @param duration  The amount of time to delay the next action in the queue from executing in milliseconds
   */
  public function delay(duration: Int): ActionContext {
    this._queue.add(new Delay(duration));
    return this;
  }

  /**
   * This method will add an action to the queue that will remove the actor from the
   * scene once it has completed its previous Any actions on the
   * action queue after this action will not be executed.
   */
  public function die(): ActionContext {
    this._queue.add(new Die(this._entity));
    return this;
  }

  /**
   * This method allows you to call an arbitrary method as the next action in the
   * action queue. This is useful if you want to execute code in after a specific
   * action, i.e An actor arrives at a destination after traversing a path
   */
  public function callMethod(method: () -> Any): ActionContext {
    this._queue.add(new CallMethod(method));
    return this;
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
    if (!times) {
      this.repeatForever(repeatBuilder);
      return this;
    }
    this._queue.add(new Repeat(this._entity, repeatBuilder, times));

    return this;
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
    this._queue.add(new RepeatForever(this._entity, repeatBuilder));
    return this;
  }

  /**
   * This method will cause the entity to follow another at a specified distance
   * @param entity           The entity to follow
   * @param followDistance  The distance to maintain when following, if not specified the actor will follow at the current distance.
   */
  public function follow(entity: Entity, ?followDistance: Int): ActionContext {
    if (followDistance == null) {
      this._queue.add(new Follow(this._entity, entity));
    } else {
      this._queue.add(new Follow(this._entity, entity, followDistance));
    }
    return this;
  }

  /**
   * This method will cause the entity to move towards another until they
   * collide "meet" at a specified speed.
   * @param entity  The entity to meet
   * @param speed  The speed in pixels per second to move, if not specified it will match the speed of the other actor
   * @param tolerance  The tolerance in pixels to meet, if not specified it will be 1 pixel
   */
  public function meet(entity: Entity, ?speed: Int, ?tolerance: Int): ActionContext {
    if (speed == null && tolerance == null) {
      this._queue.add(new Meet(this._entity, entity));
    } else if (tolerance == null) {
      this._queue.add(new Meet(this._entity, entity, speed));
    } else {
      this._queue.add(new Meet(this._entity, entity, speed, tolerance));
    }
    return this;
  }

  /**
   * Returns a promise that resolves when the current action queue up to now
   * is finished.
   */
  public function toPromise(): Promise<Void> {
    final temp = new Promise((resolve) -> {
      this._queue.add(
        new CallMethod(() -> {
          resolve();
        })
      );
    });
    return temp;
  }
}
