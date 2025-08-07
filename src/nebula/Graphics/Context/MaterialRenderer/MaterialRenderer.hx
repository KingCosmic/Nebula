package nebula.graphics.context.materialrenderer;

import nebula.math.Vector;

import nebula.graphics.Filtering;
import nebula.graphics.GraphicsDiagnostics;
import nebula.graphics.ImageSource;
import nebula.graphics.Wrapping;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

import nebula.graphics.context.QuadIndexBuffer;
import nebula.graphics.context.Renderer;
import nebula.graphics.context.VertexBuffer;
import nebula.graphics.context.VertexLayout;

class MaterialRenderer implements RendererPlugin {
  public var type: String = 'ex.material';
  public var priority: Int = 0;
  // private _maxTextures = 8;
  private var _context: ExcaliburGraphicsContextWebGL;
  private var _gl: WebGL2RenderingContext;
  private var _textures: Array<WebGLTexture> = [];
  private var _quads: Any;
  private var _buffer: VertexBuffer;
  private var _layout: VertexLayout;
  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void {
    this._gl = gl;
    this._context = context;

    // Setup memory layout
    this._buffer = new VertexBuffer({
      gl: gl,
      size: 6 * 4, // 6 components * 4 verts
      type: 'dynamic'
    });

    // Setup a vertex layout/buffer to the material
    this._layout = new VertexLayout({
      gl: gl,
      vertexBuffer: this._buffer,
      attributes: [
        ['a_position', 2],
        ['a_uv', 2],
        ['a_screenuv', 2]
      ],
      suppressWarnings: true
    });

    // Setup index buffer
    this._quads = new QuadIndexBuffer(gl, 1, true);
  }

  public function dispose() {
    this._buffer.dispose();
    this._quads.dispose();
    this._textures.length = 0;
    this._context = null;
    this._gl = null;
  }

