package nebula;

import nebula.Util.Object;
import nebula.Util.Future;
import nebula.EventEmitter;
import nebula.Input.PointerScope;
import nebula.Flags;
import nebula.Math.Vector;
import nebula.Screen;
import nebula.ScreenElement;
import nebula.Actor;
import nebula.Timer;
import nebula.TileMap;
import nebula.Director.DefaultLoader;
import nebula.Director.Loader;
import nebula.Util.Detector;
import nebula.Events;
import nebula.Util.Log;
import nebula.Color;
import nebula.Scene;
import nebula.EntityComponentSystem.Entity;
import nebula.Debug.DebugConfig;
import nebula.Util.Browser;
import nebula.Graphics;
import nebula.Util.Clock;
import nebula.Graphics.Filtering;
import nebula.Graphics.GraphicsDiagnostics;
import nebula.Input.InputMapper;
import nebula.Director.Director;
import nebula.Input.InputHost;
import nebula.Collision.PhysicsConfig;
import nebula.Util.Required;
import nebula.Context;
import nebula.GarbageCollector;
import nebula.Util.Util;
import nebula.Util.IFrame;

typedef TEngineEvents = DirectorEvents & {
  fallbackgraphicscontext: ExcaliburGraphicsContext2DCanvas,
  initialize: InitializeEvent<Engine>,
  visible: VisibleEvent,
  hidden: HiddenEvent,
  start: GameStartEvent,
  stop: GameStopEvent,
  preupdate: PreUpdateEvent<Engine>,
  postupdate: PostUpdateEvent<Engine>,
  preframe: PreFrameEvent,
  postframe: PostFrameEvent,
  predraw: PreDrawEvent,
  postdraw: PostDrawEvent
};

var EngineEvents = spreadWith(DirectorEvents, {
  FallbackGraphicsContext: 'fallbackgraphicscontext',
  Initialize: 'initialize',
  Visible: 'visible',
  Hidden: 'hidden',
  Start: 'start',
  Stop: 'stop',
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate',
  PreFrame: 'preframe',
  PostFrame: 'postframe',
  PreDraw: 'predraw',
  PostDraw: 'postdraw'
});

/**
 * Enum representing the different mousewheel event bubble prevention
 */
enum ScrollPreventionMode {
  /**
   * Do not prevent any page scrolling
   */
  None;
  /**
   * Prevent page scroll if mouse is over the game canvas
   */
  Canvas;
  /**
   * Prevent all page scrolling via mouse wheel
   */
  All;
}

enum CanvasRendering {
  Auto;
  Pixelated;
}

enum EitherOr3<A, B, C> {
  First(a: A);
  Second(b: B);
  Third(c: C);
}

enum EitherOr<A, B> {
  First(a: A);
  Second(b: B);
}

typedef TypeofScene = EitherOr3<Scene, SceneConstructor, SceneWithOptions>;

typedef RootOrLoader = EitherOr<WithRoot<TKnownScenes>, DefaultLoader>;

enum PowerPreferences {
  Default;
  HighPerformance;
  LowPower;
}

/**
 * Defines the available options to configure the Excalibur engine at constructor time.
 */
interface EngineOptions {
  /**
   * Optionally configure the width of the viewport in css pixels
   */
  public var width: Null<Int>;

  /**
   * Optionally configure the height of the viewport in css pixels
   */
  public var height: Null<Int>;

  /**
   * Optionally configure the width & height of the viewport in css pixels.
   * Use `viewport` instead of {@apilink EngineOptions.width} and {@apilink EngineOptions.height}, or vice versa.
   */
  public var viewport: Null<ViewportDimension>;

  /**
   * Optionally specify the size the logical pixel resolution, if not specified it will be width x height.
   * See {@apilink Resolution} for common presets.
   */
  public var resolution: Null<Resolution>;

  /**
   * Optionally specify antialiasing (smoothing), by default true (smooth pixels)
   *
   *  * `true` - useful for high resolution art work you would like smoothed, this also hints excalibur to load images
   * with default blending {@apilink ImageFiltering.Blended}
   *
   *  * `false` - useful for pixel art style art work you would like sharp, this also hints excalibur to load images
   * with default blending {@apilink ImageFiltering.Pixel}
   *
   * * {@apilink AntialiasOptions} Optionally deeply configure the different antialiasing settings, **WARNING** thar be dragons here.
   * It is recommended you stick to `true` or `false` unless you understand what you're doing and need to control rendering to
   * a high degree.
   */
  public var antialiasing: Null<Bool>;
  public var antialiasingOptions: Null<AntialiasOptions>;

  /**
   * Optionally specify excalibur garbage collection, by default true.
   *
   * * `true` - garbage collection defaults are enabled (default)
   *
   * * `false` - garbage collection is completely disabled (not recommended)
   *
   * * {@apilink GarbageCollectionOptions} Optionally deeply configure garbage collection settings, **WARNING** thar be dragons here.
   * It is recommended you stick to `true` or `false` unless you understand what you're doing, it is possible to get into a downward
   * spiral if collection timings are set too low where you are stuck in repeated collection.
   */
  public var garbageCollection: Null<Bool>;
  public var gcOptions: Null<GarbageCollectionOptions>;

  /**
   * Quick convenience property to configure Excalibur to use special settings for "pretty" anti-aliased pixel art
   *
   * 1. Turns on special shader condition to blend for pixel art and enables various antialiasing settings,
   *  notice blending is ON for this special mode.
   *
   * Equivalent to:
   * ```javascript
   * antialiasing: {
   *  pixelArtSampler: true,
   *  canvasImageRendering: 'auto',
   *  filtering: ImageFiltering.Blended,
   *  webglAntialiasing: true
   * }
   * ```
   */
  public var pixelArt: Null<Bool>;

  /**
   * Specify any UV padding you want use in pixels, this brings sampling into the texture if you're using
   * a sprite sheet in one image to prevent sampling bleed.
   *
   * Defaults:
   * * `antialiasing: false` or `filtering: ImageFiltering.Pixel` - 0.0;
   * * `pixelArt: true` - 0.25
   * * All else 0.01
   */
  public var uvPadding: Null<Float>;

  /**
   * Optionally hint the graphics context into a specific power profile
   *
   * Default "high-performance"
   */
  public var powerPreference: Null<PowerPreferences>;

  /**
   * Optionally upscale the number of pixels in the canvas. Normally only useful if you need a smoother look to your assets, especially
   * {@apilink Text} or Pixel Art assets.
   *
   * **WARNING** It is recommended you try using `antialiasing: true` before adjusting pixel ratio. Pixel ratio will consume more memory
   * and on mobile may break if the internal size of the canvas exceeds 4k pixels in width or height.
   *
   * Default is based the display's pixel ratio, for example a HiDPI screen might have the value 2;
   */
  public var pixelRatio: Null<Float>;

  /**
   * Optionally configure the native canvas transparent backdrop
   */
  public var enableCanvasTransparency: Null<Bool>;

  /**
   * Optionally snap graphics to nearest pixel, default is false
   */
  public var snapToPixel: Null<Bool>;

  /**
   * The {@apilink DisplayMode} of the game, by default {@apilink DisplayMode.FitScreen} with aspect ratio 4:3 (800x600).
   * Depending on this value, {@apilink width} and {@apilink height} may be ignored.
   */
  public var displayMode: Null<DisplayMode>;

