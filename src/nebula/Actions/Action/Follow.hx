package nebula.actions.action;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Vector;

import nebula.actions.Action;

class Follow implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  private var _followTx: TransformComponent;
  private var _followMotion: MotionComponent;

  public var x: Int;
  public var y: Int;
  private var _current: Vector;
  private var _end: Vector;
  private var _dir: Vector;
  private var _speed: Int;
  private var _maximumDistance: Int;
  private var _distanceBetween: Int;
  private var _started = false;
  private var _stopped = false;

  public function new(entity: Entity, entityToFollow: Entity, ?followDistance: Int) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._followTx = entityToFollow.get(TransformComponent);
    this._followMotion = entityToFollow.get(MotionComponent);
    this._current = new Vector(this._tx.pos.x, this._tx.pos.y);
    this._end = new Vector(this._followTx.pos.x, this._followTx.pos.y);
    this._maximumDistance = followDistance != null ? followDistance : this._current.distance(this._end);
    this._speed = 0;
  }

  public function update(elapsed: Int) {
    if (!this._started) {
      this._started = true;
      this._distanceBetween = this._current.distance(this._end);
      this._dir = this._end.sub(this._current).normalize();
    }

    var actorToFollowSpeed = Math.sqrt(Math.pow(this._followMotion.vel.x, 2) + Math.pow(this._followMotion.vel.y, 2));
    if (actorToFollowSpeed != 0) {
      this._speed = actorToFollowSpeed;
    }
    this._current = vec(this._tx.pos.x, this._tx.pos.y);

    this._end = vec(this._followTx.pos.x, this._followTx.pos.y);
    this._distanceBetween = this._current.distance(this._end);
    this._dir = this._end.sub(this._current).normalize();

    if (this._distanceBetween >= this._maximumDistance) {
      var m = this._dir.scale(this._speed);
      this._motion.vel = vec(m.x, m.y);
    } else {
      this._motion.vel = vec(0, 0);
    }

    if (this.isComplete()) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    }
  }

  public function stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }

  public function isComplete(): Bool {
    // the actor following should never stop unless specified to do so
    return this._stopped;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
  }
}
