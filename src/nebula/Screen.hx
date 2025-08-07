package nebula;

import nebula.math.Vector;
import nebula.util.Log;
import nebula.Camera;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.util.Util;
import nebula.graphics.context.ExcaliburGraphicsContextWebGL;
import nebula.graphics.context.ExcaliburGraphicsContext2DCanvas;
import nebula.EventEmitter;

/**
 * Enum representing the different display modes available to Excalibur.
 */
enum DisplayMode {
  /**
   * Default, use a specified resolution for the game. Like 800x600 pixels for example.
   */
  Fixed;

  /**
   * Fit the aspect ratio given by the game resolution within the container at all times will fill any gaps with canvas.
   * The displayed area outside the aspect ratio is not guaranteed to be on the screen, only the {@apilink Screen.contentArea}
   * is guaranteed to be on screen.
   */
  FitContainerAndFill;

  /**
   * Fit the aspect ratio given by the game resolution the screen at all times will fill the screen.
   * This displayed area outside the aspect ratio is not guaranteed to be on the screen, only the {@apilink Screen.contentArea}
   * is guaranteed to be on screen.
   */
  FitScreenAndFill;

  /**
   * Fit the viewport to the parent element maintaining aspect ratio given by the game resolution, but zooms in to avoid the black bars
   * (letterbox) that would otherwise be present in {@apilink FitContainer}.
   *
   * **warning** This will clip some drawable area from the user because of the zoom,
   * use {@apilink Screen.contentArea} to know the safe to draw area.
   */
  FitContainerAndZoom;

  /**
   * Fit the viewport to the device screen maintaining aspect ratio given by the game resolution, but zooms in to avoid the black bars
   * (letterbox) that would otherwise be present in {@apilink FitScreen}.
   *
   * **warning** This will clip some drawable area from the user because of the zoom,
   * use {@apilink Screen.contentArea} to know the safe to draw area.
   */
  FitScreenAndZoom;

  /**
   * Fit to screen using as much space as possible while maintaining aspect ratio and resolution.
   * This is not the same as {@apilink Screen.enterFullscreen} but behaves in a similar way maintaining aspect ratio.
   *
   * You may want to center your game here is an example
   * ```html
   * <!-- html -->
   * <body>
   * <main>
   *   <canvas id="game"></canvas>
   * </main>
   * </body>
   * ```
   *
   * ```css
   * // css
   * main {
   *   display: flex;
   *   align-items: center;
   *   justify-content: center;
   *   height: 100%;
   *   width: 100%;
   * }
   * ```
   */
  FitScreen;

  /**
   * Fill the entire screen's css width/height for the game resolution dynamically. This means the resolution of the game will
   * change dynamically as the window is resized. This is not the same as {@apilink Screen.enterFullscreen}
   */
  FillScreen;

  /**
   * Fit to parent element width/height using as much space as possible while maintaining aspect ratio and resolution.
   */
  FitContainer;

  /**
   * Use the parent DOM container's css width/height for the game resolution dynamically
   */
  FillContainer;
}

/**
 * Convenience class for quick resolutions
 * Mostly sourced from https://emulation.gametechwiki.com/index.php/Resolution
 */
class Resolution {
  public static var SVGA(get, never): Resolution;
  static function get_SVGA(): Resolution {
    return { width: 800, height: 600 };
  }

  public static var Standard(get, never): Resolution;
  static function get_Standard(): Resolution {
    return { width: 1920, height: 1080 };
  }

  public static var Atari2600(get, never): Resolution;
  static function get_Atari2600(): Resolution {
    return { width: 160, height: 192 };
  }

  public static var GameBoy(get, never): Resolution;
  static function get_GameBoy(): Resolution {
    return { width: 160, height: 144 };
  }

  public static var GameBoyAdvance(get, never): Resolution;
  static function get_GameBoyAdvance(): Resolution {
    return { width: 240, height: 160 };
  }

  public static var NintendoDS(get, never): Resolution;
  static function get_NintendoDS(): Resolution {
    return { width: 256, height: 192 };
  }

  public static var NES(get, never): Resolution;
  static function get_NES(): Resolution {
    return { width: 256, height: 224 };
  }

  public static var SNES(get, never): Resolution;
  static function get_SNES(): Resolution {
    return { width: 256, height: 244 };
  }
}

enum ViewportUnit {
  Pixel;
  Percent;
}

interface IResolution {
  var width: Int;
  var height: Int;
}

interface ViewportDimension {
  var widthUnit: Null<ViewportUnit>;
  var heightUnit: Null<ViewportUnit>;
  var width: Int;
  var height: Int;
}

enum CanvasImageRendering {
  Auto;
  Pixelated;
}

interface ScreenOptions {
  /**
   * Canvas element to build a screen on
   */
  var canvas: HTMLCanvasElement;

  /**
   * Graphics context for the screen
   */
  var context: ExcaliburGraphicsContext;