  function draw(
    image: HTMLImageSource,
    sx: Int,
    sy: Int,
    ?swidth: Int,
    ?sheight: Int,
    ?dx: Int,
    ?dy: Int,
    ?dwidth: Int,
    ?dheight: Int
  ): Void {
    final gl = this._gl;

    // Extract context info
    final material = this._context.material;
    if (!material) {
      return;
    }

    final transform = this._context.getTransform();
    final opacity = this._context.opacity;

    // material shader
    final shader = material.getShader()!;

    // construct geometry, or hold on to it in the material?
    // geometry primitive for drawing rectangles?
    // update data
    final vertexBuffer = this._layout.vertexBuffer.bufferData;
    var vertexIndex = 0;

    var width = image?.width || swidth || 0;
    var height = image?.height || sheight || 0;
    var view = [0, 0, swidth ?? image?.width ?? 0, sheight ?? image?.height ?? 0];
    var dest = [sx ?? 1, sy ?? 1];
    // If destination is specified, update view and dest
    if (dx != null && dy != null && dwidth != null && dheight != null) {
      view = [sx ?? 1, sy ?? 1, swidth ?? image?.width ?? 0, sheight ?? image?.height ?? 0];
      dest = [dx, dy];
      width = dwidth;
      height = dheight;
    }

    sx = view[0];
    sy = view[1];
    final sw = view[2];
    final sh = view[3];

    final topLeft = vec(dest[0], dest[1]);
    final topRight = vec(dest[0] + width, dest[1]);
    final bottomLeft = vec(dest[0], dest[1] + height);
    final bottomRight = vec(dest[0] + width, dest[1] + height);

    final imageWidth = image.width || width;
    final imageHeight = image.height || height;

    final uvx0 = sx / imageWidth;
    final uvy0 = sy / imageHeight;
    final uvx1 = (sx + sw - 0.01) / imageWidth;
    final uvy1 = (sy + sh - 0.01) / imageHeight;

    final topLeftScreen = transform.getPosition();
    final bottomRightScreen = topLeftScreen.add(bottomRight);
    final screenUVX0 = topLeftScreen.x / this._context.width;
    final screenUVY0 = topLeftScreen.y / this._context.height;
    final screenUVX1 = bottomRightScreen.x / this._context.width;
    final screenUVY1 = bottomRightScreen.y / this._context.height;

    // (0, 0) - 0
    vertexBuffer[vertexIndex++] = topLeft.x;
    vertexBuffer[vertexIndex++] = topLeft.y;
    vertexBuffer[vertexIndex++] = uvx0;
    vertexBuffer[vertexIndex++] = uvy0;
    vertexBuffer[vertexIndex++] = screenUVX0;
    vertexBuffer[vertexIndex++] = screenUVY0;

    // (0, 1) - 1
    vertexBuffer[vertexIndex++] = bottomLeft.x;
    vertexBuffer[vertexIndex++] = bottomLeft.y;
    vertexBuffer[vertexIndex++] = uvx0;
    vertexBuffer[vertexIndex++] = uvy1;
    vertexBuffer[vertexIndex++] = screenUVX0;
    vertexBuffer[vertexIndex++] = screenUVY1;

    // (1, 0) - 2
    vertexBuffer[vertexIndex++] = topRight.x;
    vertexBuffer[vertexIndex++] = topRight.y;
    vertexBuffer[vertexIndex++] = uvx1;
    vertexBuffer[vertexIndex++] = uvy0;
    vertexBuffer[vertexIndex++] = screenUVX1;
    vertexBuffer[vertexIndex++] = screenUVY0;

    // (1, 1) - 3
    vertexBuffer[vertexIndex++] = bottomRight.x;
    vertexBuffer[vertexIndex++] = bottomRight.y;
    vertexBuffer[vertexIndex++] = uvx1;
    vertexBuffer[vertexIndex++] = uvy1;
    vertexBuffer[vertexIndex++] = screenUVX1;
    vertexBuffer[vertexIndex++] = screenUVY1;

    // This creates and uploads the texture if not already done
    final texture = this._addImageAsTexture(image);

    // apply material
    material.use();

    this._layout.shader = shader!;
    // apply layout and geometry
    this._layout.use(true);

    // apply time in ms since the page (performance.now())
    shader.trySetUniformFloat('u_time_ms', performance.now());

    // apply opacity
    shader.trySetUniformFloat('u_opacity', opacity);

    // apply resolution
    shader.trySetUniformFloatVector('u_resolution', vec(this._context.width, this._context.height));

    // apply graphic resolution
    shader.trySetUniformFloatVector('u_graphic_resolution', vec(imageWidth, imageHeight));

    // apply size
    shader.trySetUniformFloatVector('u_size', vec(sw, sh));

    // apply orthographic projection
    shader.trySetUniformMatrix('u_matrix', this._context.ortho);

    // apply geometry transform
    shader.trySetUniformMatrix('u_transform', transform.to4x4());

    // bind graphic image texture 'uniform sampler2D u_graphic;'
    gl.activeTexture(gl.TEXTURE0 + 0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    shader.trySetUniformInt('u_graphic', 0);

    // bind the screen texture
    if (material.isUsingScreenTexture) {
      gl.activeTexture(gl.TEXTURE0 + 1);
      gl.bindTexture(gl.TEXTURE_2D, this._context.materialScreenTexture);
      shader.trySetUniformInt('u_screen_texture', 1);
    }

    // bind quad index buffer
    this._quads.bind();

    // Draw a single quad
    gl.drawElements(gl.TRIANGLES, 6, this._quads.bufferGlType, 0);

    GraphicsDiagnostics.DrawnImagesCount++;
    GraphicsDiagnostics.DrawCallCount++;
  }

  private function _addImageAsTexture(image: HTMLImageSource) {
    final maybeFiltering = image.getAttribute(ImageSourceAttributeConstants.Filtering);
    final filtering = maybeFiltering ? parseImageFiltering(maybeFiltering) : undefined;
    final wrapX = parseImageWrapping(image.getAttribute(ImageSourceAttributeConstants.WrappingX));
    final wrapY = parseImageWrapping(image.getAttribute(ImageSourceAttributeConstants.WrappingY));

    final force = image.getAttribute('forceUpload') == 'true' ? true : false;
    final texture = this._context.textureLoader.load(
      image,
      {
        filtering: filtering,
        wrapping: { x: wrapX, y: wrapY }
      },
      force
    )!;
    // remove force attribute after upload
    image.removeAttribute('forceUpload');
    if (this._textures.indexOf(texture) == -1) {
      this._textures.push(texture);
    }

    return texture;
  }

  function hasPendingDraws(): Bool {
    return false;
  }
  function flush(): Void {
    // flush does not do anything, material renderer renders immediately per draw
  }
}
