package nebula.graphics.context.circlerenderer;

import nebula.Color;
import nebula.math.Vector;

import nebula.graphics.GraphicsDiagnostics;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

import nebula.graphics.context.QuadIndexBuffer;

import nebula.graphics.context.Renderer;
import nebula.graphics.context.Shader;
import nebula.graphics.context.VertexBuffer;
import nebula.graphics.context.VertexLayout;

// import frag from './circle-renderer.frag.glsl?raw';
// import vert from './circle-renderer.vert.glsl?raw';

class CircleRenderer implements RendererPlugin {
  public var type = 'ex.circle';
  public var priority: Int = 0;

  private var _maxCircles: Int = 10922; // max(uint16) / 6 verts

  private var _shader: Shader;
  private var _context: ExcaliburGraphicsContextWebGL;
  private var _gl: WebGLRenderingContext;
  private var _buffer: VertexBuffer;
  private var _layout: VertexLayout;
  private var _quads: QuadIndexBuffer;

  private var _circleCount: Int = 0;
  private var _vertexIndex: Int = 0;

  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void {
    this._gl = gl;
    this._context = context;
    this._shader = new Shader({
      graphicsContext: context,
      fragmentSource: frag,
      vertexSource: vert
    });
    this._shader.compile();

    // setup uniforms
    this._shader.use();
    this._shader.setUniformMatrix('u_matrix', context.ortho);

    this._buffer = new VertexBuffer({
      gl: gl,
      size: 14 * 4 * this._maxCircles,
      type: 'dynamic'
    });

    this._layout = new VertexLayout({
      gl: gl,
      shader: this._shader,
      vertexBuffer: this._buffer,
      attributes: [
        ['a_position', 2],
        ['a_uv', 2],
        ['a_opacity', 1],
        ['a_color', 4],
        ['a_strokeColor', 4],
        ['a_strokeThickness', 1]
      ]
    });

    this._quads = new QuadIndexBuffer(gl, this._maxCircles, true);
  }

  public function dispose() {
    this._buffer.dispose();
    this._quads.dispose();
    this._shader.dispose();
    this._context = null;
    this._gl = null;
  }

  private function _isFull() {
    if (this._circleCount >= this._maxCircles) {
      return true;
    }
    return false;
  }

