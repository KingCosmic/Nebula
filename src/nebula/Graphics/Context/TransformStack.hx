package nebula.Graphics.Context;

import nebula.Math.AffineMatrix;
import nebula.Util.RentalPool;

class TransformStack {
  private _pool = new RentalPool(
    () => AffineMatrix.identity(),
    (mat) => mat.reset(),
    100
  );
  private _transforms: AffineMatrix[] = [];

  private _currentTransform: AffineMatrix = this._pool.rent(true);

  public save(): Void {
    this._transforms.push(this._currentTransform);
    this._currentTransform = this._currentTransform.clone(this._pool.rent());
  }

  public restore(): Void {
    this._pool.return(this._currentTransform);
    this._currentTransform = this._transforms.pop()!;
  }

  public translate(x: Int, y: Int): AffineMatrix {
    return this._currentTransform.translate(x, y);
  }

  public rotate(angle: Int): AffineMatrix {
    return this._currentTransform.rotate(angle);
  }

  public scale(x: Int, y: Int): AffineMatrix {
    return this._currentTransform.scale(x, y);
  }

  public reset(): Void {
    this._currentTransform.reset();
  }

  public set current(matrix: AffineMatrix) {
    this._currentTransform = matrix;
  }

  public get current(): AffineMatrix {
    return this._currentTransform;
  }
}
