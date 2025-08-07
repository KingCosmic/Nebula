package nebula.util;

/**
 * Future is a wrapper around a native browser Promise to allow resolving/rejecting at any time
 */
class Future<T> {
  // Code from StephenCleary https://gist.github.com/StephenCleary/ba50b2da419c03b9cba1d20cb4654d5e
  private var _resolver: (value: T) -> Void;
  private var _rejecter: (error: Error) -> Void;
  private var _isCompleted: Bool = false;

  public function new() {
    this.promise = new Promise((resolve, reject) -> {
      this._resolver = resolve;
      this._rejecter = reject;
    });
  }

  public var promise: Promise<T>;

  public var isCompleted(get, never): Bool;
  function get_isCompleted(): Bool {
    return this._isCompleted;
  }

  public function resolve(value: T): Void {
    if (this._isCompleted) {
      return;
    }
    this._isCompleted = true;
    this._resolver(value);
  }

  public function reject(error: Error): Void {
    if (this._isCompleted) {
      return;
    }
    this._isCompleted = true;
    this._rejecter(error);
  }
}