  function draw(pos: Vector, radius: Int, color: Color, stroke: Color = Color.Transparent, strokeThickness: Int = 0): Void {
    if (this._isFull()) {
      this.flush();
    }
    this._circleCount++;

    // transform based on current context
    final transform = this._context.getTransform();
    final opacity = this._context.opacity;
    final snapToPixel = this._context.snapToPixel;

    final topLeft = transform.multiply(pos.add(vec(-radius, -radius)));
    final topRight = transform.multiply(pos.add(vec(radius, -radius)));
    final bottomRight = transform.multiply(pos.add(vec(radius, radius)));
    final bottomLeft = transform.multiply(pos.add(vec(-radius, radius)));

    if (snapToPixel) {
      topLeft.x = ~~(topLeft.x + pixelSnapEpsilon);
      topLeft.y = ~~(topLeft.y + pixelSnapEpsilon);

      topRight.x = ~~(topRight.x + pixelSnapEpsilon);
      topRight.y = ~~(topRight.y + pixelSnapEpsilon);

      bottomLeft.x = ~~(bottomLeft.x + pixelSnapEpsilon);
      bottomLeft.y = ~~(bottomLeft.y + pixelSnapEpsilon);

      bottomRight.x = ~~(bottomRight.x + pixelSnapEpsilon);
      bottomRight.y = ~~(bottomRight.y + pixelSnapEpsilon);
    }

    // TODO UV could be static vertex buffer
    final uvx0 = 0;
    final uvy0 = 0;
    final uvx1 = 1;
    final uvy1 = 1;

    // update data
    final vertexBuffer = this._layout.vertexBuffer.bufferData;

    // (0, 0) - 0
    vertexBuffer[this._vertexIndex++] = topLeft.x;
    vertexBuffer[this._vertexIndex++] = topLeft.y;
    vertexBuffer[this._vertexIndex++] = uvx0;
    vertexBuffer[this._vertexIndex++] = uvy0;
    vertexBuffer[this._vertexIndex++] = opacity;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;
    vertexBuffer[this._vertexIndex++] = stroke.r / 255;
    vertexBuffer[this._vertexIndex++] = stroke.g / 255;
    vertexBuffer[this._vertexIndex++] = stroke.b / 255;
    vertexBuffer[this._vertexIndex++] = stroke.a;
    vertexBuffer[this._vertexIndex++] = strokeThickness / radius;

    // (0, 1) - 1
    vertexBuffer[this._vertexIndex++] = bottomLeft.x;
    vertexBuffer[this._vertexIndex++] = bottomLeft.y;
    vertexBuffer[this._vertexIndex++] = uvx0;
    vertexBuffer[this._vertexIndex++] = uvy1;
    vertexBuffer[this._vertexIndex++] = opacity;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;
    vertexBuffer[this._vertexIndex++] = stroke.r / 255;
    vertexBuffer[this._vertexIndex++] = stroke.g / 255;
    vertexBuffer[this._vertexIndex++] = stroke.b / 255;
    vertexBuffer[this._vertexIndex++] = stroke.a;
    vertexBuffer[this._vertexIndex++] = strokeThickness / radius;

    // (1, 0) - 2
    vertexBuffer[this._vertexIndex++] = topRight.x;
    vertexBuffer[this._vertexIndex++] = topRight.y;
    vertexBuffer[this._vertexIndex++] = uvx1;
    vertexBuffer[this._vertexIndex++] = uvy0;
    vertexBuffer[this._vertexIndex++] = opacity;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;
    vertexBuffer[this._vertexIndex++] = stroke.r / 255;
    vertexBuffer[this._vertexIndex++] = stroke.g / 255;
    vertexBuffer[this._vertexIndex++] = stroke.b / 255;
    vertexBuffer[this._vertexIndex++] = stroke.a;
    vertexBuffer[this._vertexIndex++] = strokeThickness / radius;

    // (1, 1) - 3
    vertexBuffer[this._vertexIndex++] = bottomRight.x;
    vertexBuffer[this._vertexIndex++] = bottomRight.y;
    vertexBuffer[this._vertexIndex++] = uvx1;
    vertexBuffer[this._vertexIndex++] = uvy1;
    vertexBuffer[this._vertexIndex++] = opacity;
    vertexBuffer[this._vertexIndex++] = color.r / 255;
    vertexBuffer[this._vertexIndex++] = color.g / 255;
    vertexBuffer[this._vertexIndex++] = color.b / 255;
    vertexBuffer[this._vertexIndex++] = color.a;
    vertexBuffer[this._vertexIndex++] = stroke.r / 255;
    vertexBuffer[this._vertexIndex++] = stroke.g / 255;
    vertexBuffer[this._vertexIndex++] = stroke.b / 255;
    vertexBuffer[this._vertexIndex++] = stroke.a;
    vertexBuffer[this._vertexIndex++] = strokeThickness / radius;
  }

  function hasPendingDraws(): Bool {
    return this._circleCount != 0;
  }

  function flush(): Void {
    // nothing to draw early exit
    if (this._circleCount == 0) {
      return;
    }

    final gl = this._gl;
    // Bind the shader
    this._shader.use();

    // Bind the memory layout and upload data
    this._layout.use(true);

    // Update ortho matrix uniform
    this._shader.setUniformMatrix('u_matrix', this._context.ortho);

    // Bind index buffer
    this._quads.bind();

    // Draw all the quads
    gl.drawElements(gl.TRIANGLES, this._circleCount * 6, this._quads.bufferGlType, 0);

    GraphicsDiagnostics.DrawnImagesCount += this._circleCount;
    GraphicsDiagnostics.DrawCallCount++;

    // Reset
    this._circleCount = 0;
    this._vertexIndex = 0;
  }
}
