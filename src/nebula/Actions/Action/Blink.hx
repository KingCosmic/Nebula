package nebula.actions.action;

import nebula.graphics.GraphicsComponent;
import nebula.entitycomponentsystem.Entity;
import nebula.actions.Action;

class Blink implements Action {
  var id = nextActionId();
  private var _graphics: GraphicsComponent;
  private var _timeVisible: Int = 0;
  private var _timeNotVisible: Int = 0;
  private var _elapsedTime: Int = 0;
  private var _totalTime: Int = 0;
  private var _duration: Int;
  private var _stopped: Bool = false;
  private var _started: Bool = false;
  public function new(entity: Entity, timeVisible: Int, timeNotVisible: Int, numBlinks: Int = 1) {
    this._graphics = entity.get(GraphicsComponent);
    this._timeVisible = timeVisible;
    this._timeNotVisible = timeNotVisible;
    this._duration = (timeVisible + timeNotVisible) * numBlinks;
  }

  public function update(elapsed: Int): Void {
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

  public function isComplete(): Bool {
    return this._stopped || this._totalTime >= this._duration;
  }

  public function stop(): Void {
    if (this._graphics) {
      this._graphics.isVisible = true;
    }
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
    this._elapsedTime = 0;
    this._totalTime = 0;
  }
}
