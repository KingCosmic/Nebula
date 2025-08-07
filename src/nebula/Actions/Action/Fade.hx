package nebula.actions.action;

import nebula.entitycomponentsystem.Entity;
import nebula.graphics.GraphicsComponent;
import nebula.util.Log;
import nebula.actions.Action;

class Fade implements Action {
  var id = nextActionId();
  private var _graphics: GraphicsComponent;

  private var _endOpacity: Float;
  private var _remainingTime: Int;
  private var _originalTime: Int;
  private var _multiplier: Float = 1;
  private var _started = false;
  private var _stopped = false;

  public function new(entity: Entity, endOpacity: Float, duration: Int) {
    this._graphics = entity.get(GraphicsComponent);
    this._endOpacity = endOpacity;
    this._remainingTime = this._originalTime = duration;
  }

  public function update(elapsed: Int) {
    if (!this._graphics) {
      return;
    }

    if (!this._started) {
      this._started = true;
      this._remainingTime = this._originalTime;

      // determine direction when we start
      if (this._endOpacity < this._graphics.opacity) {
        this._multiplier = -1;
      } else {
        this._multiplier = 1;
      }
    }

    if (this._remainingTime > 0) {
      this._graphics.opacity += (this._multiplier * (Math.abs(this._graphics.opacity - this._endOpacity) * elapsed)) / this._remainingTime;
    }

    this._remainingTime -= elapsed;

    if (this.isComplete()) {
      this._graphics.opacity = this._endOpacity;
    }

    Logger.getInstance().debug('[Action fade] Actor opacity:', this._graphics.opacity);
  }

  public function isComplete(): Bool {
    return this._stopped || this._remainingTime <= 0;
  }

  public function stop() {
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
    this._remainingTime = this._originalTime;
  }
}
