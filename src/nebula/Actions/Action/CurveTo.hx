package nebula.Actions.Action;

import nebula.EntityComponentSystem;
import nebula.Math;
import nebula.Actions.Action;

interface CurveToOptions {
  /**
   * Bezier Curve in world coordinates to animate towards
   *
   * The start control point is assumed to be the actor's current position
   */
  controlPoints: [control1: Vector, control2: Vector, end: Vector];
  /**
   * Total duration for the action to run
   */
  duration: Float;
  /**
   * Dynamic mode will speed up/slow down depending on the curve
   *
   * Uniform mode will animate at a consistent velocity across the curve
   *
   * Default: 'dynamic'
   */
  mode?: 'dynamic' | 'uniform';
  /**
   * Quality when sampling uniform points on the curve. Samples = 4 * quality;
   *
   * For bigger 'uniform' curves you may want to increase quality
   *
   * Default 4
   */
  quality?: Int;
}

class CurveTo implements Action {
  id: Int = nextActionId();

  private _curve: BezierCurve;
  private _durationMs: Float;
  private _entity: Entity<any>;
  private _tx: TransformComponent;
  private _currentMs: Float;
  private _started = false;
  private _stopped = false;
  private _mode: 'dynamic' | 'uniform' = 'dynamic';
  constructor(entity: Entity, options: CurveToOptions) {
    this._entity = entity;
    this._tx = this._entity.get(TransformComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only curveTo on Entities with TransformComponents.');
    }
    this._curve = new BezierCurve({
      controlPoints: [vec(0, 0), ...options.controlPoints],
      quality: options.quality
    });
    this._durationMs = options.duration;
    this._mode = options.mode ?? this._mode;
    this._currentMs = this._durationMs;
  }

  update(elapsed: Float): void {
    if (!this._started) {
      this._curve.setControlPoint(0, this._tx.globalPos.clone());
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    if (this._mode === 'dynamic') {
      this._tx.pos = this._curve.getPoint(t);
    } else {
      this._tx.pos = this._curve.getUniformPoint(t);
    }
    if (this.isComplete(this._entity)) {
      if (this._mode === 'dynamic') {
        this._tx.pos = this._curve.getPoint(1);
      } else {
        this._tx.pos = this._curve.getUniformPoint(1);
      }
    }
  }
  isComplete(entity: Entity): Bool {
    return this._stopped || this._currentMs < 0;
  }
  reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
  stop() {
    this._stopped = true;
    this._currentMs = 0;
  }
}