  /**
   * Optionally configure the global, or a factory to produce it to listen to for browser events for Excalibur to listen to
   */
  public var global: Null<GlobalEventHandlers>;

  /**
   * Configures the pointer scope. Pointers scoped to the 'Canvas' can only fire events within the canvas viewport; whereas, 'Document'
   * (default) scoped will fire anywhere on the page.
   */
  public var pointerScope: Null<PointerScope>;

  /**
   * Suppress boot up console message, which contains the "powered by Excalibur message"
   */
  public var suppressConsoleBootMessage: Null<Bool>;

  /**
   * Suppress minimum browser feature detection, it is not recommended users of excalibur switch this off. This feature ensures that
   * the currently running browser meets the minimum requirements for running excalibur. This can be useful if running on non-standard
   * browsers or if there is a bug in excalibur preventing execution.
   */
  public var suppressMinimumBrowserFeatureDetection: Null<Bool>;

  /**
   * Suppress HiDPI auto detection and scaling, it is not recommended users of excalibur switch off this feature. This feature detects
   * and scales the drawing canvas appropriately to accommodate HiDPI screens.
   */
  public var suppressHiDPIScaling: Null<Bool>;

  /**
   * Suppress play button, it is not recommended users of excalibur switch this feature. Some browsers require a user gesture (like a click)
   * for certain browser features to work like web audio.
   */
  public var suppressPlayButton: Null<Bool>;

  /**
   * Sets the focus of the window, this is needed when hosting excalibur in a cross-origin/same-origin iframe in order for certain events
   * (like keyboard) to work. You can use
   * For example: itch.io or codesandbox.io
   *
   * By default set to true,
   */
  public var grabWindowFocus: Null<Bool>;

  /**
   * Scroll prevention method.
   */
  public var scrollPreventionMode: Null<ScrollPreventionMode>;

  /**
   * Optionally set the background color
   */
  public var backgroundColor: Null<Color>;

  /**
   * Optionally set the maximum fps if not set Excalibur will go as fast as the device allows.
   *
   * You may want to constrain max fps if your game cannot maintain fps consistently, it can look and feel better to have a 30fps game than
   * one that bounces between 30fps and 60fps
   */
  public var maxFps: Null<Int>;

  /**
   * Optionally configure a fixed update timestep in milliseconds, this can be desirable if you need the physics simulation to be very stable. When
   * set the update step and physics will use the same elapsed time for each tick even if the graphical framerate drops. In order for the
   * simulation to be correct, excalibur will run multiple updates in a row (at the configured update elapsed) to catch up, for example
   * there could be X updates and 1 draw each clock step.
   *
   * **NOTE:** This does come at a potential perf cost because each catch-up update will need to be run if the fixed rate is greater than
   * the current instantaneous framerate, or perf gain if the fixed rate is less than the current framerate.
   *
   * By default is unset and updates will use the current instantaneous framerate with 1 update and 1 draw each clock step.
   *
   * **WARN:** `fixedUpdateTimestep` takes precedence over `fixedUpdateFps` use whichever is most convenient.
   */
  public var fixedUpdateTimestep: Null<Int>;

  /**
   * Optionally configure a fixed update fps, this can be desirable if you need the physics simulation to be very stable. When set
   * the update step and physics will use the same elapsed time for each tick even if the graphical framerate drops. In order for the
   * simulation to be correct, excalibur will run multiple updates in a row (at the configured update elapsed) to catch up, for example
   * there could be X updates and 1 draw each clock step.
   *
   * **NOTE:** This does come at a potential perf cost because each catch-up update will need to be run if the fixed rate is greater than
   * the current instantaneous framerate, or perf gain if the fixed rate is less than the current framerate.
   *
   * By default is unset and updates will use the current instantaneous framerate with 1 update and 1 draw each clock step.
   *
   * **WARN:** `fixedUpdateTimestep` takes precedence over `fixedUpdateFps` use whichever is most convenient.
   */
  public var fixedUpdateFps: Null<Int>;

  /**
   * Default `true`, optionally configure excalibur to use optimal draw call sorting, to opt out set this to `false`.
   *
   * Excalibur will automatically sort draw calls by z and priority into renderer batches for maximal draw performance,
   * this can disrupt a specific desired painter order.
   *
   */
  public var useDrawSorting: Null<Bool>;

  /**
   * Optionally provide a custom handler for the webgl context lost event
   */
  public var handleContextLost: Null<(e: Event) -> Void>;

  /**
   * Optionally provide a custom handler for the webgl context restored event
   */
  public var handleContextRestored: Null<(e: Event) -> Void>;

  /**
   * Optionally configure how excalibur handles poor performance on a player's browser
   */
  public var configurePerformanceCanvas2DFallback: Null<{
    /**
     * By default `false`, this will switch the internal graphics context to Canvas2D which can improve performance on non hardware
     * accelerated browsers.
     */
    allow: Bool,
    /**
     * By default `false`, if set to `true` a dialogue will be presented to the player about their browser and how to potentially
     * address any issues.
     */
    ?showPlayerMessage: Bool,
    /**
     * Default `{ numberOfFrames: 100, fps: 20 }`, optionally configure excalibur to fallback to the 2D Canvas renderer
     * if bad performance is detected.
     *
     * In this example of the default if excalibur is running at 20fps or less for 100 frames it will trigger the fallback to the 2D
     * Canvas renderer.
     */
    ?threshold: { numberOfFrames: Int, fps: Int }
  }>;

  /**
   * Optionally configure the physics simulation in excalibur
   *
   * If false, Excalibur will not produce a physics simulation.
   *
   * Default is configured to use {@apilink SolverStrategy.Arcade} physics simulation
   */
  public var physics: Null<PhysicsConfig>;

  /**
   * Optionally specify scenes with their transitions and loaders to excalibur's scene {@apilink Director}
   *
   * Scene transitions can can overridden dynamically by the `Scene` or by the call to `.goToScene`
   */
  public var scenes: Null<SceneMap<TKnownScenes>>;
}

/**
 * The Excalibur Engine
 *
 * The {@apilink Engine} is the main driver for a game. It is responsible for
 * starting/stopping the game, maintaining state, transmitting events,
 * loading resources, and managing the scene.
 */
class Engine {
  static public var Context: IContext<Null<Engine>> = Context.createContext();
  static function useEngine(): Engine {
    var value = useContext(Engine.Context);

    if (!value) {
      throw new Error('Cannot inject engine with `useEngine()`, `useEngine()` was called outside of Engine lifecycle scope.');
    }

    return value;
  }
  static var InstanceCount = 0;

  /**
   * Anything run under scope can use `useEngine()` to inject the current engine
   * @param cb
   */
  public var scope = (cb: () -> TReturn) -> Engine.Context.scope(this, cb);

  public var global: GlobalEventHandlers;

  private var _garbageCollector: GarbageCollector;

  public var garbageCollectorConfig: Null<GarbageCollectionOptions>;

  /**
   * Current Excalibur version string
   *
   * Useful for plugins or other tools that need to know what features are available
   */
  public var version = EX_VERSION;

  /**
   * Listen to and emit events on the Engine
   */
  public var events = new EventEmitter<EngineEvents>();

  /**
   * Excalibur browser events abstraction used for wiring to native browser events safely
   */
  public var browser: BrowserEvents;

  /**
   * Screen abstraction
   */
  public var screen: Screen;