  /**
   * Browser abstraction
   */
  var browser: BrowserEvents;
  /**
   * Optionally set antialiasing, defaults to true. If set to true, images will be smoothed
   */
  var antialiasing: Null<Bool>;

  /**
   * Optionally set the image rendering CSS hint on the canvas element, default is auto
   */
  var canvasImageRendering: CanvasImageRendering;
  /**
   * Optionally override the pixel ratio to use for the screen, otherwise calculated automatically from the browser
   */
  var pixelRatio: Null<Float>;
  /**
   * Optionally specify the actual pixel resolution in width/height pixels (also known as logical resolution), by default the
   * resolution will be the same as the viewport. Resolution will be overridden by {@apilink DisplayMode.FillContainer} and
   * {@apilink DisplayMode.FillScreen}.
   */
  var resolution: Null<Resolution>;
  /**
   * Visual viewport size in css pixel, if resolution is not specified it will be the same as the viewport
   */
  var viewport: ViewportDimension;
  /**
   * Set the display mode of the screen, by default DisplayMode.Fixed.
   */
  var displayMode: Null<DisplayMode>;
}

/**
 * Fires when the screen resizes, useful if you have logic that needs to be aware of resolution/viewport constraints
 */
interface ScreenResizeEvent {
  /**
   * Current viewport in css pixels of the screen
   */
  var viewport: ViewportDimension;
  /**
   * Current resolution in world pixels of the screen
   */
  var resolution: Resolution;
}

/**
 * Fires when the pixel ratio changes, useful to know if you've moved to a hidpi screen or back
 */
interface PixelRatioChangeEvent {
  /**
   * Current pixel ratio of the screen
   */
  var pixelRatio: Float;
}

/**
 * Fires when the browser fullscreen api is successfully engaged or disengaged
 */
interface FullScreenChangeEvent {
  /**
   * Current fullscreen state
   */
  var fullscreen: Bool;
}

/**
 * Built in events supported by all entities
 */
typedef TScreenEvents = {
  /**
   * Fires when the screen resizes, useful if you have logic that needs to be aware of resolution/viewport constraints
   */
  var resize: ScreenResizeEvent;
  /**
   * Fires when the pixel ratio changes, useful to know if you've moved to a hidpi screen or back
   */
  var pixelratio: PixelRatioChangeEvent;
  /**
   * Fires when the browser fullscreen api is successfully engaged or disengaged
   */
  var fullscreen: FullScreenChangeEvent;
};

final ScreenEvents = {
  ScreenResize: 'resize',
  PixelRatioChange: 'pixelratio',
  FullScreenChange: 'fullscreen'
};

/**
 * The Screen handles all aspects of interacting with the screen for Excalibur.
 */
class Screen {
  public var graphicsContext: ExcaliburGraphicsContext;
  /**
   * Listen to screen events {@apilink ScreenEvents}
   */
  public var events = new EventEmitter<ScreenEvents>();
  private var _canvas: Any;
  private var _antialiasing: Bool = true;
  private var _canvasImageRendering: CanvasImageRendering = 'auto';
  private var _contentResolution: Resolution;
  private var _browser: Any;
  private var _camera: Camera;
  private var _resolution: Resolution;
  private var _resolutionStack: Array<Resolution> = [];
  private var _viewport: ViewportDimension;
  private var _viewportStack: Array<ViewportDimension> = [];
  private var _pixelRatioOverride: Null<Float> = null;
  private var _displayMode: DisplayMode;
  private var _isFullscreen = false;
  private var _mediaQueryList: Any;
  private var _isDisposed = false;
  private var _logger = Logger.getInstance();
  private var _resizeObserver: Any;

  public function new(options: ScreenOptions) {
    this.viewport = options.viewport;
    this.resolution = options.resolution ?? Object.spreadWith(this.viewport, {});
    this._contentResolution = this.resolution;
    this._displayMode = options.displayMode ?? DisplayMode.Fixed;
    this._canvas = options.canvas;
    this.graphicsContext = options.context;
    this._antialiasing = options.antialiasing ?? this._antialiasing;
    this._canvasImageRendering = options.canvasImageRendering ?? this._canvasImageRendering;
    this._browser = options.browser;
    this._pixelRatioOverride = options.pixelRatio;

    this._applyDisplayMode();

    this._listenForPixelRatio();

    this._canvas.addEventListener('fullscreenchange', this._fullscreenChangeHandler);
    this.applyResolutionAndViewport();
  }

  private function _listenForPixelRatio() {
    if (this._mediaQueryList && !this._mediaQueryList.addEventListener) {
      // Safari <=13.1 workaround, remove any existing handlers
      this._mediaQueryList.removeListener(this._pixelRatioChangeHandler);
    }
    this._mediaQueryList = this._browser.window.nativeComponent.matchMedia('(resolution: ${window.devicePixelRatio}dppx)');

    // Safari <=13.1 workaround
    if (this._mediaQueryList.addEventListener) {
      this._mediaQueryList.addEventListener('change', this._pixelRatioChangeHandler, { once: true });
    } else {
      this._mediaQueryList.addListener(this._pixelRatioChangeHandler);
    }
  }

