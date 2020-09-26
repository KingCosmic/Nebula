package core.scale;

import core.scale.const.SCALE_MODE_CONST;
import core.Game.GameConfig;
import core.structs.Size;
import kha.math.Vector2;

/**
 * @classdesc
 * The Scale Manager handles the scaling, resizing and alignment of the game canvas.
 *
 * The way scaling is handled is by setting the game canvas to a fixed size, which is defined in the
 * game configuration. You also define the parent container in the game config. If no parent is given,
 * it will default to using the document body. The Scale Manager will then look at the available space
 * within the _parent_ and scale the canvas accordingly. Scaling is handled by setting the canvas CSS
 * width and height properties, leaving the width and height of the canvas element itself untouched.
 * Scaling is therefore achieved by keeping the core canvas the same size and 'stretching'
 * it via its CSS properties. This gives the same result and speed as using the `transform-scale` CSS
 * property, without the need for browser prefix handling.
 *
 * The calculations for the scale are heavily influenced by the bounding parent size, which is the computed
 * dimensions of the canvas's parent. The CSS rules of the parent element play an important role in the
 * operation of the Scale Manager. For example, if the parent has no defined width or height, then actions
 * like auto-centering will fail to achieve the required result. The Scale Manager works in tandem with the
 * CSS you set-up on the page hosting your game, rather than taking control of it.
 *
 * #### Parent and Display canvas containment guidelines:
 *
 * - Style the Parent element (of the game canvas) to control the Parent size and thus the games size and layout.
 *
 * - The Parent element's CSS styles should _effectively_ apply maximum (and minimum) bounding behavior.
 *
 * - The Parent element should _not_ apply a padding as this is not accounted for.
 *   If a padding is required apply it to the Parent's parent or apply a margin to the Parent.
 *   If you need to add a border, margin or any other CSS around your game container, then use a parent element and
 *   apply the CSS to this instead, otherwise you'll be constantly resizing the shape of the game container.
 *
 * - The Display canvas layout CSS styles (i.e. margins, size) should not be altered / specified as
 *   they may be updated by the Scale Manager.
 *
 * #### Scale Modes
 *
 * The way the scaling is handled is determined by the `scaleMode` property. The default is `NONE`,
 * which prevents Phaser from scaling or touching the canvas, or its parent, at all. In this mode, you are
 * responsible for all scaling. The other scaling modes afford you automatic scaling.
 *
 * If you wish to scale your game so that it always fits into the available space within the parent, you
 * should use the scale mode `FIT`. Look at the documentation for other scale modes to see what options are
 * available. Here is a basic config showing how to set this scale mode:
 *
 * ```javascript
 * scale: {
 *     parent: 'yourgamediv',
 *     mode: Phaser.Scale.FIT,
 *     width: 800,
 *     height: 600
 * }
 * ```
 *
 * Place the `scale` config object within your game config.
 *
 * If you wish for the canvas to be resized directly, so that the canvas itself fills the available space
 * (i.e. it isn't scaled, it's resized) then use the `RESIZE` scale mode. This will give you a 1:1 mapping
 * of canvas pixels to game size. In this mode CSS isn't used to scale the canvas, it's literally adjusted
 * to fill all available space within the parent. You should be extremely careful about the size of the
 * canvas you're creating when doing this, as the larger the area, the more work the GPU has to do and it's
 * very easy to hit fill-rate limits quickly.
 *
 * For complex, custom-scaling requirements, you should probably consider using the `RESIZE` scale mode,
 * with your own limitations in place re: canvas dimensions and managing the scaling with the game scenes
 * yourself. For the vast majority of games, however, the `FIT` mode is likely to be the most used.
 *
 * Please appreciate that the Scale Manager cannot perform miracles. All it does is scale your game canvas
 * as best it can, based on what it can infer from its surrounding area. There are all kinds of environments
 * where it's up to you to guide and help the canvas position itself, especially when built into rendering
 * frameworks like React and Vue. If your page requires meta tags to prevent user scaling gestures, or such
 * like, then it's up to you to ensure they are present in the html.
 *
 * #### Centering
 *
 * You can also have the game canvas automatically centered. Again, this relies heavily on the parent being
 * properly configured and styled, as the centering offsets are based entirely on the available space
 * within the parent element. Centering is disabled by default, or can be applied horizontally, vertically,
 * or both. Here's an example:
 *
 * ```javascript
 * scale: {
 *     parent: 'yourgamediv',
 *     autoCenter: Phaser.Scale.CENTER_BOTH,
 *     width: 800,
 *     height: 600
 * }
 * ```
 *
 * #### Fullscreen API
 *
 * If the browser supports it, you can send your game into fullscreen mode. In this mode, the game will fill
 * the entire display, removing all browser UI and anything else present on the screen. It will remain in this
 * mode until your game either disables it, or until the user tabs out or presses ESCape if on desktop. It's a
 * great way to achieve a desktop-game like experience from the browser, but it does require a modern browser
 * to handle it. Some mobile browsers also support this.
 */
