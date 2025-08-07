package nebula.graphics.context.pointrenderer;

import nebula.math.Vector;
import nebula.Color;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

import nebula.graphics.context.Renderer;
import nebula.graphics.context.Shader;
import nebula.graphics.context.VertexBuffer;
import nebula.graphics.context.VertexLayout;

import nebula.graphics.GraphicsDiagnostics;

// import pointVertexSource from './point-vertex.glsl?raw';
// import pointFragmentSource from './point-fragment.glsl?raw';

class PointRenderer implements RendererPlugin {
  public var type = 'ex.point';
  public var priority: Int = 0;
  private var _shader: Shader;
  private var _maxPoints: Int = 10922;
  private var _buffer: VertexBuffer;
  private var _layout: VertexLayout;
  private var _gl: WebGLRenderingContext;
  private var _context: ExcaliburGraphicsContextWebGL;
  private var _pointCount: Int = 0;
  private var _vertexIndex: Int = 0;
  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void {
    this._gl = gl;
    this._context = context;
    this._shader = new Shader({
      graphicsContext: context,
      vertexSource: pointVertexSource,
      fragmentSource: pointFragmentSource
    });
    this._shader.compile();
    this._shader.use();
    this._shader.setUniformMatrix('u_matrix', this._context.ortho);
    this._buffer = new VertexBuffer({
      gl: gl,
      size: 7 * this._maxPoints,
      type: 'dynamic'
    });

    this._layout = new VertexLayout({
      gl: gl,
      shader: this._shader,
      vertexBuffer: this._buffer,
      attributes: [
        ['a_position', 2],
        ['a_color', 4],
        ['a_size', 1]
      ]
    });
  }

  public function dispose() {
    this._buffer.dispose();
    this._shader.dispose();
    this._context = null;
    this._gl = null;
  }

  function draw(point: Vector, color: Color, size: Int): Void {
    // Force a render if the batch is full
    if (this._isFull()) {
      this.flush();
    }

    this._pointCount++;

    final transform = this._context.getTransform();
    final opacity = this._context.opacity;
    final snapToPixel = this._context.snapToPixel;

    final finalPoint = transform.multiply(point);

    if (snapToPixel) {
      finalPoint.x = ~~(finalPoint.x + pixelSnapEpsilon);
      finalPoint.y = ~~(finalPoint.y + pixelSnapEpsilon);
    }

    final vertexBuffer = this._buffer.bufferData;
    vertexBuffer[this._vertexIndex++] = finalPoint.x;
    vertexBuffer[this._vertexIndex++] = finalPoint.y;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a * opacity;
    vertexBuffer[this._vertexIndex++] = size * Math.max(transform.getScaleX(), transform.getScaleY());
  }

  private function _isFull() {
    if (this._pointCount >= this._maxPoints) {
      return true;
    }
    return false;
  }

  function hasPendingDraws(): Bool {
    return this._pointCount != 0;
  }

  function flush(): Void {
    // nothing to draw early exit
    if (this._pointCount == 0) {
      return;
    }

    final gl = this._gl;
    this._shader.use();
    this._layout.use(true);

    this._shader.setUniformMatrix('u_matrix', this._context.ortho);

    gl.drawArrays(gl.POINTS, 0, this._pointCount);

    GraphicsDiagnostics.DrawnImagesCount += this._pointCount;
    GraphicsDiagnostics.DrawCallCount++;

    this._pointCount = 0;
    this._vertexIndex = 0;
  }
}
