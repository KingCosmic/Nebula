package nebula.actions.action;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Vector;

import nebula.util.EasingFunctions;
import nebula.util.Log;

import nebula.actions.Action;

interface MoveByOptions {
  var offset: Vector;
  var duration: Int;
  var easing: Null<EasingFunction>;
}

/**
 *
 */
function isMoveByOptions(x: Any) {
  return (Std.isOfType(x.offset, Vector) && Std.isOfType(x.duration, Int));
}

class MoveByWithOptions implements Action {
  var id = nextActionId();
  private var _start: Vector;
  private var _end: Vector;
  private var _durationMs: Float;
  private var _tx: TransformComponent;
  private var _started: Bool = false;
  private var _currentMs: Float;
  private var _stopped: Bool = false;
  private var _motion: MotionComponent;
  private var _offset: Vector;
  private var _easing: EasingFunction = EasingFunctions.Linear;
  public function new(
    entity: Entity,
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
  function update(elapsed: Int) {
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

class MoveBy implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  private var _entity: Entity;
  public var x: Float;
  public var y: Float;
  private var _distance: Float;
  private var _speed: Float;

  private var _start: Vector;
  private var _offset: Vector;
  private var _end: Vector;
  private var _dir: Vector;
  private var _started = false;
  private var _stopped = false;

  public function new(entity: Entity, offsetX: Int, offsetY: Int, speed: Int) {
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

  public function update(elapsed: Int) {
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

  public function isComplete(entity: Entity): Bool {
    final tx = entity.get(TransformComponent);
    return this._stopped || tx.pos.distance(this._start) >= this._distance;
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