  public function dispose(): Void {
    if (!this._isDisposed) {
      // Clean up handlers
      this._isDisposed = true;
      this.events.clear();
      this._browser.window.off('resize', this._resizeHandler);
      this._browser.window.clear();
      if (this._resizeObserver) {
        this._resizeObserver.disconnect();
      }
      this.parent.removeEventListener('resize', this._resizeHandler);
      // Safari <=13.1 workaround
      if (this._mediaQueryList.removeEventListener) {
        this._mediaQueryList.removeEventListener('change', this._pixelRatioChangeHandler);
      } else {
        this._mediaQueryList.removeListener(this._pixelRatioChangeHandler);
      }
      this._canvas.removeEventListener('fullscreenchange', this._fullscreenChangeHandler);
      this._canvas = null;
    }
  }

  private function _fullscreenChangeHandler() {
    if (this._isDisposed) {
      return;
    }
    this._isFullscreen = !this._isFullscreen;
    this._logger.debug('Fullscreen Change', this._isFullscreen);
    this.events.emit('fullscreen', {
      fullscreen: this.isFullscreen
    });
  };

  private function _pixelRatioChangeHandler() {
    if (this._isDisposed) {
      return;
    }
    this._logger.debug('Pixel Ratio Change', window.devicePixelRatio);
    this._listenForPixelRatio();
    this._devicePixelRatio = this._calculateDevicePixelRatio();
    this.applyResolutionAndViewport();

    this.events.emit('pixelratio', {
      pixelRatio: this.pixelRatio
    });
  };

  private function _resizeHandler() {
    if (this._isDisposed) {
      return;
    }
    final parent = this.parent;
    this._logger.debug('View port resized');
    this._setResolutionAndViewportByDisplayMode(parent);
    this.applyResolutionAndViewport();

    // Emit resize event
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  };

  private function _calculateDevicePixelRatio() {
    if (window.devicePixelRatio < 1) {
      return 1;
    }

    final devicePixelRatio = window.devicePixelRatio || 1;

    return devicePixelRatio;
  }

  // Asking the window.devicePixelRatio is expensive we do it once
  private var _devicePixelRatio = this._calculateDevicePixelRatio();

  /**
   * Returns the computed pixel ratio, first using any override, then the device pixel ratio
   */
  public var pixelRation(get, never): Float;
  function get_pixelRatio(): Float {
    if (this._pixelRatioOverride) {
      return this._pixelRatioOverride;
    }

    return this._devicePixelRatio;
  }

  /**
   * This calculates the ratio between excalibur pixels and the HTML pixels.
   *
   * This is useful for scaling HTML UI so that it matches your game.
   */
  public var worldToPagePixelRation(get, never): Float;
  function get_worldToPagePixelRatio(): Float {
    if (this._canvas) {
      final pageOrigin = this.worldToPageCoordinates(Vector.Zero);
      final pageDistance = this.worldToPageCoordinates(vec(1, 0)).sub(pageOrigin);
      final pixelConversion = pageDistance.x;
      return pixelConversion;
    } else {
      return 1;
    }
  }

  /**
   * Get or set the pixel ratio override
   *
   * You will need to call applyResolutionAndViewport() affect change on the screen
   */
  public var pixelRationOverride(get, set): Null<Float>;
  function get_pixelRatioOverride(): Null<Float> {
    return this._pixelRatioOverride;
  }

  function set_pixelRatioOverride(value: Null<Float>) {
    this._pixelRatioOverride = value;
  }

  public var isHiDpi(get, never): Bool;
  function get_isHiDpi(): Bool {
    return this.pixelRatio != 1;
  }

  public var displayMode(get, never): DisplayMode;
  function get_displayMode(): DisplayMode {
    return this._displayMode;
  }

  public var canvas(get, never): Any;
  function get_canvas(): Any {
    return this._canvas;
  }
  
  public var resolution(get, set): Resolution;
  function get_resolution(): Resolution {
    return this._resolution;
  }

  function set_resolution(resolution: Resolution) {
    this._resolution = resolution;
  }

  /**
   * Returns screen dimensions in pixels or percentage
   */
  public var viewport(get, set): ViewportDimension;
  function get_viewport(): ViewportDimension {
    if (this._viewport) {
      return this._viewport;
    }
    return this._resolution;
  }

  function set_viewport(viewport: ViewportDimension) {
    this._viewport = viewport;
  }

  public var aspectRation(get, never): Float;
  function get_aspectRatio() {
    return this._resolution.width / this._resolution.height;
  }

  public var scaledWidth(get, never): Float;
  function get_scaledWidth() {
    return this._resolution.width * this.pixelRatio;
  }

