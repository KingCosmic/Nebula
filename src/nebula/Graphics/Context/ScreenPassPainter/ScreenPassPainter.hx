package nebula.graphics.context.screenpasspainter;

import nebula.graphics.context.Shader;
import nebula.graphics.context.VertexBuffer;
import nebula.graphics.context.VertexLayout;

import nebula.graphics.postprocessor.PostProcessor;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

// import screenVertex from './screen-vertex.glsl?raw';
// import screenFragment from './screen-fragment.glsl?raw';

/**
 * This is responsible for painting the entire screen during the render passes
 */
class ScreenPassPainter {
  private var _gl: WebGLRenderingContext;
  private var _shader: Shader;
  private var _buffer: VertexBuffer;
  private var _layout: VertexLayout;
  public function new(context: ExcaliburGraphicsContextWebGL) {
    final gl = context.__gl;
    this._gl = gl;
    this._shader = new Shader({
      graphicsContext: context,
      vertexSource: screenVertex,
      fragmentSource: screenFragment
    });
    this._shader.compile();
    // Setup memory layout
    this._buffer = new VertexBuffer({
      gl: gl,
      type: 'static',
      // clip space quad + uv since we don't need a camera
      data: new Float32Array([
        -1, -1, 0, 0, -1, 1, 0, 1, 1, -1, 1, 0,

        1, -1, 1, 0, -1, 1, 0, 1, 1, 1, 1, 1
      ])
    });
    this._layout = new VertexLayout({
      gl: gl,
      shader: this._shader,
      vertexBuffer: this._buffer,
      attributes: [
        ['a_position', 2],
        ['a_texcoord', 2]
      ]
    });
    this._buffer.upload();
  }

  function renderWithPostProcessor(postprocessor: PostProcessor): Void {
    final gl = this._gl;
    final shader = postprocessor.getShader();
    shader.use();
    postprocessor.getLayout().use();
    gl.activeTexture(gl.TEXTURE0);
    shader.trySetUniformInt('u_image', 0);
    if (postprocessor.onDraw) {
      postprocessor.onDraw();
    }
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }

  function renderToScreen(): Void {
    final gl = this._gl;
    this._shader.use();
    this._layout.use();
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }
}
