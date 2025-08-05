package nebula.Actions.Action;

import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math;
import nebula.Math.Vector;

import nebula.Util.EasingFunctions;
import nebula.Util.Log;

import nebula.Actions.Action;

interface MoveByOptions {
  offset: Vector;
  duration: Float;
  easing?: EasingFunction;
}

/**
 *
 */
function isMoveByOptions(x: any): x is MoveByOptions {
  return x.offset instanceof Vector && typeof x.duration === 'number';
}

class MoveByWithOptions implements Action {
  id = nextActionId();
  private _start!: Vector;
  private _end!: Vector;
  private _durationMs: Float;
  private _tx: TransformComponent;
  private _started: Bool = false;
  private _currentMs: Float;
  private _stopped: Bool = false;
  private _motion: MotionComponent;
  private _offset: Vector;
  private _easing: EasingFunction = EasingFunctions.Linear;
  public function new(
    public entity: Entity,
    options: MoveByOptions
  ) {
    this._offset = options.offset;
    this._easing = options.easing ?? this._easing;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only MoveBy on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._currentMs = this._durationMs;
  }
  update(elapsed: Float) {
    if (!this._started) {
      this._start = this._tx.pos.clone();
      this._end = this._start.add(this._offset);
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    var currentPos = this._tx.pos;
    var newPosX = this._easing(t, this._start.x, this._end.x, 1);
    var newPosY = this._easing(t, this._start.y, this._end.y, 1);
    var seconds = elapsed / 1000;
    var velX = seconds === 0 ? 0 : (newPosX - currentPos.x) / seconds;
    var velY = seconds === 0 ? 0 : (newPosY - currentPos.y) / seconds;
    this._motion.vel.x = velX;
    this._motion.vel.y = velY;

    if (this.isComplete(this.entity)) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    }
  }
  public isComplete(entity: Entity): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
    this._currentMs = 0;
  }

  public reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class MoveBy implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  private _entity: Entity;
  public x!: Float;
  public y!: Float;
  private _distance!: Float;
  private _speed: Float;

  private _start!: Vector;
  private _offset!: Vector;
  private _end!: Vector;
  private _dir!: Vector;
  private _started = false;
  private _stopped = false;

  constructor(entity: Entity, offsetX: Float, offsetY: Float, speed: Float) {
    this._entity = entity;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._speed = speed;
    this._offset = new Vector(offsetX, offsetY);
    if (speed <= 0) {
      Logger.getInstance().error('Attempted to moveBy with speed less than or equal to zero : ' + speed);
      throw new Error('Speed must be greater than 0 pixels per second');
    }
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._start = new Vector(this._tx.pos.x, this._tx.pos.y);
      this._end = this._start.add(this._offset);
      this._distance = this._offset.magnitude;
      this._dir = this._end.sub(this._start).normalize();
    }

    if (this.isComplete(this._entity)) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    } else {
      this._motion.vel = this._dir.scale(this._speed);
    }
  }

  public isComplete(entity: Entity): Bool {
    const tx = entity.get(TransformComponent);
    return this._stopped || tx.pos.distance(this._start) >= this._distance;
  }

  public stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
  }
}