  public var scaledHeight(get, never): Float;
  function get_scaledHeight() {
    return this._resolution.height * this.pixelRatio;
  }

  public function setCurrentCamera(camera: Camera) {
    this._camera = camera;
  }

  public function pushResolutionAndViewport() {
    this._resolutionStack.push(this.resolution);
    this._viewportStack.push(this.viewport);

    this.resolution = this.resolution;
    this.viewport = this.viewport;
  }

  public function peekViewport(): ViewportDimension {
    return this._viewportStack[this._viewportStack.length - 1];
  }

  public function peekResolution(): Resolution {
    return this._resolutionStack[this._resolutionStack.length - 1];
  }

  public function popResolutionAndViewport() {
    if (this._resolutionStack.length && this._viewportStack.length) {
      this.resolution = this._resolutionStack.pop();
      this.viewport = this._viewportStack.pop();
    }
  }

  public function applyResolutionAndViewport() {
    if (Std.isTypeOf(this.graphicsContext, ExcaliburGraphicsContextWebGL)) {
      final scaledResolutionSupported = this.graphicsContext.checkIfResolutionSupported({
        width: this.scaledWidth,
        height: this.scaledHeight
      });
      if (!scaledResolutionSupported) {
        this._logger.warnOnce(
          'The currently configured resolution (${this.resolution.width}x${this.resolution.height}) and pixel ratio (${this.pixelRatio})' +
            ' are too large for the platform WebGL implementation, this may work but cause WebGL rendering to behave oddly.' +
            ' Try reducing the resolution or disabling Hi DPI scaling to avoid this' +
            ' (read more here https://excaliburjs.com/docs/screens#understanding-viewport--resolution).'
        );

        // Attempt to recover if the user hasn't configured a specific ratio for up scaling
        if (!this.pixelRatioOverride) {
          var currentPixelRatio = Math.max(1, this.pixelRatio - 0.5);
          var newResolutionSupported = false;
          while (currentPixelRatio > 1 && !newResolutionSupported) {
            currentPixelRatio = Math.max(1, currentPixelRatio - 0.5);
            final width = this._resolution.width * currentPixelRatio;
            final height = this._resolution.height * currentPixelRatio;
            newResolutionSupported = this.graphicsContext.checkIfResolutionSupported({ width: width, height: height });
          }
          this.pixelRatioOverride = currentPixelRatio;
          this._logger.warnOnce(
            'Scaled resolution too big attempted recovery!' +
              ' Pixel ratio was automatically reduced to (${this.pixelRatio}) to avoid 4k texture limit.' +
              ' Setting `ex.Engine({pixelRatio: ...}) will override any automatic recalculation, do so at your own risk.` ' +
              ' (read more here https://excaliburjs.com/docs/screens#understanding-viewport--resolution).'
          );
        }
      }
    }

    this._canvas.width = this.scaledWidth;
    this._canvas.height = this.scaledHeight;

    if (this._canvasImageRendering == 'auto') {
      this._canvas.style.imageRendering = 'auto';
    } else {
      this._canvas.style.imageRendering = 'pixelated';
      // Fall back to 'crisp-edges' if 'pixelated' is not supported
      // Currently for firefox https://developer.mozilla.org/en-US/docs/Web/CSS/image-rendering
      if (this._canvas.style.imageRendering == '') {
        this._canvas.style.imageRendering = 'crisp-edges';
      }
    }

    final widthUnit = this.viewport.widthUnit == 'percent' ? '%' : 'px';
    final heightUnit = this.viewport.heightUnit == 'percent' ? '%' : 'px';

    this._canvas.style.width = this.viewport.width + widthUnit;
    this._canvas.style.height = this.viewport.height + heightUnit;

    // After messing with the canvas width/height the graphics context is invalidated and needs to have some properties reset
    this.graphicsContext.updateViewport(this.resolution);
    this.graphicsContext.resetTransform();
    this.graphicsContext.smoothing = this._antialiasing;
    if (Std.isTypeOf(this.graphicsContext, ExcaliburGraphicsContext2DCanvas)) {
      this.graphicsContext.scale(this.pixelRatio, this.pixelRatio);
    }
    // Add the excalibur world pixel to page pixel
    document.documentElement.style.setProperty('--ex-pixel-ratio', this.worldToPagePixelRatio.toString());
  }

  /**
   * Get or set screen antialiasing,
   *
   * If true smoothing is applied
   */
  public var antialiasing(get, set): Bool;
  function get_antialiasing() {
    return this._antialiasing;
  }

  /**
   * Get or set screen antialiasing
   */
  function set_antialiasing(isSmooth: Bool) {
    this._antialiasing = isSmooth;
    this.graphicsContext.smoothing = this._antialiasing;
  }

  /**
   * Returns true if excalibur is fullscreen using the browser fullscreen api
   * @deprecated use isFullscreen()
   */
  public var isFullScreen(get, never): Bool;
  function get_isFullScreen(): Bool {
    return this._isFullscreen;
  }

