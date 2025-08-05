package nebula.Actions.Action;

import nebula.Actions.Action;

class Delay implements Action {
  id = nextActionId();
  private _elapsedTime: Float = 0;
  private _delay: Float;
  private _started: Bool = false;
  private _stopped = false;
  constructor(duration: Float) {
    this._delay = duration;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
    }

    this._elapsedTime += elapsed;
  }

  isComplete(): Bool {
    return this._stopped || this._elapsedTime >= this._delay;
  }

  public stop() {
    this._stopped = true;
  }

  reset() {
    this._elapsedTime = 0;
    this._started = false;
    this._stopped = false;
  }
}
