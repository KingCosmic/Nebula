package nebula.graphics.context;

import nebula.GarbageCollector;
import nebula.util.Log;
import nebula.graphics.Filtering;
import nebula.graphics.ImageSource;
import nebula.graphics.Wrapping;
import nebula.graphics.context.ExcaliburGraphicsContext;

/**
 * Manages loading image sources into webgl textures, a unique id is associated with all sources
 */
class TextureLoader {
  private static var _LOGGER = Logger.getInstance();

  public function new(
    gl: WebGL2RenderingContext,
    ?_garbageCollector: {
      garbageCollector: GarbageCollector,
      collectionInterval: Int,
    }
  ) {
    this._gl = gl;
    TextureLoader._MAX_TEXTURE_SIZE = gl.getParameter(gl.MAX_TEXTURE_SIZE);
    if (this._garbageCollector) {
      TextureLoader._LOGGER.debug('WebGL Texture collection interval:', this._garbageCollector.collectionInterval);
      this._garbageCollector.garbageCollector?.registerCollector('texture', this._garbageCollector.collectionInterval, this._collect);
    }
  }

  public function dispose() {
    for (image => val in this._textureMap) {
      this.delete(image);
    }
    this._textureMap.clear();
    this._gl = null;
  }

  /**
   * Sets the default filtering for the Excalibur texture loader, default {@apilink ImageFiltering.Blended}
   */
  public static var filtering: ImageFiltering = ImageFiltering.Blended;
  public static var wrapping: ImageWrapConfiguration = { x: ImageWrapping.Clamp, y: ImageWrapping.Clamp };

  private var _gl: WebGL2RenderingContext;

  private var _textureMap = new Map<HTMLImageSource, WebGLTexture>();

  private static var _MAX_TEXTURE_SIZE: Int = 4096;

  /**
   * Get the WebGL Texture from a source image
   * @param image
   */
  public function get(image: HTMLImageSource): WebGLTexture {
    return this._textureMap.get(image)!;
  }

  /**
   * Returns whether a source image has been loaded as a texture
   * @param image
   */
  public function has(image: HTMLImageSource): Bool {
    return this._textureMap.has(image)!;
  }

  /**
   * Loads a graphic into webgl and returns it's texture info, a webgl context must be previously registered
   * @param image Source graphic
   * @param options {ImageSourceOptions} Optionally configure the ImageFiltering and ImageWrapping mode to apply to the loaded texture
   * @param forceUpdate Optionally force a texture to be reloaded, useful if the source graphic has changed
   */
  public function load(image: HTMLImageSource, ?options: ImageSourceOptions, forceUpdate = false): Null<WebGLTexture> {
    // Ignore loading if webgl is not registered
    final gl = this._gl;
    if (!gl) {
      return null;
    }

    final filtering = options.filtering;
    final wrapping = options.wrapping;

    var tex: Null<WebGLTexture> = null;
    // If reuse the texture if it's from the same source
    if (this.has(image)) {
      tex = this.get(image);
    }

    // Update existing webgl texture and return early
    if (tex) {
      if (forceUpdate) {
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
      }
      this._garbageCollector?.garbageCollector.touch(image);
      return tex;
    }

    // No texture exists create a new one
    tex = gl.createTexture();

    // TODO implement texture gc with weakmap and timer
    TextureLoader.checkImageSizeSupportedAndLog(image);

    gl.bindTexture(gl.TEXTURE_2D, tex);

    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);

    var wrappingConfig: Null<ImageWrapConfiguration>;
    if (wrapping) {
      if (Std.isOfType(wrapping, String)) {
        wrappingConfig = {
          x: wrapping,
          y: wrapping
        };
      } else {
        wrappingConfig = {
          x: wrapping.x,
          y: wrapping.y
        };
      }
    }
    final config = wrappingConfig ?? TextureLoader.wrapping;

    final xWrap = config.x;
    final yWrap = config.y;

    switch (xWrap) {
      case ImageWrapping.Clamp:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        break;
      case ImageWrapping.Repeat:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        break;
      case ImageWrapping.Mirror:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT);
        break;
      default:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    }
    switch (yWrap) {
      case ImageWrapping.Clamp:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        break;
      case ImageWrapping.Repeat:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        break;
      case ImageWrapping.Mirror:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
        break;
      default:
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    }

    // NEAREST for pixel art, LINEAR for hi-res
    final filterMode = filtering ?? TextureLoader.filtering;

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filterMode == ImageFiltering.Pixel ? gl.NEAREST : gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filterMode == ImageFiltering.Pixel ? gl.NEAREST : gl.LINEAR);

    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);

    this._textureMap.set(image, tex!);
    this._garbageCollector?.garbageCollector.addCollectableResource('texture', image);
    return tex;
  }

  public function delete(image: HTMLImageSource): Void {
    // Ignore loading if webgl is not registered
    final gl = this._gl;
    if (!gl) {
      return;
    }

    if (this.has(image)) {
      final texture = this.get(image);
      if (texture) {
        this._textureMap.delete(image);
        gl.deleteTexture(texture);
      }
    }
  }

  /**
   * Takes an image and returns if it meets size criteria for hardware
   * @param image
   * @returns if the image will be supported at runtime
   */
  public static function checkImageSizeSupportedAndLog(image: HTMLImageSource) {
    final originalSrc = image.dataset.originalSrc ?? 'internal canvas bitmap';
    if (image.width > TextureLoader._MAX_TEXTURE_SIZE || image.height > TextureLoader._MAX_TEXTURE_SIZE) {
      TextureLoader._LOGGER.error(
        'The image [${originalSrc}] provided to Excalibur is too large for the device\'s maximum texture size of ' +
          '(${TextureLoader._MAX_TEXTURE_SIZE}x${TextureLoader._MAX_TEXTURE_SIZE}) please resize to an image ' +
          'for excalibur to render properly.\n\nImages will likely render as black rectangles.\n\n' +
          'Read more here: https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices#understand_system_limits'
      );
      return false;
    } else if (image.width > 4096 || image.height > 4096) {
      // https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices#understand_system_limits
      TextureLoader._LOGGER.warn(
        'The image [${originalSrc}] provided to excalibur is too large may not work on all mobile devices, ' +
          'it is recommended you resize images to a maximum (4096x4096).\n\n' +
          'Images will likely render as black rectangles on some mobile platforms.\n\n' +
          'Read more here: https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices#understand_system_limits'
      );
    }
    return true;
  }

  /**
   * Looks for textures that haven't been drawn in a while
   */
  private var _collect = (image: HTMLImageSource) -> {
    if (this._gl) {
      final name = image.dataset.originalSrc ?? image.constructor.name;
      TextureLoader._LOGGER.debug('WebGL Texture for ${name} collected');
      this.delete(image);
      return true;
    }
    return false;
  };
}
