package nebula.graphics.context;

class RenderSource {
  public function new(
    _gl: WebGLRenderingContext,
    _texture: WebGLTexture
  ) {}

  public function use() {
    final gl = this._gl;
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this._texture);
  }

  public function disable() {
    final gl = this._gl;
    gl.bindTexture(gl.TEXTURE_2D, null);
  }
}