  /**
   * Requests to go fullscreen using the browser fullscreen api, requires user interaction to be successful.
   * For example, wire this to a user click handler.
   *
   * Optionally specify a target element id to go fullscreen, by default the game canvas is used
   * @param elementId
   * @deprecated use enterFullscreen(...)
   */
  public function goFullScreen(?elementId: String): Promise<Void> {
    return this.enterFullscreen(elementId);
  }

  /**
   * Requests to enter fullscreen using the browser fullscreen api, requires user interaction to be successful.
   * For example, wire this to a user click handler.
   *
   * Optionally specify a target element id to go fullscreen, by default the game canvas is used
   * @param elementId
   */
  public function enterFullscreen(?elementId: String): Promise<Void> {
    if (elementId) {
      final maybeElement = document.getElementById(elementId);
      // workaround for safari partial support
      if (maybeElement?.requestFullscreen || maybeElement.webkitRequestFullscreen) {
        if (!maybeElement.getAttribute('ex-fullscreen-listener')) {
          maybeElement.setAttribute('ex-fullscreen-listener', 'true');
          maybeElement.addEventListener('fullscreenchange', this._fullscreenChangeHandler);
        }
        if (maybeElement.requestFullscreen) {
          return maybeElement.requestFullscreen() ?? Promise.resolve();
        } else if (maybeElement.webkitRequestFullscreen) {
          return maybeElement.webkitRequestFullscreen() ?? Promise.resolve();
        }
      }
    }
    if (this._canvas?.requestFullscreen) {
      return this._canvas?.requestFullscreen() ?? Promise.resolve();
    } else if (this._canvas.webkitRequestFullscreen) {
      return this._canvas.webkitRequestFullscreen() ?? Promise.resolve();
    }
    this._logger.warnOnce('Could not go fullscreen, is this an iPhone? Currently Apple does not support fullscreen on iPhones');
    return Promise.resolve();
  }

  /**
   * Requests to exit fullscreen using the browser fullscreen api
   * @deprecated use exitFullscreen()
   */
  public function exitFullScreen(): Promise<Void> {
    return this.exitFullscreen();
  }

  public function exitFullscreen(): Promise<Void> {
    return document.exitFullscreen();
  }

  private function _viewportToPixels(viewport: ViewportDimension) {
    return {
      width: viewport.widthUnit == 'percent' ? this.canvas.offsetWidth : viewport.width,
      height: viewport.heightUnit == 'percent' ? this.canvas.offsetHeight : viewport.height
    };
  }

  /**
   * Takes a coordinate in normal html page space, for example from a pointer move event, and translates it to
   * Excalibur screen space.
   *
   * Excalibur screen space starts at the top left (0, 0) corner of the viewport, and extends to the
   * bottom right corner (resolutionX, resolutionY). When using *AndFill suffixed display modes screen space
   * (0, 0) is the top left of the safe content area bounding box not the viewport.
   * @param point
   */
  public function pageToScreenCoordinates(point: Vector): Vector {
    var newX = point.x;
    var newY = point.y;

    if (!this._isFullscreen) {
      newX -= getPosition(this._canvas).x;
      newY -= getPosition(this._canvas).y;
    }

    var viewport = this._viewportToPixels(this.viewport);

    // if fullscreen api on it centers with black bars
    // we need to adjust the screen to world coordinates in this case
    if (this._isFullscreen) {
      if (window.innerWidth / this.aspectRatio < window.innerHeight) {
        var screenHeight = window.innerWidth / this.aspectRatio;
        var screenMarginY = (window.innerHeight - screenHeight) / 2;
        newY = ((newY - screenMarginY) / screenHeight) * viewport.height;
        newX = (newX / window.innerWidth) * viewport.width;
      } else {
        var screenWidth = window.innerHeight * this.aspectRatio;
        var screenMarginX = (window.innerWidth - screenWidth) / 2;
        newX = ((newX - screenMarginX) / screenWidth) * viewport.width;
        newY = (newY / window.innerHeight) * viewport.height;
      }
    }

    newX = (newX / viewport.width) * this.resolution.width;
    newY = (newY / viewport.height) * this.resolution.height;

    // offset by content area
    newX = newX - this.contentArea.left;
    newY = newY - this.contentArea.top;

    return new Vector(newX, newY);
  }

