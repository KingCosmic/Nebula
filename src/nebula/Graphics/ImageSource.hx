package nebula.graphics;

import nebula.resources.Resource;

import nebula.graphics.Sprite;
import nebula.graphics.Filtering;

import nebula.interfaces.Loadable;

import nebula.util.Log;
import nebula.util.Future;

import nebula.graphics.context.TextureLoader;

import nebula.graphics.Wrapping;
import nebula.graphics.Graphic;

interface ImageSourceOptions {
  var filtering: Null<ImageFiltering>;
  var wrapping: Null<ImageWrapConfiguration>;
  var bustCache: Null<Bool>;
}

interface ImageWrapConfiguration {
  var x: ImageWrapping;
  var y: ImageWrapping;
}

final ImageSourceAttributeConstants = {
  Filtering: 'filtering',
  WrappingX: 'wrapping-x',
  WrappingY: 'wrapping-y'
};

class ImageSource implements Loadable<HTMLImageElement> {
  private var _logger = Logger.getInstance();
  private var _resource: Resource<Blob>;
  public var filtering: Null<ImageFiltering>;
  public var wrapping: Null<ImageWrapConfiguration>;

  /**
   * The original size of the source image in pixels
   */
  public var width(get, never): Int;
  function get_width() {
    return this.image.naturalWidth;
  }

  /**
   * The original height of the source image in pixels
   */
  public var height(get, never): Int;
  function get_height() {
    return this.image.naturalHeight;
  }

  private var _src: Null<String>;
  /**
   * Returns true if the Texture is completely loaded and is ready
   * to be drawn.
   */
  public function isLoaded(): Bool {
    if (!this._src) {
      // this boosts speed of access
      this._src = this.data.src;
    }
    return !!this._src;
  }

  /**
   * Access to the underlying html image element
   */
  public var data: HTMLImageElement = new Image();
  public var image(get, never): HTMLImageElement;
  function get_image(): HTMLImageElement {
    return this.data;
  }

  private var _readyFuture = new Future<HTMLImageElement>();
  /**
   * Promise the resolves when the image is loaded and ready for use, does not initiate loading
   */
  public var ready: Promise<HTMLImageElement> = this._readyFuture.promise;

  public var path: String;

  /**
   * The path to the image, can also be a data url like 'data:image/'
   * @param pathOrBase64 {string} Path to the image resource relative from the HTML document hosting the game, or absolute
   * @param options
   */
  public function new(pathOrBase64: String, ?options: ImageSourceOptions);
  /**
   * The path to the image, can also be a data url like 'data:image/'
   * @param pathOrBase64 {string} Path to the image resource relative from the HTML document hosting the game, or absolute
   * @param bustCache {boolean} Should excalibur add a cache busting querystring?
   * @param filtering {ImageFiltering} Optionally override the image filtering set by {@apilink EngineOptions.antialiasing}
   */
  public function new(pathOrBase64: String, bustCache: Bool, ?filtering: ImageFiltering);
  public function new(pathOrBase64: String, bustCacheOrOptions: Null<Any>, ?filtering: ImageFiltering) {
    this.path = pathOrBase64;
    var bustCache: Null<Bool> = false;
    var wrapping: Null<Any>;
    if (Std.isOfType(bustCacheOrOptions, Bool)) {
      bustCache = bustCacheOrOptions;
    } else {
      bustCache = bustCacheOrOptions.bustCache;
      wrapping = bustCacheOrOptions.wrapping;
      filtering = bustCacheOrOptions.filtering;
    }
    this._resource = new Resource(pathOrBase64, 'blob', bustCache);
    this.filtering = filtering ?? this.filtering;
    if (Std.isOfType(wrapping, String)) {
      this.wrapping = {
        x: wrapping,
        y: wrapping
      };
    } else {
      this.wrapping = wrapping ?? this.wrapping;
    }
    if (pathOrBase64.endsWith('.gif')) {
      this._logger.warn(
        'Use the ex.Gif type to load gifs, you may have mixed results with ${pathOrBase64} in ex.ImageSource. Fully supported: svg, jpg, bmp, and png'
      );
    }
  }

