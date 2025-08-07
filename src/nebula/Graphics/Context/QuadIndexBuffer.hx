package nebula.graphics.context;

import nebula.util.Log;

import haxe.io.UInt16Array;
import haxe.io.UInt32Array;

enum BufferType {
  Uint16(data:UInt16Array);
  Uint32(data:UInt32Array);
}

/**
 * Helper that defines and index buffer for quad geometry
 *
 * Index buffers allow you to save space in vertex buffers when you share vertices in geometry
 * it is almost always worth it in terms of performance to use an index buffer.
 */
class QuadIndexBuffer {
  private var _gl: WebGL2RenderingContext;
  private var _logger: Logger = Logger.getInstance();
  /**
   * Access to the webgl buffer handle
   */
  public var buffer: WebGLBuffer;
  /**
   * Access to the raw data of the index buffer
   */
  public var bufferData: BufferType;
  /**
   * Depending on the browser this is either gl.UNSIGNED_SHORT or gl.UNSIGNED_INT
   */
  public var bufferGlType: Int;

  /**
   * @param gl WebGL2RenderingContext this layout will be attached to, these cannot be reused across contexts.
   * @param numberOfQuads Specify the max number of quads you want to draw
   * @param useUint16 Optionally force a uint16 buffer
   */
  public function new(gl: WebGL2RenderingContext, numberOfQuads: Int, ?useUint16: Bool) {
    this._gl = gl;
    this.buffer = gl.createBuffer()!;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.buffer);

    final totalVertices = numberOfQuads * 6;

    if (!useUint16) {
      this.bufferData = new Uint32Array(totalVertices);
    } else {
      // fall back to using gl.UNSIGNED_SHORT or tell the user they are out of luck
      final maxUint16 = 65_535;
      final maxUint16Index = Math.floor((maxUint16 - 1) / 4); // max quads

      this.bufferGlType = gl.UNSIGNED_SHORT;
      this.bufferData = new Uint16Array(totalVertices);
      // TODO Should we error if this happens?? maybe not might crash mid game
      if (numberOfQuads > maxUint16Index) {
        this._logger.warn(
          'Total quads exceeds hardware index buffer limit (uint16), max(${maxUint16Index}) requested quads(${numberOfQuads})'
        );
      }
    }

    var currentQuad = 0;
    var i = 0;
    while (i < totalVertices) {
      // first triangle
      this.bufferData[i + 0] = currentQuad + 0;
      this.bufferData[i + 1] = currentQuad + 1;
      this.bufferData[i + 2] = currentQuad + 2;
      // second triangle
      this.bufferData[i + 3] = currentQuad + 2;
      this.bufferData[i + 4] = currentQuad + 1;
      this.bufferData[i + 5] = currentQuad + 3;
      currentQuad += 4;
      i += 6;
    }
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.bufferData, gl.STATIC_DRAW);
  }

  public var size(get, never): Int;
  function get_size() {
    return this.bufferData.length;
  }

  /**
   * Upload data to the GPU
   */
  public function upload() {
    final gl = this._gl;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.buffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.bufferData, gl.STATIC_DRAW);
  }

  /**
   * Bind this index buffer
   */
  public function bind() {
    final gl = this._gl;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.buffer);
  }

  public function dispose() {
    final gl = this._gl;
    gl.deleteBuffer(this.buffer);
    this._gl = null;
  }
}