class ScaleManager extends EventEmitter {
  // A reference to the Phaser.Game instance this Scale Manager belongs to.
  public var game:Game;

  // A reference to the window object this scale manager is attached to.
  public var window:kha.Window;

  // The Canvas resolution.
  public var resolution:Float = 1;

  /**
   * The game zoom factor.
   *
   * This value allows you to multiply your games base size by the given zoom factor.
   * This is then used when calculating the display size, even in `NONE` situations.
   * If you don't want Phaser to touch the canvas style at all, this value should be 1.
   *
   * Can also be set to `MAX_ZOOM` in which case the zoom value will be derived based
   * on the game size and available space within the parent.
   */
  public var zoom:Float = 1;

  // Internal flag set when the game zoom factor is modified.
  public var _resetZoom:Bool = false;

  // The scale factor between the baseSize and the canvasBounds.
  public var displayScale:Vector2 = new Vector2(1, 1);

	/**
   * The Game Size component.
   *
   * The un-modified game size, as requested in the game config (the raw width / height),
   * as used for world bounds, cameras, etc
   */
  public var gameSize:Size = new Size();

	/**
   * The Base Size component.
   *
   * The modified game size, which is the auto-rounded gameSize, used to set the canvas width and height
   * (but not the CSS style)
   */
  public var baseSize:Size = new Size();

  // The game scale mode.
  public var scaleMode:Int = SCALE_MODE_CONST.RESIZE;

  /**
   * If set, the canvas sizes will be automatically passed through Math.floor.
   * This results in rounded pixel display values, which is important for performance on legacy
   * and low powered devices, but at the cost of not achieving a 'perfect' fit in some browser windows.
   */
  public var autoRound:Bool = false;

	/**
   * Automatically center the canvas within the parent? The different centering modes are:
   *
   * 1. No centering.
   * 2. Center both horizontally and vertically.
   * 3. Center horizontally.
   * 4. Center vertically.
   *
   * Please be aware that in order to center the game canvas, you must have specified a parent
   * that has a size set, or the canvas parent is the document.body.
   */
  public var autoCenter:Int = 1;

  /**
   * The current device orientation.
   * 
	 * Orientation events are dispatched via the Device Orientation API, typically only on mobile browsers.
   */
  public var orientation:String = 'landscape-primary';
  
  // Is this game fullscreened?
  public var isFullscreen:Bool = false;

	/**
   * The dirty state of the Scale Manager.
   * Set if there is a change between the parent size and the current size.
   */
  public var dirty:Bool = false;

  public function new(_game:Game) {
    super();

    game = _game;
  }

  // Called _before_ the canvas object is created and added to the DOM.
  public function preBoot(_window:kha.Window) {
    // Parse the config to get the scaling values we need
    parseConfig(game.config);

    window = _window;

    game.events.once('BOOT', boot);
  }

  /**
   * The Boot handler is called by Phaser.Game when it first starts up.
   * The renderer is available by now and the canvas has been added to the DOM.
   */
  public function boot() {
    refresh();

    game.events.once('READY', refresh);
    game.events.once('DESTROY', destroy);

    startListeners();
  }

  // Parses the game configuration to set-up the scale defaults.
  public function parseConfig(config:GameConfig) {
    var width = config.width;
    var height = config.height;

    if (autoRound) {
      width = Math.floor(width);
      height = Math.floor(height);
    }

		// The un-modified game size, as requested in the game config (the raw width / height) as used for world bounds, etc
    gameSize.setSize(width, height);

    // modified game size
    baseSize.setSize(width, height);

    // Isn't this just redundant since we already rounded
    // before setting baseSize
    if (autoRound) {
      baseSize.width = Math.floor(baseSize.width);
      baseSize.height = Math.floor(baseSize.height);
    }

		// orientation = getScreenOrientation(width, height);
  }

	/**
   * Attempts to lock the orientation of the web browser using the Screen Orientation API.
   *
   * This API is only available on modern mobile browsers.
   * See https://developer.mozilla.org/en-US/docs/Web/API/Screen/lockOrientation for details.
   */
  public function lockOrientation(orientation:String) {
    // TODO: add lock orientation functionality
  }

