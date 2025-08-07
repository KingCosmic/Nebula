package nebula.graphics.context;

interface UniformBufferOptions {
  /**
   * WebGL2RenderingContext this layout will be attached to, these cannot be reused across contexts.
   */
  var gl: WebGL2RenderingContext;
  /**
   * Size in number of floats, so [4.2, 4.0, 2.1] is size = 3
   *
   * **NOTE It is recommended you use multiples of 4's to avoid hardware implemenetation bugs, vec4's the the most supported**
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

class UniformBuffer {
  // TODO provide a struct layout?
  private var _gl: WebGL2RenderingContext;
  /**
   * Access to the webgl buffer handle
   */
  public var buffer: WebGLBuffer;
  public var bufferData: Float32Array;
  public var type: String = 'static';
  private var _maxFloats: Any;
  public function new(options: UniformBufferOptions) {
    final gl = options.gl,
          size = options.size,
          type = options.type,
          data = options.data;
    
    this._gl = gl;
    this.buffer = gl.createBuffer()!;
    this._maxFloats = gl.getParameter(gl.MAX_UNIFORM_BLOCK_SIZE) / 32;
    if (!data && !size) {
      throw Error('Must either provide data or a size to the UniformBuffer');
    }

    if (!data) {
      this.bufferData = new Float32Array(size!);
    } else {
      this.bufferData = data;
    }

    if (this.bufferData.length > this._maxFloats) {
      throw Error('UniformBuffer exceeds browsers allowed number of floats ${this._maxFloats}');
    }
    this.type = type ?? this.type;
    // Allocate buffer
    gl.bindBuffer(gl.UNIFORM_BUFFER, this.buffer);
    gl.bufferData(gl.UNIFORM_BUFFER, this.bufferData, this.type == 'static' ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
  }

  /**
   * Bind this uniform buffer
   */
  function bind() {
    final gl = this._gl;
    gl.bindBuffer(gl.UNIFORM_BUFFER, this.buffer);
  }

  function unbind() {
    final gl = this._gl;
    gl.bindBuffer(gl.UNIFORM_BUFFER, null);
  }

  function upload(?count: Int) {
    final gl = this._gl;
    gl.bindBuffer(gl.UNIFORM_BUFFER, this.buffer);
    if (count) {
      gl.bufferSubData(gl.UNIFORM_BUFFER, 0, this.bufferData, 0, count);
    } else {
      gl.bufferData(gl.UNIFORM_BUFFER, this.bufferData, this.type == 'static' ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
    }
  }

  function dispose() {
    final gl = this._gl;
    gl.deleteBuffer(this.buffer);
    this._gl = null;
  }
}