  /**
   * Takes a coordinate in Excalibur screen space, and translates it to normal html page space. For example,
   * this is where html elements might live if you want to position them relative to Excalibur.
   *
   * Excalibur screen space starts at the top left (0, 0) corner of the viewport, and extends to the
   * bottom right corner (resolutionX, resolutionY)
   * @param point
   */
  public function screenToPageCoordinates(point: Vector): Vector {
    var newX = point.x;
    var newY = point.y;

    // no need to offset by content area, drawing is already offset by this

    var viewport = this._viewportToPixels(this.viewport);

    newX = (newX / this.resolution.width) * viewport.width;
    newY = (newY / this.resolution.height) * viewport.height;

    if (this._isFullscreen) {
      if (window.innerWidth / this.aspectRatio < window.innerHeight) {
        var screenHeight = window.innerWidth / this.aspectRatio;
        var screenMarginY = (window.innerHeight - screenHeight) / 2;
        newY = (newY / viewport.height) * screenHeight + screenMarginY;
        newX = (newX / viewport.width) * window.innerWidth;
      } else {
        var screenWidth = window.innerHeight * this.aspectRatio;
        var screenMarginX = (window.innerWidth - screenWidth) / 2;
        newX = (newX / viewport.width) * screenWidth + screenMarginX;
        newY = (newY / viewport.height) * window.innerHeight;
      }
    }

    if (!this._isFullscreen) {
      newX += getPosition(this._canvas).x;
      newY += getPosition(this._canvas).y;
    }

    return new Vector(newX, newY);
  }

  /**
   * Takes a coordinate in Excalibur screen space, and translates it to Excalibur world space.
   *
   * World space is where {@apilink Entity | `entities`} in Excalibur live by default {@apilink CoordPlane.World}
   * and extends infinitely out relative from the {@apilink Camera}.
   * @param point  Screen coordinate to convert
   */
  public function screenToWorldCoordinates(point: Vector): Vector {
    // offset by content area
    point = point.add(vec(this.contentArea.left, this.contentArea.top));

    // the only difference between screen & world is the camera transform
    if (this._camera) {
      return this._camera.inverse.multiply(point);
    }
    return point.sub(vec(this.resolution.width / 2, this.resolution.height / 2));
  }

  /**
   * Takes a coordinate in Excalibur world space, and translates it to Excalibur screen space.
   *
   * Screen space is where {@apilink ScreenElement | `screen elements`} and {@apilink Entity | `entities`} with {@apilink CoordPlane.Screen} live.
   * @param point  World coordinate to convert
   */
  public function worldToScreenCoordinates(point: Vector): Vector {
    if (this._camera) {
      return this._camera.transform.multiply(point);
    }
    return point.add(vec(this.resolution.width / 2, this.resolution.height / 2));
  }

  public function pageToWorldCoordinates(point: Vector): Vector {
    var screen = this.pageToScreenCoordinates(point);
    return this.screenToWorldCoordinates(screen);
  }

  public function worldToPageCoordinates(point: Vector): Vector {
    var screen = this.worldToScreenCoordinates(point);
    return this.screenToPageCoordinates(screen);
  }