	/**
   * This method will set a new size for your game.
   *
   * It should only be used if you're looking to change the base size of your game and are using
   * one of the Scale Manager scaling modes, i.e. `FIT`. If you're using `NONE` and wish to
   * change the game and canvas size directly, then please use the `resize` method instead.
   */
  public function setGameSize(_width:Float, _height:Float) {
    if (autoRound) {
      _width = Math.floor(_width);
      _height = Math.floor(_height);
    }

    var previousWidth = gameSize.width;
    var previousHeight = gameSize.height;

    // The un-modified game size, as requested in the game config (the raw width / height) as used for world bounds, etc
    gameSize.resize(_width, _height);

    // The modified game size
    baseSize.resize(_width, _height);

    if (autoRound) {
      baseSize.width = Math.floor(baseSize.width);
      baseSize.height = Math.floor(baseSize.height);
    }

    return refresh(previousWidth, previousHeight);
  }

	/**
	 * Call this to modify the size of the Phaser canvas element directly.
	 * You should only use this if you are using the `NONE` scale mode,
	 * it will update all internal components completely.
	 *
	 * If all you want to do is change the size of the parent, see the `setParentSize` method.
	 *
	 * If all you want is to change the base size of the game, but still have the Scale Manager
	 * manage all the scaling (i.e. you're **not** using `NONE`), then see the `setGameSize` method.
	 *
	 * This method will set the `gameSize`, `baseSize` and `displaySize` components to the given
	 * dimensions. It will then resize the canvas width and height to the values given, by
	 * directly setting the properties. Finally, if you have set the Scale Manager zoom value
	 * to anything other than 1 (the default), it will set the canvas CSS width and height to
	 * be the given size multiplied by the zoom factor (the canvas pixel size remains untouched).
	 *
	 * If you have enabled `autoCenter`, it is then passed to the `updateCenter` method and
	 * the margins are set, allowing the canvas to be centered based on its parent element
	 * alone. Finally, the `displayScale` is adjusted and the RESIZE event dispatched.
   */
  public function resize(_width:Float, _height:Float) {
    if (autoRound) {
      _width = Math.floor(_width);
      _height = Math.floor(_height);
    }

    var previousWidth = gameSize.width;
    var previousHeight = gameSize.height;

		// The un-modified game size, as requested in the game config (the raw width / height) as used for world bounds, etc
		gameSize.resize(_width, _height);

		// The modified game size
    baseSize.resize(_width, _height);

		if (autoRound) {
			baseSize.width = Math.floor(baseSize.width);
			baseSize.height = Math.floor(baseSize.height);
		}

		return refresh(previousWidth, previousHeight);
  }

  // Sets the zoom value of the Scale Manager.
  public function setZoom(value:Float) {
    zoom = value;
    _resetZoom = true;

    return refresh();
  }

  // Sets the zoom to be the maximum possible based on the _current_ parent size.
  public function setMaxZoom() {
    zoom = getMaxZoom();
    _resetZoom = true;

    return refresh();
  }

	/**
	 * Refreshes the internal scale values, bounds sizes and orientation checks.
	 *
	 * Once finished, dispatches the resize event.
	 *
	 * This is called automatically by the Scale Manager when the browser window size changes,
	 * as long as it is using a Scale Mode other than 'NONE'.
   */
  public function refresh(?previousWidth:Float, ?previousHeight:Float) {
    if (previousWidth == null) previousWidth = gameSize.width;
    if (previousHeight == null) previousHeight = gameSize.height;

    updateScale();
    updateOrientation();

    emit('RESIZE', gameSize, baseSize, previousWidth, previousHeight);
    
    return this;
  }

	/**
	 * Internal method that checks the current screen orientation, only if the internal check flag is set.
	 *
	 * If the orientation has changed it updates the orientation property and then dispatches the orientation change event.
   */
  public function updateOrientation() {
    /* TODO: Fix this
    if (_checkOrientation) {
      _checkOrientation = false;

      var newOrientation = GetScreenOrientation(gameSize.width, gameSize.height);
      
      if (newOrientation != orientation) {
        orientation = newOrientation;

        emit('ORIENTATION_CHANGE', newOrientation);
      }
    }*/
  }