  /**
   * Scene director, manages all scenes, scene transitions, and loaders in excalibur
   */
  public var director: Director<TKnownScenes>;

  /**
   * Direct access to the engine's canvas element
   */
  public var canvas: HTMLCanvasElement;

  /**
   * Direct access to the ExcaliburGraphicsContext used for drawing things to the screen
   */
  public var graphicsContext: ExcaliburGraphicsContext;


  /**
   * Direct access to the physics configuration for excalibur
   */
  public var physics: DeepRequired<PhysicsConfig>;

  /**
   * Optionally set the maximum fps if not set Excalibur will go as fast as the device allows.
   *
   * You may want to constrain max fps if your game cannot maintain fps consistently, it can look and feel better to have a 30fps game than
   * one that bounces between 30fps and 60fps
   */
  public var maxFps: Int = Number.POSITIVE_INFINITY;

  /**
   * Optionally configure a fixed update fps, this can be desirable if you need the physics simulation to be very stable. When set
   * the update step and physics will use the same elapsed time for each tick even if the graphical framerate drops. In order for the
   * simulation to be correct, excalibur will run multiple updates in a row (at the configured update elapsed) to catch up, for example
   * there could be X updates and 1 draw each clock step.
   *
   * **NOTE:** This does come at a potential perf cost because each catch-up update will need to be run if the fixed rate is greater than
   * the current instantaneous framerate, or perf gain if the fixed rate is less than the current framerate.
   *
   * By default is unset and updates will use the current instantaneous framerate with 1 update and 1 draw each clock step.
   *
   * **WARN:** `fixedUpdateTimestep` takes precedence over `fixedUpdateFps` use whichever is most convenient.
   */
  public var fixedUpdateFps: Null<Int>;

  /**
   * Optionally configure a fixed update timestep in milliseconds, this can be desirable if you need the physics simulation to be very stable. When
   * set the update step and physics will use the same elapsed time for each tick even if the graphical framerate drops. In order for the
   * simulation to be correct, excalibur will run multiple updates in a row (at the configured update elapsed) to catch up, for example
   * there could be X updates and 1 draw each clock step.
   *
   * **NOTE:** This does come at a potential perf cost because each catch-up update will need to be run if the fixed rate is greater than
   * the current instantaneous framerate, or perf gain if the fixed rate is less than the current framerate.
   *
   * By default is unset and updates will use the current instantaneous framerate with 1 update and 1 draw each clock step.
   *
   * **WARN:** `fixedUpdateTimestep` takes precedence over `fixedUpdateFps` use whichever is most convenient.
   */
  public var fixedUpdateTimestep: Null<Int>;

  /**
   * Direct access to the excalibur clock
   */
  public var clock: Clock;

  public var pointerScope: PointerScope;
  public var grabWindowFocus: Bool;

  /**
   * The width of the game canvas in pixels (physical width component of the
   * resolution of the canvas element)
   */
  public var canvasWidth(get, never): Int;
  function get_canvasWidth(): Int {
    return this.screen.canvasWidth;
  }

  /**
   * Returns half width of the game canvas in pixels (half physical width component)
   */
  public var halfCanvasWidth(get, never): Float;
  function get_halfCanvasWidth(): Float {
    return this.screen.halfCanvasWidth;
  }

  /**
   * The height of the game canvas in pixels, (physical height component of
   * the resolution of the canvas element)
   */
  public var canvasHeight(get, never): Int;
  function get_canvasHeight(): Int {
    return this.screen.canvasHeight;
  }

  /**
   * Returns half height of the game canvas in pixels (half physical height component)
   */
  public var halfCanvasHeight(get, never): Float;
  function get_halfCanvasHeight(): Float {
    return this.screen.halfCanvasHeight;
  }

  /**
   * Returns the width of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var drawWidth(get, never): Int;
  function get_drawWidth(): Int {
    return this.screen.drawWidth;
  }

  /**
   * Returns half the width of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var halfDrawWidth(get, never): Float;
  function get_halfDrawWidth(): Float {
    return this.screen.halfDrawWidth;
  }

  /**
   * Returns the height of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var drawHeight(get, never): Int;
  function get_drawHeight(): Int {
    return this.screen.drawHeight;
  }

  /**
   * Returns half the height of the engine's visible drawing surface in pixels including zoom and device pixel ratio.
   */
  public var halfDrawHeight(get, never): Float;
  function get_halfDrawHeight(): Float {
    return this.screen.halfDrawHeight;
  }

  /**
   * Returns whether excalibur detects the current screen to be HiDPI
   */
  public var isHiDpi(get, never): Bool;
  function get_isHiDpi(): Bool {
    return this.screen.isHiDpi;
  }

  /**
   * Access engine input like pointer, keyboard, or gamepad
   */
  public var input: InputHost;

  /**
   * Map multiple input sources to specific game actions actions
   */
  public var inputMapper: InputMapper;

  private var _inputEnabled: Bool = true;

  /**
   * Access Excalibur debugging functionality.
   *
   * Useful when you want to debug different aspects of built in engine features like
   *   * Transform
   *   * Graphics
   *   * Colliders
   */
  public var debug: DebugConfig;

  /**
   * Access {@apilink stats} that holds frame statistics.
   */
  public var stats(get, never): DebugStats;
  function get_stats(): DebugStats {
    return this.debug.stats;
  }

  /**
   * The current {@apilink Scene} being drawn and updated on screen
   */
  public var currentScene(get, never): Scene;
  function get_currentScene(): Scene {
    return this.director.currentScene;
  }

  /**
   * The current {@apilink Scene} being drawn and updated on screen
   */
  public var currentSceneName(get, never): String;
  function get_currentSceneName(): String {
    return this.director.currentSceneName;
  }

  /**
   * The default {@apilink Scene} of the game, use {@apilink Engine.goToScene} to transition to different scenes.
   */
  public var rootScene(get, never): Scene;
  function get_rootScene(): Scene {
    return this.director.rootScene;
  }

  /**
   * Contains all the scenes currently registered with Excalibur
   */
  public var scenes(get, never): Bool;
  function get_scenes(): Map<String, TypeofScene> {
    return this.director.scenes;
  }

  /**
   * Indicates whether the engine is set to fullscreen or not
   */
  public var isFullScreen(get, never): Bool;
  function get_isFullscreen(): Bool {
    return this.screen.isFullScreen;
  }

  /**
   * Indicates the current {@apilink DisplayMode} of the engine.
   */
  public var displayMode(get, never): DisplayMode;
  function get_displayMode(): DisplayMode {
    return this.screen.displayMode;
  }

  private var _suppressPlayButton: Bool = false;
  /**
   * Returns the calculated pixel ration for use in rendering
   */
  public var pixelRatio(get, never): Float;
  function get_pixelRatio(): Float {
    return this.screen.pixelRatio;
  }

  /**
   * Indicates whether audio should be paused when the game is no longer visible.
   */
  public var pauseAudioWhenHidden: Bool = true;

  /**
   * Indicates whether the engine should draw with debug information
   */
  private var _isDebug: Bool = false;
  public var isDebug(get, never): Bool;
  function get_isDebug(): Bool {
    return this._isDebug;
  }

  /**
   * Sets the background color for the engine.
   */
  public var backgroundColor: Color;

  /**
   * Sets the Transparency for the engine.
   */
  public var enableCanvasTransparency: Bool = true;

