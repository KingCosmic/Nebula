package nebula.graphics.context;

import nebula.graphics.context.RenderSource;

interface RenderTargetOptions {
  var gl: WebGL2RenderingContext;
  var width: Int;
  var height: Int;
  var transparency: Bool;
  /**
   * Optionally enable render buffer multisample anti-aliasing
   *
   * By default false
   */
  var antialias: Null<Bool>;
  /**
   * Optionally specify number of anti-aliasing samples to use
   *
   * By default the max for the platform is used if antialias is on.
   */
  var samples: Null<Int>;
}

class RenderTarget {
  var width: Int;
  var height: Int;
  var transparency: Bool;
  var antialias: Bool = false;
  var samples: Int = 1;
  private var _gl: WebGL2RenderingContext;
  public var bufferFormat: Int;
  public function new(options: RenderTargetOptions) {
    this._gl = options.gl;
    this.width = options.width;
    this.height = options.height;
    this.transparency = options.transparency;
    this.antialias = options.antialias ?? this.antialias;
    this.samples = options.samples ?? this._gl.getParameter(this._gl.MAX_SAMPLES);

    final gl = this._gl;
    // Determine current context format for blitting later needs to match
    if (gl.drawingBufferFormat) {
      this.bufferFormat = gl.drawingBufferFormat;
    } else {
      // Documented in webgl spec
      // https://registry.khronos.org/webgl/specs/latest/1.0/
      if (this.transparency) {
        this.bufferFormat = gl.RGBA8;
      } else {
        this.bufferFormat = gl.RGB8;
      }
    }

    this._setupRenderBuffer();
    this._setupFramebuffer();
  }

  function setResolution(width: Int, height: Int) {
    final gl = this._gl;
    this.width = width;
    this.height = height;

    // update backing texture size
    gl.bindTexture(gl.TEXTURE_2D, this._frameTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

    // update render buffer size
    if (this._renderBuffer) {
      gl.bindRenderbuffer(gl.RENDERBUFFER, this._renderBuffer);
      gl.renderbufferStorageMultisample(
        gl.RENDERBUFFER,
        Math.min(this.samples, gl.getParameter(gl.MAX_SAMPLES)),
        this.bufferFormat,
        this.width,
        this.height
      );
    }
  }

  private var _renderBuffer: WebGLRenderbuffer;
  public var renderBuffer(get, never): WebGLFramebuffer;
  function get_renderBuffer() {
    return this._renderBuffer;
  }

  private var _renderFrameBuffer: WebGLFramebuffer;
  public var renderFrameBuffer(get, never): WebGLFramebuffer;
  function get_renderFrameBuffer() {
    return this._renderFrameBuffer;
  }

  private var _frameBuffer: WebGLFramebuffer;
  public var frameBuffer(get, never): WebGLFramebuffer;
  function get_frameBuffer() {
    return this._frameBuffer;
  }

  private var _frameTexture: WebGLTexture;
  public var frameTexture(get, never): WebGLTexture;
  function get_frameTexture() {
    return this._frameTexture;
  }

  private function _setupRenderBuffer() {
    if (this.antialias) {
      final gl = this._gl;
      // Render buffers can be used as an input to a shader
      this._renderBuffer = gl.createRenderbuffer()!;
      this._renderFrameBuffer = gl.createFramebuffer()!;
      gl.bindRenderbuffer(gl.RENDERBUFFER, this._renderBuffer);
      gl.renderbufferStorageMultisample(
        gl.RENDERBUFFER,
        Math.min(this.samples, gl.getParameter(gl.MAX_SAMPLES)),
        this.bufferFormat,
        this.width,
        this.height
      );
      gl.bindFramebuffer(gl.FRAMEBUFFER, this._renderFrameBuffer);
      gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, this._renderBuffer);
    }
  }

  private function _setupFramebuffer() {
    // Allocates frame buffer
    final gl = this._gl;
    this._frameTexture = gl.createTexture()!;
    gl.bindTexture(gl.TEXTURE_2D, this._frameTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

    // set the filtering so we don't need mips
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    // attach the texture as the first color attachment
    final attachmentPoint = gl.COLOR_ATTACHMENT0;

    // After this bind all draw calls will draw to this framebuffer texture
    this._frameBuffer = gl.createFramebuffer()!;
    gl.bindFramebuffer(gl.FRAMEBUFFER, this._frameBuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, attachmentPoint, gl.TEXTURE_2D, this._frameTexture, 0);

    // Reset after initialized
    this.disable();
  }

  public function toRenderSource() {
    if (this.renderBuffer) {
      this.blitRenderBufferToFrameBuffer();
    }
    final source = new RenderSource(this._gl, this._frameTexture);
    return source;
  }

  public function blitToScreen() {
    final gl = this._gl;
    // set to size of canvas's drawingBuffer
    if (this._renderBuffer) {
      gl.bindFramebuffer(gl.READ_FRAMEBUFFER, this.renderFrameBuffer);
      gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
      gl.clearBufferfv(gl.COLOR, 0, [0.0, 0.0, 1.0, 1.0]);
      gl.blitFramebuffer(0, 0, this.width, this.height, 0, 0, this.width, this.height, gl.COLOR_BUFFER_BIT, gl.LINEAR);
    } else {
      gl.bindFramebuffer(gl.READ_FRAMEBUFFER, this.frameBuffer);
      gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
      gl.clearBufferfv(gl.COLOR, 0, [0.0, 0.0, 1.0, 1.0]);
      gl.blitFramebuffer(0, 0, this.width, this.height, 0, 0, this.width, this.height, gl.COLOR_BUFFER_BIT, gl.LINEAR);
    }
  }

  public function blitRenderBufferToFrameBuffer() {
    if (this._renderBuffer) {
      final gl = this._gl;
      gl.bindFramebuffer(gl.READ_FRAMEBUFFER, this.renderFrameBuffer);
      gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, this.frameBuffer);
      gl.clearBufferfv(gl.COLOR, 0, [0.0, 0.0, 1.0, 1.0]);
      gl.blitFramebuffer(0, 0, this.width, this.height, 0, 0, this.width, this.height, gl.COLOR_BUFFER_BIT, gl.LINEAR);
    }
  }

  public function copyToTexture(texture: WebGLTexture) {
    final gl = this._gl;
    if (this._renderBuffer) {
      this.blitRenderBufferToFrameBuffer();
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, this._frameBuffer);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.copyTexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 0, 0, this.width, this.height, 0);
  }

  /**
   * When called, all drawing gets redirected to this render target
   */
  public function use() {
    final gl = this._gl;
    if (this.antialias) {
      gl.bindFramebuffer(gl.FRAMEBUFFER, this._renderFrameBuffer);
    } else {
      gl.bindFramebuffer(gl.FRAMEBUFFER, this._frameBuffer);
    }

    // very important to set the viewport to the size of the framebuffer texture
    gl.viewport(0, 0, this.width, this.height);
  }

  /**
   * When called, all drawing is sent back to the canvas
   */
  public function disable() {
    final gl = this._gl;
    // passing null switches rendering back to the canvas
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindTexture(gl.TEXTURE_2D, null);
  }
}
