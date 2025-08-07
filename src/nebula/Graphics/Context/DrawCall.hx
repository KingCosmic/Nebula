package nebula.graphics.context;

import nebula.math.AffineMatrix;

import nebula.Color;

import nebula.graphics.context.ExcaliburGraphicsContext;

class DrawCall {
  public var z: Int = 0;
  public var priority: Int = 0;
  public var renderer: String = '';
  public var transform: AffineMatrix = AffineMatrix.identity();
  public var state: ExcaliburGraphicsContextState = {
    z: 0,
    opacity: 1,
    tint: Color.White,
    material: null
  };
  public var args: Array<Any> = new Array(10);
}
