package nebula.director;

import nebula.Color;
import nebula.interfaces.Loadable;
import nebula.util.DrawUtil;

import nebula.math.Vector;
import nebula.util.Util;

import nebula.EventEmitter;
import nebula.director.DefaultLoader;

import nebula.Engine;
import nebula.Screen;

import nebula.util.Log;
import nebula.util.Future;

interface LoaderOptions extends DefaultLoaderOptions {
  /**
   * Go fullscreen after loading and clicking play
   */
  var fullscreenAfterLoad: Null<Bool>;
  /**
   * Fullscreen container element or id
   */
  var fullscreenContainer: Null<Any>;
}

/**
 * Pre-loading assets
 *
 * The loader provides a mechanism to preload multiple resources at
 * one time. The loader must be passed to the engine in order to
 * trigger the loading progress bar.
 *
 * The {@apilink Loader} itself implements {@apilink Loadable} so you can load loaders.
 *
 * ## Example: Pre-loading resources for a game
 *
 * ```js
 * // create a loader
 * var loader = new ex.Loader();
 *
 * // create a resource dictionary (best practice is to keep a separate file)
 * var resources = {
 *   TextureGround: new ex.Texture("/images/textures/ground.png"),
 *   SoundDeath: new ex.Sound("/sound/death.wav", "/sound/death.mp3")
 * };
 *
 * // loop through dictionary and add to loader
 * for (var loadable in resources) {
 *   if (resources.hasOwnProperty(loadable)) {
 *     loader.addResource(resources[loadable]);
 *   }
 * }
 *
 * // start game
 * game.start(loader).then(function () {
 *   console.log("Game started!");
 * });
 * ```
 *
 * ## Customize the Loader
 *
 * The loader can be customized to show different, text, logo, background color, and button.
 *
 * ```typescript
 * const loader = new ex.Loader([playerTexture]);
 *
 * // The loaders button text can simply modified using this
 * loader.playButtonText = 'Start the best game ever';
 *
 * // The logo can be changed by inserting a base64 image string here
 *
 * loader.logo = 'data:image/png;base64,iVBORw...';
 * loader.logoWidth = 15;
 * loader.logoHeight = 14;
 *
 * // The background color can be changed like so by supplying a valid CSS color string
 *
 * loader.backgroundColor = 'red'
 * loader.backgroundColor = '#176BAA'
 *
 * // To build a completely new button
 * loader.startButtonFactory = () => {
 *     let myButton = document.createElement('button');
 *     myButton.textContent = 'The best button';
 *     return myButton;
 * };
 *
 * engine.start(loader).then(() => {});
 * ```
 */
class Loader extends DefaultLoader {
  private var _logger = Logger.getInstance();
  private static var _DEFAULT_LOADER_OPTIONS: LoaderOptions = {
    loadables: [],
    fullscreenAfterLoad: false,
    fullscreenContainer: undefined
  };
  private var _originalOptions: LoaderOptions = { loadables: [] };
  public var events = new EventEmitter();
  public var screen: Screen;
  private var _playButtonShown: Bool = false;

  // logo drawing stuff

  // base64 string encoding of the excalibur logo (logo-white.png)
  public var logo = logoImg;
  public var logoWidth = 468;
  public var logoHeight = 118;
  /**
   * Positions the top left corner of the logo image
   * If not set, the loader automatically positions the logo
   */
  public var logoPosition: Null<Vector>;
  /**
   * Positions the top left corner of the play button.
   * If not set, the loader automatically positions the play button
   */
  public var playButtonPosition: Null<Vector>;
  /**
   * Positions the top left corner of the loading bar
   * If not set, the loader automatically positions the loading bar
   */
  public var loadingBarPosition: Null<Vector>;

  /**
   * Gets or sets the color of the loading bar, default is {@apilink Color.White}
   */
  public var loadingBarColor: Color = Color.White;

  /**
   * Gets or sets the background color of the loader as a hex string
   */
  public var backgroundColor: String = '#176BAA';

  var _imageElement: Any;
  var _imageLoaded: Future<Void> = new Future();
  var _image(get, never): Any;
  function get__image() {
    // if (!this._imageElement) {
    //   this._imageElement = new Image();
    //   this._imageElement.onload = () -> this._imageLoaded.resolve();
    //   this._imageElement.src = this.logo;
    // }

    return this._imageElement;
  }

  public var suppressPlayButton: Bool = false;
  public var playButtonRootElement(get, never): Null<Any>;
  function get_playButtonRootElement() {
    return this._playButtonRootElement;
  }

