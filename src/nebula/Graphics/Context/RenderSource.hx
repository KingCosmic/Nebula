package nebula.Graphics.Context;

class RenderSource {
  public function new(
    private _gl: WebGLRenderingContext,
    private _texture: WebGLTexture
  ) {}

  public use() {
    final gl = this._gl;
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this._texture);
  }

  public disable() {
    final gl = this._gl;
    gl.bindTexture(gl.TEXTURE_2D, null);
  }
}
