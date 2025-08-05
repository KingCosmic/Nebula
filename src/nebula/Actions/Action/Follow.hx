package nebula.Actions.Action;

import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math.Vector;

import nebula.Actions.Action;

class Follow implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  private _followTx: TransformComponent;
  private _followMotion: MotionComponent;

  public x: Float;
  public y: Float;
  private _current: Vector;
  private _end: Vector;
  private _dir: Vector;
  private _speed: Float;
  private _maximumDistance: Float;
  private _distanceBetween: Float;
  private _started = false;
  private _stopped = false;

  public function new(entity: Entity, entityToFollow: Entity, followDistance?: Float) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._followTx = entityToFollow.get(TransformComponent);
    this._followMotion = entityToFollow.get(MotionComponent);
    this._current = new Vector(this._tx.pos.x, this._tx.pos.y);
    this._end = new Vector(this._followTx.pos.x, this._followTx.pos.y);
    this._maximumDistance = followDistance !== undefined ? followDistance : this._current.distance(this._end);
    this._speed = 0;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._distanceBetween = this._current.distance(this._end);
      this._dir = this._end.sub(this._current).normalize();
    }

    var actorToFollowSpeed = Math.sqrt(Math.pow(this._followMotion.vel.x, 2) + Math.pow(this._followMotion.vel.y, 2));
    if (actorToFollowSpeed !== 0) {
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

  public stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }

  public isComplete(): Bool {
    // the actor following should never stop unless specified to do so
    return this._stopped;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
  }
}
