package nebula.Actions.Action;

import nebula.Graphics.GraphicsComponent;
import nebula.EntityComponentSystem.Entity;
import nebula.Actions.Action;

class Blink implements Action {
  id = nextActionId();
  private _graphics: GraphicsComponent;
  private _timeVisible: Float = 0;
  private _timeNotVisible: Float = 0;
  private _elapsedTime: Float = 0;
  private _totalTime: Float = 0;
  private _duration: Float;
  private _stopped: Bool = false;
  private _started: Bool = false;
  constructor(entity: Entity, timeVisible: Float, timeNotVisible: Float, numBlinks: Int = 1) {
    this._graphics = entity.get(GraphicsComponent);
    this._timeVisible = timeVisible;
    this._timeNotVisible = timeNotVisible;
    this._duration = (timeVisible + timeNotVisible) * numBlinks;
  }

  public update(elapsed: Float): void {
    if (!this._started) {
      this._started = true;
      this._elapsedTime = 0;
      this._totalTime = 0;
    }
    if (!this._graphics) {
      return;
    }

    this._elapsedTime += elapsed;
    this._totalTime += elapsed;
    if (this._graphics.isVisible && this._elapsedTime >= this._timeVisible) {
      this._graphics.isVisible = false;
      this._elapsedTime = 0;
    }

    if (!this._graphics.isVisible && this._elapsedTime >= this._timeNotVisible) {
      this._graphics.isVisible = true;
      this._elapsedTime = 0;
    }

    if (this.isComplete()) {
      this._graphics.isVisible = true;
    }
  }

  public isComplete(): Bool {
    return this._stopped || this._totalTime >= this._duration;
  }

  public stop(): void {
    if (this._graphics) {
      this._graphics.isVisible = true;
    }
    this._stopped = true;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
    this._elapsedTime = 0;
    this._totalTime = 0;
  }
}
