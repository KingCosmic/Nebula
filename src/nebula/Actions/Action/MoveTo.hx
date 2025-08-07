package nebula.actions.action;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Vector;

import nebula.util.EasingFunctions;

import nebula.actions.Action;

interface MoveToOptions {
  var pos: Vector;
  var duration: Int;
  var easing: Null<EasingFunction>;
}

/**
 *
 */
function isMoveToOptions(x: Any) {
  return (Std.isOfType(x.pos, Vector) && Std.isOfType(x.duration, Int));
}

class MoveToWithOptions implements Action {
  var id = nextActionId();
  private var _end: Vector;
  private var _durationMs: Float;
  private var _tx: TransformComponent;
  private var _started: Bool = false;
  private var _start: Vector;
  private var _currentMs: Float;
  private var _stopped: Bool = false;
  private var _motion: MotionComponent;
  private var _easing: EasingFunction = EasingFunctions.Linear;
  public function new(
    entity: Entity,
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
  function update(elapsed: Int): Void {
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
    var velX = seconds == 0 ? 0 : (newPosX - currentPos.x) / seconds;
    var velY = seconds == 0 ? 0 : (newPosY - currentPos.y) / seconds;
    this._motion.vel.x = velX;
    this._motion.vel.y = velY;

    if (this.isComplete(this.entity)) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    }
  }
  public function isComplete(entity: Entity): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public function stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
    this._currentMs = 0;
  }

  public function reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class MoveTo implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  public var x: Int;
  public var y: Int;
  private var _start: Vector;
  private var _end: Vector;
  private var _dir: Vector;
  private var _speed: Int;
  private var _distance: Int;
  private var _started = false;
  private var _stopped = false;
  public function new(
    entity: Entity,
    destX: Int,
    destY: Int,
    speed: Int
  ) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._end = new Vector(destX, destY);
    this._speed = speed;
  }

  public function update(elapsed: Int) {
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

  public function isComplete(entity: Entity): Bool {
    var tx = entity.get(TransformComponent);
    return this._stopped || new Vector(tx.pos.x, tx.pos.y).distance(this._start) >= this._distance;
  }

  public function stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
  }
}