  public var playButtonElement(get, never): Null<Any>;
  function get_playButtonElement() {
    return this._playButtonElement;
  }
  var _playButtonRootElement: Any;
  var _playButtonElement: Any;
  var _styleBlock: Any;
  /** Loads the css from Loader.css */
  var _playButtonStyles: String = loaderCss;
  public var _playButton(get, never): Any;
  function get__playButton() {
    final existingRoot = document.getElementById('excalibur-play-root');
    if (existingRoot) {
      this._playButtonRootElement = existingRoot;
    }
    if (!this._playButtonRootElement) {
      this._playButtonRootElement = document.createElement('div');
      this._playButtonRootElement.id = 'excalibur-play-root';
      this._playButtonRootElement.style.position = 'absolute';
      document.body.appendChild(this._playButtonRootElement);
    }
    if (!this._styleBlock) {
      this._styleBlock = document.createElement('style');
      this._styleBlock.textContent = this._playButtonStyles;
      document.head.appendChild(this._styleBlock);
    }
    if (!this._playButtonElement) {
      this._playButtonElement = this.startButtonFactory();
      this._playButtonRootElement.appendChild(this._playButtonElement);
    }
    return this._playButtonElement;
  }

  /**
   * Get/set play button text
   */
  public var playButtonText: String = 'Play game';

  /**
   * Return a html button element for excalibur to use as a play button
   */
  public var startButtonFactory = () -> {
    var buttonElement: Any = document.getElementById('excalibur-play');
    if (!buttonElement) {
      buttonElement = document.createElement('button');
    }

    buttonElement.id = 'excalibur-play';
    buttonElement.textContent = this.playButtonText;
    buttonElement.style.display = 'none';
    return buttonElement;
  };

  /**
   * @param loadables  Optionally provide the list of resources you want to load at constructor time
   */
  public function new(options: LoaderOptions) {
    super(options);
    this._originalOptions = Object.spreadWith(Loader._DEFAULT_LOADER_OPTIONS, options);
  }

  public override function onInitialize(engine: Engine): Void {
    this.engine = engine;
    this.screen = engine.screen;
    this.canvas.width = this.engine.canvas.width;
    this.canvas.height = this.engine.canvas.height;
    this.screen.events.on('resize', () -> {
      this.canvas.width = this.engine.canvas.width;
      this.canvas.height = this.engine.canvas.height;
    });
  }

  /**
   * Shows the play button and returns a promise that resolves when clicked
   */
  public function showPlayButton(): Any {
    if (this.suppressPlayButton) {
      this.hidePlayButton();
      // Delay is to give the logo a chance to show, otherwise don't delay
      delay(500, this.engine?.clock);
    } else {
      var resizeHandler = () -> {
        try {
          this._positionPlayButton();
        } catch (e: Any) {
          // swallow if can't position
        }
      };
      if (this.engine?.browser) {
        this.engine.browser.window.on('resize', resizeHandler);
      }
      this._playButtonShown = true;
      this._playButton.style.display = 'block';
      document.body.addEventListener('keyup', (evt: KeyboardEvent) => {
        if (evt.key == 'Enter') {
          this._playButton.click();
        }
      });
      this._positionPlayButton();
      // var playButtonClicked = new Promise<Void>((resolve) -> {
      //   var startButtonHandler = (e: Event) => {
      //     // We want to stop propagation to keep bubbling to the engine pointer handlers
      //     e.stopPropagation();
      //     // Hide Button after click
      //     this.hidePlayButton();
      //     if (this.engine?.browser) {
      //       this.engine.browser.window.off('resize', resizeHandler);
      //     }

      //     if (this._originalOptions.fullscreenAfterLoad) {
      //       try {
      //         this._logger.info('requesting fullscreen');
      //         if (Std.isOfType(this._originalOptions.fullscreenContainer, HTMLElement)) {
      //           // eslint-disable-next-line @typescript-eslint/no-floating-promises
      //           this._originalOptions.fullscreenContainer.requestFullscreen();
      //         } else {
      //           // eslint-disable-next-line @typescript-eslint/no-floating-promises
      //           this.engine.screen.enterFullscreen(this._originalOptions.fullscreenContainer);
      //         }
      //       } catch (error) {
      //         this._logger.error('could not go fullscreen', error);
      //       }
      //     }

      //     resolve();
      //   };
      //   this._playButton.addEventListener('click', startButtonHandler);
      //   this._playButton.addEventListener('touchend', startButtonHandler);
      //   this._playButton.addEventListener('pointerup', startButtonHandler);
      //   if (this.engine) {
      //     this.engine.input.gamepads.once('button', () -> startButtonHandler(new Event('button')));
      //   }
      // });

      return playButtonClicked;
    }
  }

