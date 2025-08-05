package nebula.Util;

/**
 * Future is a wrapper around a native browser Promise to allow resolving/rejecting at any time
 */
class Future<T> {
  // Code from StephenCleary https://gist.github.com/StephenCleary/ba50b2da419c03b9cba1d20cb4654d5e
  private _resolver: (value: T) => Void;
  private _rejecter: (error: Error) => Void;
  private _isCompleted: boolean = false;

  public function new() {
    this.promise = new Promise((resolve, reject) => {
      this._resolver = resolve;
      this._rejecter = reject;
    });
  }

  public readonly promise: Promise<T>;

  public get isCompleted(): Bool {
    return this._isCompleted;
  }

  public resolve(value: T): Void {
    if (this._isCompleted) {
      return;
    }
    this._isCompleted = true;
    this._resolver(value);
  }

  public reject(error: Error): Void {
    if (this._isCompleted) {
      return;
    }
    this._isCompleted = true;
    this._rejecter(error);
  }
}
