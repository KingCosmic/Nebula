package nebula.actions.action;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Vector;

import nebula.actions.Action;

class Meet implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  private var _meetTx: TransformComponent;
  private var _meetMotion: MotionComponent;
  public var x: Int;
  public var y: Int;
  private var _current: Vector;
  private var _end: Vector;
  private var _dir: Vector;
  private var _speed: Int;
  private var _distanceBetween: Int;
  private var _started = false;
  private var _stopped = false;
  private var _speedWasSpecified = false;
  private var _tolerance = 1;

  public function new(actor: Entity, actorToMeet: Entity, ?speed: Int, ?tolerance: Int) {
    this._tx = actor.get(TransformComponent);
    this._motion = actor.get(MotionComponent);
    this._meetTx = actorToMeet.get(TransformComponent);
    this._meetMotion = actorToMeet.get(MotionComponent);
    this._current = new Vector(this._tx.pos.x, this._tx.pos.y);
    this._end = new Vector(this._meetTx.pos.x, this._meetTx.pos.y);
    this._speed = speed || 0;

    if (speed != null) {
      this._speedWasSpecified = true;
    }

    if (tolerance != null) {
      this._tolerance = tolerance;
    }
  }

  public function update(elapsed: Int) {
    if (!this._started) {
      this._started = true;
      this._distanceBetween = this._current.distance(this._end);
      this._dir = this._end.sub(this._current).normalize();
    }

    var actorToMeetSpeed = Math.sqrt(Math.pow(this._meetMotion.vel.x, 2) + Math.pow(this._meetMotion.vel.y, 2));
    if (actorToMeetSpeed != 0 && !this._speedWasSpecified) {
      this._speed = actorToMeetSpeed;
    }
    this._current = vec(this._tx.pos.x, this._tx.pos.y);

    this._end = vec(this._meetTx.pos.x, this._meetTx.pos.y);
    this._distanceBetween = this._current.distance(this._end);
    this._dir = this._end.sub(this._current).normalize();

    var m = this._dir.scale(this._speed);
    this._motion.vel = vec(m.x, m.y);

    if (this.isComplete()) {
      this._tx.pos = vec(this._end.x, this._end.y);
      this._motion.vel = vec(0, 0);
    }
  }

  public function isComplete(): Bool {
    return this._stopped || this._distanceBetween <= this._tolerance;
  }

  public function stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
    this._distanceBetween = Infinity;
  }
}
