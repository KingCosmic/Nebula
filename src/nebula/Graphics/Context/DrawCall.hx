package nebula.Graphics.Context

import nebula.Math.AffineMatrix;

import nebula.Color;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

class DrawCall {
  public z: Int = 0;
  public priority: Int = 0;
  public renderer: String = '';
  public transform: AffineMatrix = AffineMatrix.identity();
  public state: ExcaliburGraphicsContextState = {
    z: 0,
    opacity: 1,
    tint: Color.White,
    material: null
  };
  public args: any[] = new Array(10);
}