  /**
   * Returns a BoundingBox of the top left corner of the screen
   * and the bottom right corner of the screen.
   *
   * World bounds are in world coordinates, useful for culling objects offscreen that are in world space
   */
  public function getWorldBounds(): BoundingBox {
    var bounds = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Half)
      .scale(vec(1 / this._camera.zoom, 1 / this._camera.zoom))
      .rotate(this._camera.rotation)
      .translate(this._camera.drawPos);
    return bounds;
  }

  /**
   * Returns a BoundingBox of the top left corner of the screen and the bottom right corner of the screen.
   *
   * Screen bounds are in screen coordinates, useful for culling objects offscreen that are in screen space
   */
  public function getScreenBounds(): BoundingBox {
    var bounds = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Zero, Vector.Zero);
    return bounds;
  }

  /**
   * The width of the game canvas in pixels (physical width component of the
   * resolution of the canvas element)
   */
  public var canvasWidth(get, never): Int;
  function get_canvasWidth(): Int {
    return this.canvas.width;
  }

  /**
   * Returns half width of the game canvas in pixels (half physical width component)
   */
  public var halfCanvasWidth(get, never): Float;
  function get_halfCanvasWidth(): Float {
    return this.canvas.width / 2;
  }

  /**
   * The height of the game canvas in pixels, (physical height component of
   * the resolution of the canvas element)
   */
  public var canvasHeight(get, never): Int;
  function get_canvasHeight(): Int {
    return this.canvas.height;
  }

  /**
   * Returns half height of the game canvas in pixels (half physical height component)
   */
  public var halfCanvasHeight(get, never): Float;
  function get_halfCanvasHeight(): Float {
    return this.canvas.height / 2;
  }

  /**
   * Returns the width of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var drawWidth(get, never): Float;
  function get_drawWidth(): Float {
    if (this._camera) {
      return this.resolution.width / this._camera.zoom;
    }
    return this.resolution.width;
  }

  /**
   * Returns the width of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var width(get, never): Float;
  function get_width(): Float {
    if (this._camera) {
      return this.resolution.width / this._camera.zoom;
    }
    return this.resolution.width;
  }

  /**
   * Returns half the width of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var halfDrawWidth(get, never): Float;
  function get_halfDrawWidth(): Float {
    return this.drawWidth / 2;
  }

  /**
   * Returns the height of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var drawHeight(get, never): Float;
  function get_drawHeight(): Float {
    if (this._camera) {
      return this.resolution.height / this._camera.zoom;
    }
    return this.resolution.height;
  }

  public var height(get, never): Float;
  function get_height(): Float {
    if (this._camera) {
      return this.resolution.height / this._camera.zoom;
    }
    return this.resolution.height;
  }

  /**
   * Returns half the height of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var halfDrawHeight(get, never): Float;
  function get_halfDrawHeight(): Float {
    return this.drawHeight / 2;
  }

  /**
   * Returns screen center coordinates including zoom and device pixel ratio.
   */
  public var center(get, never): Vector;
  function get_center(): Vector {
    return vec(this.halfDrawWidth, this.halfDrawHeight);
  }

  /**
   * Returns the content area in screen space where it is safe to place content
   */
  public var contentArea(get, never): BoundingBox;
  function get_contentArea(): BoundingBox {
    return this._contentArea;
  }

  /**
   * Returns the unsafe area in screen space, this is the full screen and some space may not be onscreen.
   */
  public var unsafeArea(get, never): BoundingBox;
  function get_unsafeArea(): BoundingBox {
    return this._unsafeArea;
  }

  private var _contentArea: BoundingBox = new BoundingBox();
  private var _unsafeArea: BoundingBox = new BoundingBox();

  private function _computeFit() {
    document.body.style.margin = '0px';
    document.body.style.overflow = 'hidden';
    var aspect = this.aspectRatio;
    var adjustedWidth = 0;
    var adjustedHeight = 0;
    if (window.innerWidth / aspect < window.innerHeight) {
      adjustedWidth = window.innerWidth;
      adjustedHeight = window.innerWidth / aspect;
    } else {
      adjustedWidth = window.innerHeight * aspect;
      adjustedHeight = window.innerHeight;
    }

    this.viewport = {
      width: adjustedWidth,
      height: adjustedHeight
    };
    this._contentArea = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Zero);
    this._unsafeArea = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Zero);
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _computeFitScreenAndFill() {
    document.body.style.margin = '0px';
    document.body.style.overflow = 'hidden';
    var vw = window.innerWidth;
    var vh = window.innerHeight;
    this._computeFitAndFill(vw, vh);
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _computeFitContainerAndFill() {
    this.canvas.style.width = '100%';
    this.canvas.style.height = '100%';

    this._computeFitAndFill(this.canvas.offsetWidth, this.canvas.offsetHeight, {
      width: 100,
      widthUnit: 'percent',
      height: 100,
      heightUnit: 'percent'
    });
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _computeFitAndFill(vw: Int, vh: Int, ?viewport: ViewportDimension) {
    this.viewport = viewport ?? {
      width: vw,
      height: vh
    };
    // if the current screen aspectRatio is less than the original aspectRatio
    if (vw / vh <= this._contentResolution.width / this._contentResolution.height) {
      // compute new resolution to match the original aspect ratio
      this.resolution = {
        width: (vw * this._contentResolution.width) / vw,
        height: (((vw * this._contentResolution.width) / vw) * vh) / vw
      };
      var clip = (this.resolution.height - this._contentResolution.height) / 2;
      this._contentArea = new BoundingBox({
        top: clip,
        left: 0,
        right: this._contentResolution.width,
        bottom: this.resolution.height - clip
      });
      this._unsafeArea = new BoundingBox({
        top: -clip,
        left: 0,
        right: this._contentResolution.width,
        bottom: this.resolution.height + clip
      });
    } else {
      this.resolution = {
        width: (((vh * this._contentResolution.height) / vh) * vw) / vh,
        height: (vh * this._contentResolution.height) / vh
      };
      var clip = (this.resolution.width - this._contentResolution.width) / 2;
      this._contentArea = new BoundingBox({
        top: 0,
        left: clip,
        right: this.resolution.width - clip,
        bottom: this._contentResolution.height
      });
      this._unsafeArea = new BoundingBox({
        top: 0,
        left: -clip,
        right: this.resolution.width + clip,
        bottom: this._contentResolution.height
      });
    }
  }

  private function _computeFitScreenAndZoom() {
    document.body.style.margin = '0px';
    document.body.style.overflow = 'hidden';
    this.canvas.style.position = 'absolute';

    var vw = window.innerWidth;
    var vh = window.innerHeight;

    this._computeFitAndZoom(vw, vh);
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _computeFitContainerAndZoom() {
    this.canvas.style.width = '100%';
    this.canvas.style.height = '100%';
    this.canvas.style.position = 'relative';
    var parent = this.canvas.parentElement;
    parent.style.overflow = 'hidden';

    var vw = this.canvas.offsetWidth;
    var vh = this.canvas.offsetHeight;

    this._computeFitAndZoom(vw, vh);
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _computeFitAndZoom(vw: Int, vh: Int) {
    var aspect = this.aspectRatio;
    var adjustedWidth = 0;
    var adjustedHeight = 0;
    if (vw / aspect < vh) {
      adjustedWidth = vw;
      adjustedHeight = vw / aspect;
    } else {
      adjustedWidth = vh * aspect;
      adjustedHeight = vh;
    }

    var scaleX = vw / adjustedWidth;
    var scaleY = vh / adjustedHeight;

    var maxScaleFactor = Math.max(scaleX, scaleY);

    var zoomedWidth = adjustedWidth * maxScaleFactor;
    var zoomedHeight = adjustedHeight * maxScaleFactor;

    // Center zoomed dimension if bigger than the screen
    if (zoomedWidth > vw) {
      this.canvas.style.left = -(zoomedWidth - vw) / 2 + 'px';
    } else {
      this.canvas.style.left = '';
    }

    if (zoomedHeight > vh) {
      this.canvas.style.top = -(zoomedHeight - vh) / 2 + 'px';
    } else {
      this.canvas.style.top = '';
    }

    this.viewport = {
      width: zoomedWidth,
      height: zoomedHeight
    };

    var bounds = BoundingBox.fromDimension(this.viewport.width, this.viewport.height, Vector.Zero);
    // return safe area
    if (this.viewport.width > vw) {
      var clip = ((this.viewport.width - vw) / this.viewport.width) * this.resolution.width;
      bounds.top = 0;
      bounds.left = clip / 2;
      bounds.right = this.resolution.width - clip / 2;
      bounds.bottom = this.resolution.height;
    }

    if (this.viewport.height > vh) {
      var clip = ((this.viewport.height - vh) / this.viewport.height) * this.resolution.height;
      bounds.top = clip / 2;
      bounds.left = 0;
      bounds.bottom = this.resolution.height - clip / 2;
      bounds.right = this.resolution.width;
    }
    this._contentArea = bounds;
  }

  private function _computeFitContainer() {
    var aspect = this.aspectRatio;
    var adjustedWidth = 0;
    var adjustedHeight = 0;
    var widthUnit: ViewportUnit = 'pixel';
    var heightUnit: ViewportUnit = 'pixel';
    var parent = this.canvas.parentElement;
    if (parent.clientWidth / aspect < parent.clientHeight) {
      this.canvas.style.width = '100%';
      adjustedWidth = 100;
      widthUnit = 'percent';
      adjustedHeight = this.canvas.offsetWidth / aspect;
    } else {
      this.canvas.style.height = '100%';
      adjustedHeight = 100;
      heightUnit = 'percent';
      adjustedWidth = this.canvas.offsetHeight * aspect;
    }

    this.viewport = {
      width: adjustedWidth,
      widthUnit: widthUnit,
      height: adjustedHeight,
      heightUnit: heightUnit
    };
    this._contentArea = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Zero);
    this.events.emit('resize', {
      resolution: this.resolution,
      viewport: this.viewport
    });
  }

  private function _applyDisplayMode() {
    this._setResolutionAndViewportByDisplayMode(this.parent);

    // watch resizing
    if (Std.isTypeOf(this.parent, Window)) {
      this._browser.window.on('resize', this._resizeHandler);
    } else {
      this._resizeObserver = new ResizeObserver(() -> {
        this._resizeHandler();
      });
      this._resizeObserver.observe(this.parent);
    }
    this.parent.addEventListener('resize', this._resizeHandler);
  }

  /**
   * Sets the resolution and viewport based on the selected display mode.
   */
  private function _setResolutionAndViewportByDisplayMode(parent: HTMLElement) {
    if (this.displayMode == DisplayMode.FillContainer) {
      this.canvas.style.width = '100%';
      this.canvas.style.height = '100%';
      this.viewport = {
        width: 100,
        widthUnit: 'percent',
        height: 100,
        heightUnit: 'percent'
      };
      this.resolution = {
        width: this.canvas.offsetWidth,
        height: this.canvas.offsetHeight
      };
    }

    if (this.displayMode == DisplayMode.FillScreen) {
      document.body.style.margin = '0px';
      document.body.style.overflow = 'hidden';
      this.resolution = {
        width: parent.innerWidth,
        height: parent.innerHeight
      };

      this.viewport = this.resolution;
    }

    this._contentArea = BoundingBox.fromDimension(this.resolution.width, this.resolution.height, Vector.Zero);

    if (this.displayMode == DisplayMode.FitScreen) {
      this._computeFit();
    }

    if (this.displayMode == DisplayMode.FitContainer) {
      this._computeFitContainer();
    }

    if (this.displayMode == DisplayMode.FitScreenAndFill) {
      this._computeFitScreenAndFill();
    }

    if (this.displayMode == DisplayMode.FitContainerAndFill) {
      this._computeFitContainerAndFill();
    }

    if (this.displayMode == DisplayMode.FitScreenAndZoom) {
      this._computeFitScreenAndZoom();
    }

    if (this.displayMode == DisplayMode.FitContainerAndZoom) {
      this._computeFitContainerAndZoom();
    }
  }
}
