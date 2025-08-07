package nebula.actions.action;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Vector;
import nebula.actions.Action;

/**
 * @deprecated use moveBy({offset: Vector, duration: number, easing: EasingFunction})
 */
class EaseBy implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  private var _currentLerpTime: Int = 0;
  private var _lerpDuration: Int = 1 * 1000; // 1 second
  private var _lerpStart: Vector = new Vector(0, 0);
  private var _lerpEnd: Vector = new Vector(0, 0);
  private var _offset: Vector;
  private var _initialized: Bool = false;
  private var _stopped: Bool = false;
  public function new(
    entity: Entity,
    offsetX: Float,
    offsetY: Float,
    duration: Float,
    easingFcn: (currentTime: Float, startValue: Float, endValue: Float, duration: Float) -> Float
  ) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._lerpDuration = duration;
    this._offset = new Vector(offsetX, offsetY);
  }
  private function _initialize() {
    this._lerpStart = new Vector(this._tx.pos.x, this._tx.pos.y);
    this._currentLerpTime = 0;
    this._lerpEnd = this._lerpStart.add(this._offset);
  }

  public function update(elapsed: Int): Void {
    if (!this._initialized) {
      this._initialize();
      this._initialized = true;
    }

    // Need to update lerp time first, otherwise the first update will always be zero
    this._currentLerpTime += elapsed;
    var newX = this._tx.pos.x;
    var newY = this._tx.pos.y;
    if (this._currentLerpTime < this._lerpDuration) {
      if (this._lerpEnd.x < this._lerpStart.x) {
        newX =
          this._lerpStart.x -
          (this.easingFcn(this._currentLerpTime, this._lerpEnd.x, this._lerpStart.x, this._lerpDuration) - this._lerpEnd.x);
      } else {
        newX = this.easingFcn(this._currentLerpTime, this._lerpStart.x, this._lerpEnd.x, this._lerpDuration);
      }

      if (this._lerpEnd.y < this._lerpStart.y) {
        newY =
          this._lerpStart.y -
          (this.easingFcn(this._currentLerpTime, this._lerpEnd.y, this._lerpStart.y, this._lerpDuration) - this._lerpEnd.y);
      } else {
        newY = this.easingFcn(this._currentLerpTime, this._lerpStart.y, this._lerpEnd.y, this._lerpDuration);
      }
      // Given the lerp position figure out the velocity in pixels per second
      var seconds = elapsed / 1000;
      this._motion.vel = vec(seconds == 0 ? 0 : (newX - this._tx.pos.x) / seconds, seconds == 0 ? 0 : (newY - this._tx.pos.y) / seconds);
    } else {
      this._tx.pos = vec(this._lerpEnd.x, this._lerpEnd.y);
      this._motion.vel = Vector.Zero;
    }
  }
  public function isComplete(): Bool {
    return this._stopped || this._currentLerpTime >= this._lerpDuration;
  }

  public function reset() {
    this._initialized = false;
    this._stopped = false;
    this._currentLerpTime = 0;
  }
  public function stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }
}