  public function hidePlayButton() {
    this._playButtonShown = false;
    this._playButton.style.display = 'none';
  }

  /**
   * Clean up generated elements for the loader
   */
  public function dispose() {
    if (this._playButtonRootElement.parentElement) {
      this._playButtonRootElement.removeChild(this._playButtonElement);
      document.body.removeChild(this._playButtonRootElement);
      document.head.removeChild(this._styleBlock);
      this._playButtonRootElement = null;
      this._playButtonElement = null;
      this._styleBlock = null;
    }
  }

  public override function onUserAction(): Any {
    // short delay in showing the button for aesthetics
    delay(200, this.engine?.clock);
    this.canvas.flagDirty();
    // show play button
    this.showPlayButton();
  }

  public override function onBeforeLoad(): Any {
    this.screen.pushResolutionAndViewport();
    this.screen.resolution = { width: this.canvas.width, height: this.canvas.height };
    this.screen.applyResolutionAndViewport();
    var image = this._image;
    this._imageLoaded.promise;
    image?.decode(); // decode logo if it exists
  }

  // eslint-disable-next-line require-await
  public override function onAfterLoad(): Any {
    this.screen.popResolutionAndViewport();
    this.screen.applyResolutionAndViewport();
    this.dispose();
  }

  private function _positionPlayButton() {
    if (this.engine) {
      final bcr = this.engine.canvas.getBoundingClientRect();
      var left = bcr.x,
            top = bcr.y,
            screenWidth = bcr.width,
            screenHeight = bcr.height;

      if (this._playButtonRootElement) {
        var buttonWidth = this._playButton.clientWidth;
        var buttonHeight = this._playButton.clientHeight;
        if (this.playButtonPosition) {
          this._playButtonRootElement.style.left = '${this.playButtonPosition.x}px';
          this._playButtonRootElement.style.top = '${this.playButtonPosition.y}px';
        } else {
          this._playButtonRootElement.style.left = '${left + screenWidth / 2 - buttonWidth / 2}px';
          this._playButtonRootElement.style.top = '${top + screenHeight / 2 - buttonHeight / 2 + 100}px';
        }
      }
    }
  }

  /**
   * Loader draw function. Draws the default Excalibur loading screen.
   * Override `logo`, `logoWidth`, `logoHeight` and `backgroundColor` properties
   * to customize the drawing, or just override entire method.
   */
  public override function onDraw(ctx: Any) {
    var canvasHeight = this.engine.canvasHeight / this.engine.pixelRatio;
    var canvasWidth = this.engine.canvasWidth / this.engine.pixelRatio;

    this._positionPlayButton();

    ctx.fillStyle = this.backgroundColor;
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    var logoY = canvasHeight / 2;
    var width = Math.min(this.logoWidth, canvasWidth * 0.75);
    var logoX = canvasWidth / 2 - width / 2;

    if (this.logoPosition) {
      logoX = this.logoPosition.x;
      logoY = this.logoPosition.y;
    }

    var imageHeight = Math.floor(width * (this.logoHeight / this.logoWidth)); // OG height/width factor
    var oldAntialias = this.engine.screen.antialiasing;
    this.engine.screen.antialiasing = true;
    if (!this.logoPosition) {
      ctx.drawImage(this._image, 0, 0, this.logoWidth, this.logoHeight, logoX, logoY - imageHeight - 20, width, imageHeight);
    } else {
      ctx.drawImage(this._image, 0, 0, this.logoWidth, this.logoHeight, logoX, logoY, width, imageHeight);
    }

    // loading box
    if (!this.suppressPlayButton && this._playButtonShown) {
      this.engine.screen.antialiasing = oldAntialias;
      return;
    }

    var loadingX = logoX;
    var loadingY = logoY;
    if (this.loadingBarPosition) {
      loadingX = this.loadingBarPosition.x;
      loadingY = this.loadingBarPosition.y;
    }

    ctx.lineWidth = 2;
    DrawUtil.roundRect(ctx, loadingX, loadingY, width, 20, 10, this.loadingBarColor);
    var progress = width * this.progress;
    var margin = 5;
    var progressWidth = progress - margin * 2;
    var height = 20 - margin * 2;
    DrawUtil.roundRect(
      ctx,
      loadingX + margin,
      loadingY + margin,
      progressWidth > 10 ? progressWidth : 10,
      height,
      5,
      null,
      this.loadingBarColor
    );
    this.engine.screen.antialiasing = oldAntialias;
  }
}
