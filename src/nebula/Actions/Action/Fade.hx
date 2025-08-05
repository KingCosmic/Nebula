package nebula.Actions.Action;

import nebula.EntityComponentSystem.Entity;
import nebula.Graphics.GraphicsComponent;
import nebula.Util.Log;
import nebula.Actions.Action;

class Fade implements Action {
  id = nextActionId();
  private _graphics: GraphicsComponent;

  private _endOpacity: Float;
  private _remainingTime: Float;
  private _originalTime: Float;
  private _multiplier: Float = 1;
  private _started = false;
  private _stopped = false;

  constructor(entity: Entity, endOpacity: Float, duration: Float) {
    this._graphics = entity.get(GraphicsComponent);
    this._endOpacity = endOpacity;
    this._remainingTime = this._originalTime = duration;
  }

  public update(elapsed: Float) {
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

  public isComplete(): Bool {
    return this._stopped || this._remainingTime <= 0;
  }

  public stop() {
    this._stopped = true;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
    this._remainingTime = this._originalTime;
  }
}