  /**
   * Hints the graphics context to truncate fractional world space coordinates
   */
  public var snapToPixel(get, set): Bool;
  function get_snapToPixel(): Bool {
    return this.graphicsContext.snapToPixel;
  }

  function set_snapToPixel(shouldSnapToPixel: Bool) {
    this.graphicsContext.snapToPixel = shouldSnapToPixel;
  }

  /**
   * The action to take when a fatal exception is thrown
   */
  public function onFatalException(e: Any) {
    Logger.getInstance().fatal(e, e.stack);
  };

  /**
   * The mouse wheel scroll prevention mode
   */
  public var pageScrollPreventionMode: ScrollPreventionMode;

  private var _logger: Logger;

  private var _toaster: Toaster = new Toaster();

  // this determines whether excalibur is compatible with your browser
  private var _compatible: Bool;

  private var _timescale: Float = 1.0;

  // loading
  private var _loader: DefaultLoader;

  private var _isInitialized: Bool = false;

  public function emit(eventName: String, event: Null<Any>): Void {
    this.events.emit(eventName, event);
  }

  public function on<String>(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once<String>(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off<String>(eventName: String, handler: Null<Handler<Any>>): Void {
    this.events.off(eventName, handler);
  }

  /**
   * Default {@apilink EngineOptions}
   */
  private static var _DEFAULT_ENGINE_OPTIONS: EngineOptions = {
    width: 0,
    height: 0,
    enableCanvasTransparency: true,
    useDrawSorting: true,
    configurePerformanceCanvas2DFallback: {
      allow: false,
      showPlayerMessage: false,
      threshold: { fps: 20, numberOfFrames: 100 }
    },
    canvasElementId: '',
    canvasElement: undefined,
    enableCanvasContextMenu: false,
    snapToPixel: false,
    antialiasing: true,
    pixelArt: false,
    garbageCollection: true,
    powerPreference: 'high-performance',
    pointerScope: PointerScope.Canvas,
    suppressConsoleBootMessage: null,
    suppressMinimumBrowserFeatureDetection: null,
    suppressHiDPIScaling: null,
    suppressPlayButton: null,
    grabWindowFocus: true,
    scrollPreventionMode: ScrollPreventionMode.Canvas,
    backgroundColor: Color.fromHex('#2185d0') // Excalibur blue
  };

  private var _originalOptions: EngineOptions = {};
  public var _originalDisplayMode: DisplayMode;

  /**
   * Creates a new game using the given {@apilink EngineOptions}. By default, if no options are provided,
   * the game will be rendered full screen (taking up all available browser window space).
   * You can customize the game rendering through {@apilink EngineOptions}.
   *
   * Example:
   *
   * ```js
   * var game = new ex.Engine({
   *   width: 0, // the width of the canvas
   *   height: 0, // the height of the canvas
   *   enableCanvasTransparency: true, // the transparencySection of the canvas
   *   canvasElementId: '', // the DOM canvas element ID, if you are providing your own
   *   displayMode: ex.DisplayMode.FullScreen, // the display mode
   *   pointerScope: ex.PointerScope.Document, // the scope of capturing pointer (mouse/touch) events
   *   backgroundColor: ex.Color.fromHex('#2185d0') // background color of the engine
   * });
   *
   * // call game.start, which is a Promise
   * game.start().then(function () {
   *   // ready, set, go!
   * });
   * ```
   */
  public function new(options: Null<EngineOptions>) {
    options = Object.spreadWith(Engine._DEFAULT_ENGINE_OPTIONS, options);
    this._originalOptions = options;

    Flags.freeze();

    // Initialize browser events facade
    this.browser = new BrowserEvents(window, document);

    // Check compatibility
    final detector = new Detector();
    if (!options.suppressMinimumBrowserFeatureDetection && !(this._compatible = detector.test())) {
      final message = document.createElement('div');
      message.innerText = 'Sorry, your browser does not support all the features needed for Excalibur';
      document.body.appendChild(message);

      detector.failedTests.forEach(function (test) {
        final testMessage = document.createElement('div');
        testMessage.innerText = 'Browser feature missing ' + test;
        document.body.appendChild(testMessage);
      });

      if (options.canvasElementId) {
        final canvas = document.getElementById(options.canvasElementId);
        if (canvas) {
          canvas.parentElement.removeChild(canvas);
        }
      }

      return;
    } else {
      this._compatible = true;
    }

    // Use native console API for color fun
    // eslint-disable-next-line no-console
    if (console.log && !options.suppressConsoleBootMessage) {
      // eslint-disable-next-line no-console
      console.log(
        '%cPowered by Excalibur.js (v${EX_VERSION})',
        'background: #176BAA; color: white; border-radius: 5px; padding: 15px; font-size: 1.5em; line-height: 80px;'
      );
      // eslint-disable-next-line no-console
      console.log('Visit', 'http://excaliburjs.com', 'for more information');
    }

    // Suppress play button
    if (options.suppressPlayButton) {
      this._suppressPlayButton = true;
    }

    this._logger = Logger.getInstance();

    // If debug is enabled, let's log browser features to the console.
    if (this._logger.defaultLevel == LogLevel.Debug) {
      detector.logBrowserFeatures();
    }

    this._logger.debug('Building engine...');
    if (options.garbageCollection == true) {
      this.garbageCollectorConfig = Object.spreadWith(DefaultGarbageCollectionOptions, {});
    } else if (options.garbageCollection == false) {
      this._logger.warn(
        'WebGL Garbage Collection Disabled!!! If you leak any images over time your game will crash when GPU memory is exhausted'
      );
      this.garbageCollectorConfig = null;
    } else {
      this.garbageCollectorConfig = Object.spreadWith(DefaultGarbageCollectionOptions, options.garbageCollection);
    }
    this._garbageCollector = new GarbageCollector({ getTimestamp: Date.now });

    this.canvasElementId = options.canvasElementId;

    if (options.canvasElementId) {
      this._logger.debug('Using Canvas element specified: ' + options.canvasElementId);

      //test for existence of element
      if (document.getElementById(options.canvasElementId) == null) {
        throw new Error('Cannot find existing element in the DOM, please ensure element is created prior to engine creation.');
      }

      this.canvas = document.getElementById(options.canvasElementId);
    } else if (options.canvasElement) {
      this._logger.debug('Using Canvas element specified:', options.canvasElement);
      this.canvas = options.canvasElement;
    } else {
      this._logger.debug('Using generated canvas element');
      this.canvas = document.createElement('canvas');
    }

    if (this.canvas && !options.enableCanvasContextMenu) {
      this.canvas.addEventListener('contextmenu', (evt) => {
        evt.preventDefault();
      });
    }

    var displayMode = options.displayMode ?? DisplayMode.Fixed;
    if ((options.width && options.height) || options.viewport) {
      if (options.displayMode == undefined) {
        displayMode = DisplayMode.Fixed;
      }
      this._logger.debug('Engine viewport is size ' + options.width + ' x ' + options.height);
    } else if (!options.displayMode) {
      this._logger.debug('Engine viewport is fit');
      displayMode = DisplayMode.FitScreen;
    }

    var global = options.global;

    this.global = global ?? getDefaultGlobal();
    this.grabWindowFocus = options.grabWindowFocus;
    this.pointerScope = options.pointerScope;

    this._originalDisplayMode = displayMode;

    var pixelArtSampler: Bool;
    var uvPadding: Float;
    var nativeContextAntialiasing: Bool;

    var canvasImageRendering: CanvasRendering;
    var filtering: ImageFiltering;
    var multiSampleAntialiasing: { samples: Int };
    if (options.antialiasingOptions) {
      final aaOptions = Object.spreadWith(
        options.pixelArt ? DefaultPixelArtOptions : DefaultAntialiasOptions,
        options.antialiasingOptions
      );

      pixelArtSampler = aaOptions.pixelArtSampler;
      nativeContextAntialiasing = aaOptions.nativeContextAntialiasing;
      multiSampleAntialiasing = aaOptions.multiSampleAntialiasing;
      filtering = aaOptions.filtering;
      canvasImageRendering = aaOptions.canvasImageRendering;
    } else {
      pixelArtSampler = !!options.pixelArt;
      nativeContextAntialiasing = false;
      multiSampleAntialiasing = options.antialiasing;
      canvasImageRendering = options.antialiasing ? 'auto' : 'pixelated';
      filtering = options.antialiasing ? ImageFiltering.Blended : ImageFiltering.Pixel;
    }

    if (nativeContextAntialiasing && multiSampleAntialiasing) {
      this._logger.warnOnce(
        "Cannot use antialias setting nativeContextAntialiasing and multiSampleAntialiasing" +
          " at the same time, they are incompatible settings. If you aren't sure use multiSampleAntialiasing"
      );
    }

    if (options.pixelArt) {
      uvPadding = 0.25;
    }

    if (!options.antialiasing || filtering == ImageFiltering.Pixel) {
      uvPadding = 0;
    }

    // Override with any user option, if non default to .25 for pixel art, 0.01 for everything else
    uvPadding = options.uvPadding ?? uvPadding ?? 0.01;

    // Canvas 2D fallback can be flagged on
    var useCanvasGraphicsContext = Flags.isEnabled('use-canvas-context');
    if (!useCanvasGraphicsContext) {
      // Attempt webgl first
      try {
        this.graphicsContext = new ExcaliburGraphicsContextWebGL({
          canvasElement: this.canvas,
          enableTransparency: this.enableCanvasTransparency,
          pixelArtSampler: pixelArtSampler,
          antialiasing: nativeContextAntialiasing,
          multiSampleAntialiasing: multiSampleAntialiasing,
          uvPadding: uvPadding,
          powerPreference: options.powerPreference,
          backgroundColor: options.backgroundColor,
          snapToPixel: options.snapToPixel,
          useDrawSorting: options.useDrawSorting,
          garbageCollector: this.garbageCollectorConfig
            ? {
                garbageCollector: this._garbageCollector,
                collectionInterval: this.garbageCollectorConfig.textureCollectInterval
              }
            : null,
          handleContextLost: options.handleContextLost ?? this._handleWebGLContextLost,
          handleContextRestored: options.handleContextRestored
        });
      } catch (e) {
        this._logger.warn(
          'Excalibur could not load webgl for some reason (${(e as Error).message}) and loaded a Canvas 2D fallback. ' +
            'Some features of Excalibur will not work in this mode. \n\n' +
            'Read more about this issue at https://excaliburjs.com/docs/performance'
        );
        // fallback to canvas in case of failure
        useCanvasGraphicsContext = true;
      }
    }

    if (useCanvasGraphicsContext) {
      this.graphicsContext = new ExcaliburGraphicsContext2DCanvas({
        canvasElement: this.canvas,
        enableTransparency: this.enableCanvasTransparency,
        antialiasing: nativeContextAntialiasing,
        backgroundColor: options.backgroundColor,
        snapToPixel: options.snapToPixel,
        useDrawSorting: options.useDrawSorting
      });
    }

    this.screen = new Screen({
      canvas: this.canvas,
      context: this.graphicsContext,
      antialiasing: nativeContextAntialiasing,
      canvasImageRendering: canvasImageRendering,
      browser: this.browser,
      viewport: options.viewport ?? (options.width && options.height ? { width: options.width, height: options.height } : Resolution.SVGA),
      resolution: options.resolution,
      displayMode: displayMode,
      pixelRatio: options.suppressHiDPIScaling ? 1 : (options.pixelRatio ?? null)
    });

    // TODO REMOVE STATIC!!!
    // Set default filtering based on antialiasing
    TextureLoader.filtering = filtering;

    if (options.backgroundColor) {
      this.backgroundColor = options.backgroundColor.clone();
    }

    this.maxFps = options.maxFps ?? this.maxFps;

    this.fixedUpdateTimestep = options.fixedUpdateTimestep ?? this.fixedUpdateTimestep;
    this.fixedUpdateFps = options.fixedUpdateFps ?? this.fixedUpdateFps;
    this.fixedUpdateTimestep = this.fixedUpdateTimestep || 1000 / this.fixedUpdateFps;

    this.clock = new StandardClock({
      maxFps: this.maxFps,
      tick: this._mainloop.bind(this),
      onFatalException: (e) => this.onFatalException(e)
    });

    this.enableCanvasTransparency = options.enableCanvasTransparency;

    if (options.physicsOptions) {
      this.physics = Object.spreadWith(
        getDefaultPhysicsConfig(),
        { enabled: options.physics }
      );
    } else {
      this.physics = Object.spreadWith(
        getDefaultPhysicsConfig(),
        {}
      );
      mergeDeep(this.physics, options.physicsOptions);
    }

    this.debug = new DebugConfig(this);

    this.director = new Director(this, options.scenes);
    this.director.events.pipe(this.events);

    this._initialize(options);

    Engine.InstanceCount++;
  }

  private function _handleWebGLContextLost(e: Event) {
    e.preventDefault();
    this.clock.stop();
    this._logger.fatalOnce('WebGL Graphics Lost', e);
    final container = document.createElement('div');
    container.id = 'ex-webgl-graphics-context-lost';
    container.style.position = 'absolute';
    container.style.zIndex = '99';
    container.style.left = '50%';
    container.style.top = '50%';
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.transform = 'translate(-50%, -50%)';
    container.style.backgroundColor = 'white';
    container.style.padding = '10px';
    container.style.borderStyle = 'solid 1px';

    final div = document.createElement('div');
    div.innerHTML = '
      <h1>There was an issue rendering, please refresh the page.</h1>
      <div>
        <p>WebGL Graphics Context Lost</p>

        <button id="ex-webgl-graphics-reload">Refresh Page</button>

        <p>There are a few reasons this might happen:</p>
        <ul>
          <li>Two or more pages are placing a high demand on the GPU</li>
          <li>Another page or operation has stalled the GPU and the browser has decided to reset the GPU</li>
          <li>The computer has multiple GPUs and the user has switched between them</li>
          <li>Graphics driver has crashed or restarted</li>
          <li>Graphics driver was updated</li>
        </ul>
      </div>
    ';
    container.appendChild(div);
    if (this.canvas?.parentElement) {
      this.canvas.parentElement.appendChild(container);
      final button = div.querySelector('#ex-webgl-graphics-reload');
      button?.addEventListener('click', () -> location.reload());
    }
  };

  private var _performanceThresholdTriggered = false;
  private var _fpsSamples: Array<Int> = [];
  private function _monitorPerformanceThresholdAndTriggerFallback() {
    final allow = this._originalOptions.configurePerformanceCanvas2DFallback.allow;
    var threshold = this._originalOptions.configurePerformanceCanvas2DFallback.threshold;
    var threshold = this._originalOptions.configurePerformanceCanvas2DFallback.showPlayerMessage;
    if (threshold == null) {
      threshold = Engine._DEFAULT_ENGINE_OPTIONS.configurePerformanceCanvas2DFallback.threshold;
    }
    if (showPlayerMessage == null) {
      showPlayerMessage = Engine._DEFAULT_ENGINE_OPTIONS.configurePerformanceCanvas2DFallback.showPlayerMessage;
    }
    if (!Flags.isEnabled('use-canvas-context') && allow && this.ready && !this._performanceThresholdTriggered) {
      // Calculate Average fps for last X number of frames after start
      if (this._fpsSamples.length == threshold.numberOfFrames) {
        this._fpsSamples.splice(0, 1);
      }
      this._fpsSamples.push(this.clock.fpsSampler.fps);
      var total = 0;
      for (sample in samples) {
        total += sample;
      }
      var average = total / this._fpsSamples.length;

      if (this._fpsSamples.length == threshold.numberOfFrames) {
        if (average <= threshold.fps) {
          this._performanceThresholdTriggered = true;
          this._logger.warn(
            'Switching to browser 2D Canvas fallback due to performance. Some features of Excalibur will not work in this mode.\n' +
              "this might mean your browser doesn't have webgl enabled or hardware acceleration is unavailable.\n\n" +
              'If in Chrome:\n' +
              '  * Visit Settings > Advanced > System, and ensure "Use Hardware Acceleration" is checked.\n' +
              '  * Visit chrome://flags/#ignore-gpu-blocklist and ensure "Override software rendering list" is "enabled"\n' +
              'If in Firefox, visit about:config\n' +
              '  * Ensure webgl.disabled = false\n' +
              '  * Ensure webgl.force-enabled = true\n' +
              '  * Ensure layers.acceleration.force-enabled = true\n\n' +
              'Read more about this issue at https://excaliburjs.com/docs/performance'
          );

          if (showPlayerMessage) {
            this._toaster.toast(
              'Excalibur is encountering performance issues. ' +
                "It's possible that your browser doesn't have hardware acceleration enabled. " +
                'Visit [LINK] for more information and potential solutions.',
              'https://excaliburjs.com/docs/performance'
            );
          }
          this.useCanvas2DFallback();
          this.emit('fallbackgraphicscontext', this.graphicsContext);
        }
      }
    }
  }

  /**
   * Switches the engine's graphics context to the 2D Canvas.
   * @warning Some features of Excalibur will not work in this mode.
   */
  public function useCanvas2DFallback() {
    // Swap out the canvas
    var newCanvas = this.canvas.cloneNode(false);
    this.canvas.parentNode.replaceChild(newCanvas, this.canvas);
    this.canvas = newCanvas;

    var options = Object.spreadWith(
      this._originalOptions,
      { antialiasing: this.screen.antialiasing }
    );

    var displayMode = this._originalDisplayMode;

    // New graphics context
    this.graphicsContext = new ExcaliburGraphicsContext2DCanvas({
      canvasElement: this.canvas,
      enableTransparency: this.enableCanvasTransparency,
      antialiasing: options.antialiasing,
      backgroundColor: options.backgroundColor,
      snapToPixel: options.snapToPixel,
      useDrawSorting: options.useDrawSorting
    });

    // Reset screen
    if (this.screen) {
      this.screen.dispose();
    }

    this.screen = new Screen({
      canvas: this.canvas,
      context: this.graphicsContext,
      antialiasing: options.antialiasing ?? true,
      browser: this.browser,
      viewport: options.viewport ?? (options.width && options.height ? { width: options.width, height: options.height } : Resolution.SVGA),
      resolution: options.resolution,
      displayMode: displayMode,
      pixelRatio: options.suppressHiDPIScaling ? 1 : (options.pixelRatio ?? null)
    });
    this.screen.setCurrentCamera(this.currentScene.camera);

    // Reset pointers
    this.input.pointers.detach();
    final pointerTarget = options && options.pointerScope == PointerScope.Document ? document : this.canvas;
    this.input.pointers = this.input.pointers.recreate(pointerTarget, this);
    this.input.pointers.init();
  }

  private var _disposed = false;
  /**
   * Attempts to completely clean up excalibur resources, including removing the canvas from the dom.
   *
   * To start again you will need to new up an Engine.
   */
  public function dispose() {
    if (!this._disposed) {
      this._disposed = true;
      this.stop();
      this._garbageCollector.forceCollectAll();
      this.input.toggleEnabled(false);
      this.canvas.parentNode.removeChild(this.canvas);
      this.canvas = null;
      this.screen.dispose();
      this.graphicsContext.dispose();
      this.graphicsContext = null;
      Engine.InstanceCount--;
    }
  }

  public function isDisposed() {
    return this._disposed;
  }

  /**
   * Returns a BoundingBox of the top left corner of the screen
   * and the bottom right corner of the screen.
   */
  public function getWorldBounds() {
    return this.screen.getWorldBounds();
  }

  /**
   * Gets the current engine timescale factor (default is 1.0 which is 1:1 time)
   */
  public var timescale(get, set): Float;
  function get_timescale(): Float {
    return this._timescale;
  }

  /**
   * Sets the current engine timescale factor. Useful for creating slow-motion effects or fast-forward effects
   * when using time-based movement.
   */
  function set_timescale(value: Float): Void {
    if (value < 0) {
      Logger.getInstance().warnOnce('engine.timescale to a value less than 0 are ignored');
      return;
    }

    this._timescale = value;
  }

  /**
   * Adds a {@apilink Timer} to the {@apilink currentScene}.
   * @param timer  The timer to add to the {@apilink currentScene}.
   */
  public function addTimer(timer: Timer): Timer {
    return this.currentScene.addTimer(timer);
  }

  /**
   * Removes a {@apilink Timer} from the {@apilink currentScene}.
   * @param timer  The timer to remove to the {@apilink currentScene}.
   */
  public function removeTimer(timer: Timer): Timer {
    return this.currentScene.removeTimer(timer);
  }

  /**
   * Adds a {@apilink Scene} to the engine, think of scenes in Excalibur as you
   * would levels or menus.
   * @param key  The name of the scene, must be unique
   * @param scene The scene to add to the engine
   */
  public function addScene(key: String, scene: TypeofScene): Engine {
    this.director.add(key, scene);
    return this;
  }

  /**
   * @internal
   */
  public function removeScene(entity: TypeofScene): Void {
    this.director.remove(entity);
  }

  public function add(entity: Any): Void {
    if (arguments.length == 2) {
      this.director.add(arguments[0], arguments[1]);
      return;
    }
    var maybeDeferred = this.director.getDeferredScene();
    if (Std.isOfType(maybeDeferred, Scene)) {
      maybeDeferred.add(entity);
    } else {
      this.currentScene.add(entity);
    }
  }

  /**
   * Removes a {@apilink ScreenElement} from the scene, it will no longer be drawn or updated
   * @param screenElement  The ScreenElement to remove from the {@apilink currentScene}
   */
  public function remove(entity: Any): Void {
    if (Std.isOfType(entity, Entity)) {
      this.currentScene.remove(entity);
    }

    if (Std.isOfType(entity, Scene) || isSceneConstructor(entity)) {
      this.removeScene(entity);
    }

    if (Std.isOfType(entity, String)) {
      this.removeScene(entity);
    }
  }

  /**
   * Changes the current scene with optionally supplied:
   * * Activation data
   * * Transitions
   * * Loaders
   *
   * Example:
   * ```typescript
   * game.goToScene('myScene', {
   *   sceneActivationData: {any: 'thing at all'},
   *   destinationIn: new FadeInOut({duration: 1000, direction: 'in'}),
   *   sourceOut: new FadeInOut({duration: 1000, direction: 'out'}),
   *   loader: MyLoader
   * });
   * ```
   *
   * Scenes are defined in the Engine constructor
   * ```typescript
   * const engine = new ex.Engine({
      scenes: {...}
    });
   * ```
   * Or by adding dynamically
   *
   * ```typescript
   * engine.addScene('myScene', new ex.Scene());
   * ```
   * @param destinationScene
   * @param options
   */
  public function goToScene(destinationScene: WithRoot<TKnownScenes>, ?options: GoToOptions<TData>): Promise<Void> {
    this.scope(() -> {
      this.director.goToScene(destinationScene, options);
    });
  }

  /**
   * Transforms the current x, y from screen coordinates to world coordinates
   * @param point  Screen coordinate to convert
   */
  public function screenToWorldCoordinates(point: Vector): Vector {
    return this.screen.screenToWorldCoordinates(point);
  }

  /**
   * Transforms a world coordinate, to a screen coordinate
   * @param point  World coordinate to convert
   */
  public function worldToScreenCoordinates(point: Vector): Vector {
    return this.screen.worldToScreenCoordinates(point);
  }

  /**
   * Initializes the internal canvas, rendering context, display mode, and native event listeners
   */
  private function _initialize(?options: EngineOptions) {
    this.pageScrollPreventionMode = options.scrollPreventionMode;

    // initialize inputs
    var pointerTarget = options && options.pointerScope == PointerScope.Document ? document : this.canvas;
    var grabWindowFocus = this._originalOptions?.grabWindowFocus ?? true;
    this.input = new InputHost({
      global: this.global,
      pointerTarget: pointerTarget,
      grabWindowFocus: grabWindowFocus,
      engine: this
    });
    this.inputMapper = this.input.inputMapper;

    // Issue #385 make use of the visibility api
    // https://developer.mozilla.org/en-US/docs/Web/Guide/User_experience/Using_the_Page_Visibility_API

    this.browser.document.on('visibilitychange', () -> {
      if (document.visibilityState == 'hidden') {
        this.events.emit('hidden', new HiddenEvent(this));
        this._logger.debug('Window hidden');
      } else if (document.visibilityState == 'visible') {
        this.events.emit('visible', new VisibleEvent(this));
        this._logger.debug('Window visible');
      }
    });

    if (!this.canvasElementId && !options.canvasElement) {
      document.body.appendChild(this.canvas);
    }
  }

  public function toggleInputEnabled(enabled: Bool) {
    this._inputEnabled = enabled;
    this.input.toggleEnabled(this._inputEnabled);
  }

  public function onInitialize(engine: Engine) {
    // Override me
  }

  /**
   * Gets whether the actor is Initialized
   */
  public var isInitialized(get, never): Bool;
  function get_isInitialized(): Bool {
    return this._isInitialized;
  }

  private function _overrideInitialize(engine: Engine) {
    if (!this.isInitialized) {
      this.director.onInitialize().then(() -> {
        this.onInitialize(engine).then(() -> {
          this.events.emit('initialize', new InitializeEvent(engine, this));
          this._isInitialized = true;
        });
      });
    }
  }

  /**
   * Updates the entire state of the game
   * @param elapsed  Number of milliseconds elapsed since the last update.
   */
  private function _update(elapsed: Int) {
    if (this._isLoading) {
      // suspend updates until loading is finished
      this._loader?.onUpdate(this, elapsed);
      // Update input listeners
      this.input.update();
      return;
    }

    // Publish preupdate events
    this.clock.__runScheduledCbs('preupdate');
    this._preupdate(elapsed);

    // process engine level events
    this.currentScene.update(this, elapsed);

    // Update graphics postprocessors
    this.graphicsContext.updatePostProcessors(elapsed);

    // Publish update event
    this.clock.__runScheduledCbs('postupdate');
    this._postupdate(elapsed);

    // Update input listeners
    this.input.update();
  }

  /**
   * @internal
   */
  public function _preupdate(elapsed: Int) {
    this.emit('preupdate', new PreUpdateEvent(this, elapsed, this));
    this.onPreUpdate(this, elapsed);
  }

  /**
   * Safe to override method
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPreUpdate(engine: Engine, elapsed: Int) {
    // Override me
  }

  /**
   * @internal
   */
  public function _postupdate(elapsed: Int) {
    this.emit('postupdate', new PostUpdateEvent(this, elapsed, this));
    this.onPostUpdate(this, elapsed);
  }

  /**
   * Safe to override method
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPostUpdate(engine: Engine, elapsed: Int) {
    // Override me
  }

  /**
   * Draws the entire game
   * @param elapsed  Number of milliseconds elapsed since the last draw.
   */
  private function _draw(elapsed: Int) {
    // Use scene background color if present, fallback to engine
    this.graphicsContext.backgroundColor = this.currentScene.backgroundColor ?? this.backgroundColor;
    this.graphicsContext.beginDrawLifecycle();
    this.graphicsContext.clear();
    this.clock.__runScheduledCbs('predraw');
    this._predraw(this.graphicsContext, elapsed);

    // Drawing nothing else while loading
    if (this._isLoading) {
      if (!this._hideLoader) {
        this._loader?.canvas.draw(this.graphicsContext, 0, 0);
        this.clock.__runScheduledCbs('postdraw');
        this.graphicsContext.flush();
        this.graphicsContext.endDrawLifecycle();
      }
      return;
    }

    this.currentScene.draw(this.graphicsContext, elapsed);

    this.clock.__runScheduledCbs('postdraw');
    this._postdraw(this.graphicsContext, elapsed);

    // Flush any pending drawings
    this.graphicsContext.flush();
    this.graphicsContext.endDrawLifecycle();

    this._checkForScreenShots();
  }

  /**
   * @internal
   */
  public function _predraw(ctx: ExcaliburGraphicsContext, elapsed: Int) {
    this.emit('predraw', new PreDrawEvent(ctx, elapsed, this));
    this.onPreDraw(ctx, elapsed);
  }

  /**
   * Safe to override method to hook into pre draw
   * @param ctx {@link ExcaliburGraphicsContext} for drawing
   * @param elapsed  Number of milliseconds elapsed since the last draw.
   */
  public function onPreDraw(ctx: ExcaliburGraphicsContext, elapsed: Int) {
    // Override me
  }

  /**
   * @internal
   */
  public function _postdraw(ctx: ExcaliburGraphicsContext, elapsed: Int) {
    this.emit('postdraw', new PostDrawEvent(ctx, elapsed, this));
    this.onPostDraw(ctx, elapsed);
  }

  /**
   * Safe to override method to hook into pre draw
   * @param ctx {@link ExcaliburGraphicsContext} for drawing
   * @param elapsed  Number of milliseconds elapsed since the last draw.
   */
  public function onPostDraw(ctx: ExcaliburGraphicsContext, elapsed: Int) {
    // Override me
  }

  /**
   * Enable or disable Excalibur debugging functionality.
   * @param toggle a value that debug drawing will be changed to
   */
  public function showDebug(toggle: Bool): Void {
    this._isDebug = toggle;
  }

  /**
   * Toggle Excalibur debugging functionality.
   */
  public function toggleDebug(): Bool {
    this._isDebug = !this._isDebug;
    return this._isDebug;
  }

  /**
   * Returns true when loading is totally complete and the player has clicked start
   */
  public var loadingComplete(get, never): Bool;
  function get_loadingComplete() {
    return !this._isLoading;
  }

  private var _isLoading = false;
  private var _hideLoader = false;
  private var _isReadyFuture = new Future<Void>();
  public var ready(get, never): Bool;
  function get_ready() {
    return this._isReadyFuture.isCompleted;
  }
  public function isReady(): Promise<Void> {
    return this._isReadyFuture.promise;
  }

  public function start(?sceneNameOrLoader: RootOrLoader, ?options: StartOptions): Promise<Void> {
    this.scope(() -> {
      if (!this._compatible) {
        throw new Error('Excalibur is incompatible with your browser');
      }
      this._isLoading = true;
      var loader: DefaultLoader;
      if (Std.isOfType(sceneNameOrLoader, DefaultLoader)) {
        loader = sceneNameOrLoader;
      } else if (Std.isOfType(sceneNameOrLoader, String)) {
        this.director.configureStart(sceneNameOrLoader, options);
        loader = this.director.mainLoader;
      }

      // Start the excalibur clock which drives the mainloop
      this._logger.debug('Starting game clock...');
      this.browser.resume();
      this.clock.start();
      if (this.garbageCollectorConfig) {
        this._garbageCollector.start();
      }
      this._logger.debug('Game clock started');

      this.load(loader ?? new Loader()).then(() -> {
        // Initialize before ready
        this._overrideInitialize(this).then(() -> {
          this._isReadyFuture.resolve();
          this.emit('start', new GameStartEvent(this));
        });
      });

      return this._isReadyFuture.promise;
    });
  }

  /**
   * Returns the current frames elapsed milliseconds
   */
  public var currentFrameElapsedMs = 0;

  /**
   * Returns the current frame lag when in fixed update mode
   */
  public var currentFrameLagMs = 0;

  private var _lagMs = 0;
  private function _mainloop(elapsed: Int) {
    this.scope(() -> {
      this.emit('preframe', new PreFrameEvent(this, this.stats.prevFrame));
      var elapsedMs = elapsed * this.timescale;
      this.currentFrameElapsedMs = elapsedMs;

      // reset frame stats (reuse existing instances)
      var frameId = this.stats.prevFrame.id + 1;
      this.stats.currFrame.reset();
      this.stats.currFrame.id = frameId;
      this.stats.currFrame.elapsedMs = elapsedMs;
      this.stats.currFrame.fps = this.clock.fpsSampler.fps;
      GraphicsDiagnostics.clear();

      var beforeUpdate = this.clock.now();
      var fixedTimestepMs = this.fixedUpdateTimestep;
      if (this.fixedUpdateTimestep) {
        this._lagMs += elapsedMs;
        while (this._lagMs >= fixedTimestepMs) {
          this._update(fixedTimestepMs);
          this._lagMs -= fixedTimestepMs;
        }
      } else {
        this._update(elapsedMs);
      }
      var afterUpdate = this.clock.now();
      this.currentFrameLagMs = this._lagMs;
      this._draw(elapsedMs);
      var afterDraw = this.clock.now();

      this.stats.currFrame.duration.update = afterUpdate - beforeUpdate;
      this.stats.currFrame.duration.draw = afterDraw - afterUpdate;
      this.stats.currFrame.graphics.drawnImages = GraphicsDiagnostics.DrawnImagesCount;
      this.stats.currFrame.graphics.drawCalls = GraphicsDiagnostics.DrawCallCount;

      this.emit('postframe', new PostFrameEvent(this, this.stats.currFrame));
      this.stats.prevFrame.reset(this.stats.currFrame);

      this._monitorPerformanceThresholdAndTriggerFallback();
    });
  }

  /**
   * Stops Excalibur's main loop, useful for pausing the game.
   */
  public function stop() {
    if (this.clock.isRunning()) {
      this.emit('stop', new GameStopEvent(this));
      this.browser.pause();
      this.clock.stop();
      this._garbageCollector.stop();
      this._logger.debug('Game stopped');
    }
  }

  /**
   * Returns the Engine's running status, Useful for checking whether engine is running or paused.
   */
  public function isRunning() {
    return this.clock.isRunning();
  }

  private var _screenShotRequests: Array<{ preserveHiDPIResolution: Bool, resolve: (image: HTMLImageElement) -> Void }> = [];
  /**
   * Takes a screen shot of the current viewport and returns it as an
   * HTML Image Element.
   * @param preserveHiDPIResolution in the case of HiDPI return the full scaled backing image, by default false
   */
  public function screenshot(preserveHiDPIResolution = false): Promise<HTMLImageElement> {
    var screenShotPromise = new Promise<HTMLImageElement>((resolve) => {
      this._screenShotRequests.push({ preserveHiDPIResolution: preserveHiDPIResolution, resolve: resolve });
    });
    return screenShotPromise;
  }

  private function _checkForScreenShots() {
    // We must grab the draw buffer before we yield to the browser
    // the draw buffer is cleared after compositing
    // the reason for the asynchrony is setting `preserveDrawingBuffer: true`
    // forces the browser to copy buffers which can have a mass perf impact on mobile
    for (request in this._screenShotRequests) {
      var finalWidth = request.preserveHiDPIResolution ? this.canvas.width : this.screen.resolution.width;
      var finalHeight = request.preserveHiDPIResolution ? this.canvas.height : this.screen.resolution.height;
      var screenshot = document.createElement('canvas');
      screenshot.width = finalWidth;
      screenshot.height = finalHeight;
      var ctx = screenshot.getContext('2d');
      ctx.imageSmoothingEnabled = this.screen.antialiasing;
      ctx.drawImage(this.canvas, 0, 0, finalWidth, finalHeight);

      var result = new Image();
      var raw = screenshot.toDataURL('image/png');
      result.onload = () -> {
        request.resolve(result);
      };
      result.src = raw;
    }
    // Reset state
    this._screenShotRequests.length = 0;
  }

  /**
   * Another option available to you to load resources into the game.
   * Immediately after calling this the game will pause and the loading screen
   * will appear.
   * @param loader  Some {@apilink Loadable} such as a {@apilink Loader} collection, {@apilink Sound}, or {@apilink Texture}.
   */
  public function load(loader: DefaultLoader, hideLoader = false): Promise<Void> {
    this.scope(() -> {
      try {
        // early exit if loaded
        if (loader.isLoaded()) {
          return;
        }
        this._loader = loader;
        this._isLoading = true;
        this._hideLoader = hideLoader;

        if (Std.isOfType(loader, Loader)) {
          loader.suppressPlayButton = loader.suppressPlayButton || this._suppressPlayButton;
        }
        this._loader.onInitialize(this);

        loader.load();
      } catch (e) {
        this._logger.error('Error loading resources, things may not behave properly', e);
        Promise.resolve();
      }

      this._isLoading = false;
      this._hideLoader = false;
      this._loader = null;
    });
  }
}