  /**
   * Create an ImageSource from and HTML <image> tag element
   * @param image
   */
  static function fromHtmlImageElement(image: HTMLImageElement, ?options: ImageSourceOptions) {
    final imageSource = new ImageSource('');
    imageSource._src = 'image-element';
    imageSource.data = image;
    imageSource.data.setAttribute('data-original-src', 'image-element');

    if (options && options.filtering) {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.Filtering, options.filtering);
    } else {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.Filtering, ImageFiltering.Blended);
    }

    if (options && options.wrapping) {
      var wrapping: ImageWrapConfiguration;
      if (Std.isOfType(options.wrapping, String)) {
        wrapping = {
          x: options.wrapping,
          y: options.wrapping
        };
      } else {
        wrapping = {
          x: options.wrapping.x,
          y: options.wrapping.y
        };
      }
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingX, wrapping.x);
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingY, wrapping.y);
    } else {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingX, ImageWrapping.Clamp);
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingY, ImageWrapping.Clamp);
    }

    TextureLoader.checkImageSizeSupportedAndLog(image);
    imageSource._readyFuture.resolve(image);
    return imageSource;
  }

  static function fromHtmlCanvasElement(image: HTMLCanvasElement, ?options: ImageSourceOptions): ImageSource {
    final imageSource = new ImageSource('');
    imageSource._src = 'canvas-element-blob';
    imageSource.data.setAttribute('data-original-src', 'canvas-element-blob');

    if (options && options.filtering) {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.Filtering, options.filtering);
    } else {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.Filtering, ImageFiltering.Blended);
    }

    if (options && options.wrapping) {
      var wrapping: ImageWrapConfiguration;
      if (Std.isOfType(options.wrapping, String)) {
        wrapping = {
          x: options.wrapping,
          y: options.wrapping
        };
      } else {
        wrapping = {
          x: options.wrapping.x,
          y: options.wrapping.y
        };
      }
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingX, wrapping.x);
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingY, wrapping.y);
    } else {
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingX, ImageWrapping.Clamp);
      imageSource.data.setAttribute(ImageSourceAttributeConstants.WrappingY, ImageWrapping.Clamp);
    }

    TextureLoader.checkImageSizeSupportedAndLog(image);

    image.toBlob((blob) -> {
      // TODO throw? if blob null?
      final url = URL.createObjectURL(blob!);
      imageSource.image.onload = () -> {
        // no longer need to read the blob so it's revoked
        URL.revokeObjectURL(url);
        imageSource.data = imageSource.image;
        imageSource._readyFuture.resolve(imageSource.image);
      };
      imageSource.image.src = url;
    });

    return imageSource;
  }

  static function fromSvgString(svgSource: String, ?options: ImageSourceOptions) {
    final blob = new Blob([svgSource], { type: 'image/svg+xml' });
    final url = URL.createObjectURL(blob);
    return new ImageSource(url, options);
  }

  /**
   * Should excalibur add a cache busting querystring? By default false.
   * Must be set before loading
   */
  public var bustCache(get, set): Bool;
  function get_bustCache() {
    return this._resource.bustCache;
  }

  function set_bustCache(val: Bool) {
    this._resource.bustCache = val;
  }

  /**
   * Begins loading the image and returns a promise that resolves when the image is loaded
   */
  function load(): Promise<HTMLImageElement> {
    if (this.isLoaded()) {
      return this.data;
    }
    try {
      // Load base64 or blob if needed
      var url: String;
      if (!this.path.includes('data:image/')) {
        final blob = this._resource.load();
        url = URL.createObjectURL(blob);
      } else {
        url = this.path;
      }

      // Decode the image
      final image = new Image();
      // Use Image.onload over Image.decode()
      // https://bugs.chromium.org/p/chromium/issues/detail?id=1055828#c7
      // Otherwise chrome will throw still Image.decode() failures for large textures
      final loadedFuture = new Future<Void>();
      image.onload = () -> loadedFuture.resolve();
      image.src = url;
      image.setAttribute('data-original-src', this.path);

      // await loadedFuture.promise;

      // Set results
      // We defer loading the texture into webgl until the first draw that way we avoid a singleton
      // and for the multi-engine case the texture needs to be created in EACH webgl context to work
      // See image-renderer.ts draw()
      this.data = image;

      // emit warning if potentially too big
      TextureLoader.checkImageSizeSupportedAndLog(this.data);
    } catch (error: Any) {
      throw 'Error loading ImageSource from path \'${this.path}\' with error [${error.message}]';
    }
    // Do a bad thing to pass the filtering as an attribute
    this.data.setAttribute(ImageSourceAttributeConstants.Filtering, this.filtering); // TODO fix type
    this.data.setAttribute(ImageSourceAttributeConstants.WrappingX, this.wrapping?.x ?? ImageWrapping.Clamp);
    this.data.setAttribute(ImageSourceAttributeConstants.WrappingY, this.wrapping?.y ?? ImageWrapping.Clamp);

    // todo emit complete
    this._readyFuture.resolve(this.data);
    return this.data;
  }

  /**
   * Build a sprite from this ImageSource
   */
  public function toSprite(?options: Omit<GraphicOptions & SpriteOptions, 'image'>): Sprite {
    return Sprite.from(this, options);
  }

  /**
   * Unload images from memory
   */
  function unload(): Void {
    this.data = new Image();
  }
}
