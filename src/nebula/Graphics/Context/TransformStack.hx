package nebula.graphics.context;

import nebula.math.AffineMatrix;
import nebula.util.RentalPool;

class TransformStack {
  private var _pool = new RentalPool(
    () -> AffineMatrix.identity(),
    (mat) -> mat.reset(),
    100
  );
  private var _transforms: Array<AffineMatrix> = [];

  private var _currentTransform: AffineMatrix = this._pool.rent(true);

  public function save(): Void {
    this._transforms.push(this._currentTransform);
    this._currentTransform = this._currentTransform.clone(this._pool.rent());
  }

  public function restore(): Void {
    this._pool.remove(this._currentTransform);
    this._currentTransform = this._transforms.pop()!;
  }

  public function translate(x: Int, y: Int): AffineMatrix {
    return this._currentTransform.translate(x, y);
  }

  public function rotate(angle: Int): AffineMatrix {
    return this._currentTransform.rotate(angle);
  }

  public function scale(x: Int, y: Int): AffineMatrix {
    return this._currentTransform.scale(x, y);
  }

  public function reset(): Void {
    this._currentTransform.reset();
  }

  public var current(get, set): AffineMatrix;
  function set_current(matrix: AffineMatrix) {
    this._currentTransform = matrix;
  }
  function get_current(): AffineMatrix {
    return this._currentTransform;
  }
}