  // Internal method that manages updating the size components based on the scale mode.
  public function updateScale() {
		if (scaleMode == SCALE_MODE_CONST.RESIZE) {
			// Resize to match parent

			this.gameSize.setSize(window.width, window.height);

			this.baseSize.setSize(gameSize.width, gameSize.height);

			var canvasWidth = this.baseSize.width;
			var canvasHeight = this.baseSize.height;

			if (autoRound) {
				canvasWidth = Math.floor(canvasWidth);
				canvasHeight = Math.floor(canvasHeight);
      }
      
			this.baseSize.setSize(canvasWidth, canvasHeight);
		}
  }

	/**
	 * Calculates and returns the largest possible zoom factor, based on the current
	 * parent and game sizes. If the parent has no dimensions (i.e. an unstyled div),
	 * or is smaller than the un-zoomed game, then this will return a value of 1 (no zoom)
   */
  public function getMaxZoom() {
		return 1;
  }

	/**
   * Transforms the pageX value into the scaled coordinate space of the Scale Manager.
   */
  public function transformX(x:Float) {
    return x;
  }

	/**
	 * Transforms the pageY value into the scaled coordinate space of the Scale Manager.
   */
  public function transformY(y:Float) {
    return y;
  }

	/**
	 * Sends a request to the browser to ask it to go in to full screen mode, using the {@link https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API Fullscreen API}.
	 *
	 * If the browser does not support this, a `FULLSCREEN_UNSUPPORTED` event will be emitted.
	 *
	 * This method _must_ be called from a user-input gesture, such as `pointerup`. You cannot launch
	 * games fullscreen without this, as most browsers block it. Games within an iframe will also be blocked
	 * from fullscreen unless the iframe has the `allowfullscreen` attribute.
	 *
	 * On touch devices, such as Android and iOS Safari, you should always use `pointerup` and NOT `pointerdown`,
	 * otherwise the request will fail unless the document in which your game is embedded has already received
	 * some form of touch input, which you cannot guarantee. Activating fullscreen via `pointerup` circumvents
	 * this issue.
	 *
	 * Performing an action that navigates to another page, or opens another tab, will automatically cancel
 	 * fullscreen mode, as will the user pressing the ESC key. To cancel fullscreen mode directly from your game,
	 * i.e. by clicking an icon, call the `stopFullscreen` method.
	 *
	 * A browser can only send one DOM element into fullscreen. You can control which element this is by
	 * setting the `fullscreenTarget` property in your game config, or changing the property in the Scale Manager.
	 * Note that the game canvas _must_ be a child of the target. If you do not give a target, Phaser will
	 * automatically create a blank `<div>` element and move the canvas into it, before going fullscreen.
	 * When it leaves fullscreen, the div will be removed.
   */
  public function startFullscreen(fullscreenOptions) {
    // TODO:
  }

  // Calling this method will cancel fullscreen mode, if the browser has entered it.
  public function stopFullscreen() {
    // TODO:
  }

	/**
	 * Toggles the fullscreen mode. If already in fullscreen, calling this will cancel it.
	 * If not in fullscreen, this will request the browser to enter fullscreen mode.
	 *
	 * If the browser does not support this, a `FULLSCREEN_UNSUPPORTED` event will be emitted.
	 *
	 * This method _must_ be called from a user-input gesture, such as `pointerdown`. You cannot launch
	 * games fullscreen without this, as most browsers block it. Games within an iframe will also be blocked
	 * from fullscreen unless the iframe has the `allowfullscreen` attribute.
   */
  public function toggleFullscreen() {
    // TODO:
  }

  // An internal method that starts the different DOM event listeners running.
  public function startListeners() {
    window.notifyOnResize((_width, _height) -> {
      setGameSize(_width, _height);
    });
  }

	/**
	 * Is the device in a portrait orientation as reported by the Orientation API?
	 * This value is usually only available on mobile devices.
   */
  public function isPortrait() {
		return (orientation == 'portrait-primary');
  }

	/**
	 * Is the device in a landscape orientation as reported by the Orientation API?
	 * This value is usually only available on mobile devices.
   */
  public function isLandscape() {
    return (orientation == 'landscape-primary');
  }

	/**
	 * Are the game dimensions portrait? (i.e. taller than they are wide)
	 *
	 * This is different to the device itself being in a portrait orientation.
   */
  public function isGamePortrait() {
    return (gameSize.height > gameSize.width);
  }

	/**
	 * Are the game dimensions landscape? (i.e. wider than they are tall)
	 *
	 * This is different to the device itself being in a landscape orientation.
   */
  public function isGameLandscape() {
    return (gameSize.width > gameSize.height);
  }

  /**
   * Destroys this Scale Manager, releasing all references to external resources.
   * Once destroyed, the Scale Manager cannot be used again.
   */
  public function destroy() {
    game = null;
  }
}