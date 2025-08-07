package nebula.actions.action;

import nebula.math.Vector;
import nebula.actions.Action;

interface CurveByOptions {
  /**
   * Bezier Curve relative to the current actor position to move
   */
  var controlPoints: { control1: Vector, control2: Vector, end: Vector };
  /**
   * Total duration for the action to run
   */
  var duration: Int;
  /**
   * Dynamic mode will speed up/slow down depending on the curve
   *
   * Uniform mode will animate at a consistent velocity across the curve
   *
   * Default: 'dynamic'
   */
  var mode: Null<String>;

  /**
   * Quality when sampling uniform points on the curve. Samples = 4 * quality;
   *
   * For bigger 'uniform' curves you may want to increase quality to make the motion appear smooth
   *
   * Default 4
   */
  var quality: Null<Int>;
}

class CurveBy implements Action {
  var id: Int = nextActionId();

  private var _curve: BezierCurve;
  private var _durationMs: Int;
  private var _entity: Entity<Any>;
  private var _tx: TransformComponent;
  private var _currentMs: Int;
  private var _started = false;
  private var _stopped = false;
  private var _mode: String = 'dynamic';
  public function new(entity: Entity, options: CurveByOptions) {
    this._entity = entity;
    this._tx = this._entity.get(TransformComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only curveTo on Entities with TransformComponents.');
    }
    this._curve = this._curve = new BezierCurve({
      controlPoints: [vec(0, 0), ...options.controlPoints],
      quality: options.quality
    });
    this._durationMs = options.duration;
    this._mode = options.mode ?? this._mode;
    this._currentMs = this._durationMs;
  }

  function update(elapsed: Int): Void {
    if (!this._started) {
      this._curve.setControlPoint(0, this._tx.globalPos);
      this._curve.setControlPoint(1, this._curve.controlPoints[1].add(this._tx.globalPos));
      this._curve.setControlPoint(2, this._curve.controlPoints[2].add(this._tx.globalPos));
      this._curve.setControlPoint(3, this._curve.controlPoints[3].add(this._tx.globalPos));
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    if (this._mode == 'dynamic') {
      this._tx.pos = this._curve.getPoint(t);
    } else {
      this._tx.pos = this._curve.getUniformPoint(t);
    }
    if (this.isComplete(this._entity)) {
      if (this._mode == 'dynamic') {
        this._tx.pos = this._curve.getPoint(1);
      } else {
        this._tx.pos = this._curve.getUniformPoint(1);
      }
    }
  }
  function isComplete(entity: Entity): Bool {
    return this._stopped || this._currentMs < 0;
  }
  function reset(): Void {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
  function stop(): Void {
    this._stopped = true;
  }
}
