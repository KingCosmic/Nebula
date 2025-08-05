package nebula.Actions.Action;

import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math.Vector;
import nebula.Actions.Action;

/**
 * @deprecated use moveBy({offset: Vector, duration: number, easing: EasingFunction})
 */
class EaseBy implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  private _currentLerpTime: Float = 0;
  private _lerpDuration: Float = 1 * 1000; // 1 second
  private _lerpStart: Vector = new Vector(0, 0);
  private _lerpEnd: Vector = new Vector(0, 0);
  private _offset: Vector;
  private _initialized: Bool = false;
  private _stopped: Bool = false;
  public function new(
    entity: Entity,
    offsetX: Float,
    offsetY: Float,
    duration: Float,
    public easingFcn: (currentTime: Float, startValue: Float, endValue: Float, duration: Float) => Float
  ) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._lerpDuration = duration;
    this._offset = new Vector(offsetX, offsetY);
  }
  private _initialize() {
    this._lerpStart = new Vector(this._tx.pos.x, this._tx.pos.y);
    this._currentLerpTime = 0;
    this._lerpEnd = this._lerpStart.add(this._offset);
  }

  public update(elapsed: Float): void {
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
      this._motion.vel = vec(seconds === 0 ? 0 : (newX - this._tx.pos.x) / seconds, seconds === 0 ? 0 : (newY - this._tx.pos.y) / seconds);
    } else {
      this._tx.pos = vec(this._lerpEnd.x, this._lerpEnd.y);
      this._motion.vel = Vector.Zero;
    }
  }
  public isComplete(): Bool {
    return this._stopped || this._currentLerpTime >= this._lerpDuration;
  }

  public reset() {
    this._initialized = false;
    this._stopped = false;
    this._currentLerpTime = 0;
  }
  public stop() {
    this._motion.vel = vec(0, 0);
    this._stopped = true;
  }
}
