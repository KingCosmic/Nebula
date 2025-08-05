package nebula.Actions.Action;

import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math;
import nebula.Math.Vector;

import nebula.Util.EasingFunctions;

import nebula.Actions.Action;

interface MoveToOptions {
  pos: Vector;
  duration: Float;
  easing?: EasingFunction;
}

/**
 *
 */
function isMoveToOptions(x: any): x is MoveToOptions {
  return x.pos instanceof Vector && typeof x.duration === 'number';
}

class MoveToWithOptions implements Action {
  id = nextActionId();
  private _end: Vector;
  private _durationMs: Float;
  private _tx: TransformComponent;
  private _started: Bool = false;
  private _start!: Vector;
  private _currentMs: Float;
  private _stopped: Bool = false;
  private _motion: MotionComponent;
  private _easing: EasingFunction = EasingFunctions.Linear;
  public function new(
    public entity: Entity,
    options: MoveToOptions
  ) {
    this._end = options.pos;
    this._easing = options.easing ?? this._easing;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only moveTo on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._currentMs = this._durationMs;
  }
  update(elapsed: Float): void {
    if (!this._started) {
      this._start = this._tx.pos.clone();
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

class MoveTo implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  public x!: Float;
  public y!: Float;
  private _start!: Vector;
  private _end: Vector;
  private _dir!: Vector;
  private _speed: Float;
  private _distance!: Float;
  private _started = false;
  private _stopped = false;
  public function new(
    public entity: Entity,
    destX: Float,
    destY: Float,
    speed: Float
  ) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._end = new Vector(destX, destY);
    this._speed = speed;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._start = new Vector(this._tx.pos.x, this._tx.pos.y);
      this._distance = this._start.distance(this._end);
      this._dir = this._end.sub(this._start).normalize();
    }
    var m = this._dir.scale(this._speed);
    this._motion.vel = vec(m.x, m.y);

    if (this.isComplete(this.entity)) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    }
  }

  public isComplete(entity: Entity): Bool {
    var tx = entity.get(TransformComponent);
    return this._stopped || new Vector(tx.pos.x, tx.pos.y).distance(this._start) >= this._distance;
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
