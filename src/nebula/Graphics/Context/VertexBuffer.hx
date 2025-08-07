package nebula.graphics.context;

interface VertexBufferOptions {
  /**
   * WebGL2RenderingContext this layout will be attached to, these cannot be reused across contexts.
   */
  var gl: WebGL2RenderingContext;
  /**
   * Size in number of floats, so [4.2, 4.0, 2.1] is size = 3
   *
   * Ignored if data is passed directly
   */
  var size: Null<Int>;
  /**
   * If the vertices never change switching 'static' can be more efficient on the gpu
   *
   * Default is 'dynamic'
   */
  var type: Null<String>;

  /**
   * Optionally pass pre-seeded data, size parameter is ignored
   */
  var data: Null<Float32Array>;
}

/**
 * Helper around vertex buffer to simplify creating and uploading geometry
 *
 * Under the hood uses Float32Array
 */
class VertexBuffer {
  private var _gl: WebGL2RenderingContext;

  /**
   * Access to the webgl buffer handle
   */
  public var buffer: WebGLBuffer;
  /**
   * Access to the raw data of the vertex buffer
   */
  public var bufferData: Float32Array;

  /**
   * If the vertices never change switching 'static' can be more efficient on the gpu
   *
   * Default is 'dynamic'
   */
  public var type: String = 'dynamic';

  public function new(options: VertexBufferOptions) {
    final gl = options.gl,
          size = options.size,
          type = options.type,
          data = options.data;

    this._gl = gl;
    this.buffer = this._gl.createBuffer()!;
    if (!data && !size) {
      throw Error('Must either provide data or a size to the VertexBuffer');
    }

    if (!data) {
      this.bufferData = new Float32Array(size!);
    } else {
      this.bufferData = data;
    }
    this.type = type ?? this.type;
    // Allocate buffer
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
    gl.bufferData(gl.ARRAY_BUFFER, this.bufferData, this.type == 'static' ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
  }

  /**
   * Bind this vertex buffer
   */
  function bind() {
    final gl = this._gl;
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
  }

  function unbind() {
    final gl = this._gl;
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
  }

  /**
   * Upload vertex buffer geometry to the GPU
   */
  function upload(?count: Int) {
    final gl = this._gl;
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
    if (count) {
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, this.bufferData, 0, count);
    } else {
      // TODO always use bufferSubData? need to perf test it
      gl.bufferData(gl.ARRAY_BUFFER, this.bufferData, this.type == 'static' ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
    }
  }

  function dispose() {
    final gl = this._gl;
    gl.deleteBuffer(this.buffer);
    this._gl = null;
  }
}
