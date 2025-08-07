package nebula.actions.action;

import nebula.actions.Action;

class Delay implements Action {
  var id = nextActionId();
  private var _elapsedTime: Int = 0;
  private var _delay: Int;
  private var _started: Bool = false;
  private var _stopped = false;
  public function new(duration: Int) {
    this._delay = duration;
  }

  public function update(elapsed: Int) {
    if (!this._started) {
      this._started = true;
    }

    this._elapsedTime += elapsed;
  }

  function isComplete(): Bool {
    return this._stopped || this._elapsedTime >= this._delay;
  }

  public function stop() {
    this._stopped = true;
  }

  function reset() {
    this._elapsedTime = 0;
    this._started = false;
    this._stopped = false;
  }
}
