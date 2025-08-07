package nebula.graphics.context.linerenderer;

import nebula.math.Vector;
import nebula.Color;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

import nebula.graphics.context.Renderer;
import nebula.graphics.context.Shader;
import nebula.graphics.context.VertexBuffer;
import nebula.graphics.context.VertexLayout;
import nebula.graphics.GraphicsDiagnostics;

// import lineVertexSource from './line-vertex.glsl?raw';
// import lineFragmentSource from './line-fragment.glsl?raw';

interface LineOptions {
  var color: Null<Color>;
  var width: Null<Int>;
}

class LineRenderer implements RendererPlugin {
  public var type = 'ex.line';
  public var priority: Int = 0;
  private var _context: ExcaliburGraphicsContextWebGL;
  private var _gl: WebGL2RenderingContext;
  private var _shader: Shader;
  private var _maxLines: Int = 10922;
  private var _vertexBuffer: VertexBuffer;
  private var _layout: VertexLayout;
  private var _vertexIndex = 0;
  private var _lineCount = 0;
  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void {
    this._gl = gl;
    this._context = context;
    this._shader = new Shader({
      graphicsContext: context,
      vertexSource: lineVertexSource,
      fragmentSource: lineFragmentSource
    });
    this._shader.compile();
    this._shader.use();

    this._shader.setUniformMatrix('u_matrix', this._context.ortho);

    this._vertexBuffer = new VertexBuffer({
      gl: gl,
      size: 6 * 2 * this._maxLines,
      type: 'dynamic'
    });

    this._layout = new VertexLayout({
      gl: gl,
      vertexBuffer: this._vertexBuffer,
      shader: this._shader,
      attributes: [
        ['a_position', 2],
        ['a_color', 4]
      ]
    });
  }

  public function dispose() {
    this._vertexBuffer.dispose();
    this._shader.dispose();
    this._context = null;
    this._gl = null;
  }

  private var _startScratch = vec(0, 0);
  private var _endScratch = vec(0, 0);
  function draw(start: Vector, end: Vector, color: Color): Void {
    // Force a render if the batch is full
    if (this._isFull()) {
      this.flush();
    }

    this._lineCount++;

    final transform = this._context.getTransform();
    final finalStart = transform.multiply(start, this._startScratch);
    final finalEnd = transform.multiply(end, this._endScratch);

    final vertexBuffer = this._vertexBuffer.bufferData;
    // Start
    vertexBuffer[this._vertexIndex++] = finalStart.x;
    vertexBuffer[this._vertexIndex++] = finalStart.y;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;

    // End
    vertexBuffer[this._vertexIndex++] = finalEnd.x;
    vertexBuffer[this._vertexIndex++] = finalEnd.y;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;
  }

  private function _isFull() {
    if (this._lineCount >= this._maxLines) {
      return true;
    }
    return false;
  }

  function hasPendingDraws(): Bool {
    return this._lineCount != 0;
  }

  function flush(): Void {
    // nothing to draw early exit
    if (this._lineCount == 0) {
      return;
    }

    final gl = this._gl;
    this._shader.use();
    this._layout.use(true);

    this._shader.setUniformMatrix('u_matrix', this._context.ortho);

    gl.drawArrays(gl.LINES, 0, this._lineCount * 2); // 2 verts per line

    GraphicsDiagnostics.DrawnImagesCount += this._lineCount;
    GraphicsDiagnostics.DrawCallCount++;

    // reset
    this._vertexIndex = 0;
    this._lineCount = 0;
  }
}
