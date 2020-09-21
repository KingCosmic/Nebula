package core;

import kha.Image;
import core.gameobjects.GameObject;
import kha.math.FastMatrix3;
import core.structs.Size;
import core.gameobjects.components.TransformMatrix;
import core.cameras.Camera;
import core.gameobjects.DisplayList;
import core.scene.Scene;
import kha.Color;

import kha.graphics2.Graphics;

/**
 * The game class prepares a backbuffer to which states draw. The
 * backbuffer is defined by the game's rendering resolution (width
 * and height). It also handles states and state changes.
 */
class Renderer {
  // The Phaser Game isntance that owns this renderer.
  public var game:Game;

  // The total number of Game Objects which were rendered in a frame.
  public var drawCount:Int = 0;

  // The width of the canvas being rendered to.
  public var width:Float = 0;

  // The height of the canvas being rendered to.
  public var height:Float = 0;

  // The local configuration settings of the Renderer.
  public var config = {
    clearBeforeRender: true,
    backgroundColor: Color.fromBytes(0, 0, 0),
    antialias: false,
    roundPixels: false
  }

  // current Graphics (updated every time notifyFrames runs)
  public var graphics:Graphics;

  public var contextOptions = {
    alpha: true,
    desynchronized: false
  };

  // Should the Canvas use Image Smoothing or not when drawing Sprites?
  public var antialias:Bool = true;

  // The blend modes supported by the renderer
  public var blendModes = [
    'source-over',
    'lighter',
    'multiply',
    'screen',
    'overlay',
    'darken',
    'lighten',
    'color-dodge',
    'color-burn',
    'hard-light',
    'soft-light',
    'difference',
    'exclusion',
    'hue',
    'saturation',
    'color',
    'luminosity',
    'destination-out',
    'source-in',
    'source-out',
    'source-atop',
    'destination-over',
    'destination-in',
    'destination-out',
    'destination-atop',
    'lighter',
    'copy',
    'xor'
  ];

	// A temporary Transform Matrix, re-used internally during batching.
  public var _tempMatrix1 = new TransformMatrix();

	// A temporary Transform Matrix, re-used internally during batching.
  public var _tempMatrix2 = new TransformMatrix();
  
	// A temporary Transform Matrix, re-used internally during batching.
  public var _tempMatrix3 = new TransformMatrix();
  
	// A temporary Transform Matrix, re-used internally during batching.
	public var _tempMatrix4 = new TransformMatrix();

  public function new(_game:Game) {
    game = _game;

    init();
  }

  // Prepares the game canvas for rendering.
  public function init() {
    game.scale.on('RESIZE', onResize);

    var baseSize = game.scale.baseSize;

    resize(baseSize.width, baseSize.height);
  }

  // The event handler that manages the `resize` event dispatched by the Scale Manager.
  public function onResize(gameSize:Size, baseSize:Size) {
    // Hase the underlying canvas size changed?
		if (baseSize.width != width || baseSize.height != height) {
			resize(baseSize.width, baseSize.height);
		}
  }

  // Resize the main game canvas.
  public function resize(_width:Float, _height:Float) {
    width = _width;
    height = _height;
  }

  // Resets the transformation matrix of the current context to the identity matrix, thus resetting any transformation.
  public function resetTransform() {
		// TODO:
  }

  // Sets the blend mode (compositing operation) of the current context.
  public function setBlendMode(blendMode:String) {
    // TODO:
  }

  // Sets the global alpha of the current context.
  public function setAlpha(alpha:Float) {
    graphics.set_opacity(alpha);

    return this;
  }

  public function preRender(_graphics:Graphics) {
    graphics = _graphics;

    graphics.set_opacity(1);

		// Start drawing, and clear the framebuffer to `petrol`
    graphics.begin(config.clearBeforeRender, Color.fromBytes(0, 0, 0));

    // save?

    drawCount = 0;
  }

  /**
   * The core render step for a Scene Camera.
   *
   * Iterates through the given Game Object's array and renders them with the given Camera.
   *
   * This is called by the `CameraManager.render` method. The Camera Manager instance belongs to a Scene, and is invoked
   * by the Scene Systems.render method.
   *
   * This method is not called if `Camera.visible` is `false`, or `Camera.alpha` is zero.
   */
	public function render(scene:Scene, children:DisplayList, camera:Camera) {
    
    var list = children.children;
    var childCount = list.length;

    // TODO: add this functionality
		// var ctx = (camera.renderToTexture) ? camera.context : scene.sys.context;
    
    drawCount += childCount;

    for (child in list) {
      // will this child render via this camera?
      if (!child.willRender(camera)) {
        continue;
      }

      // TODO: mask

      child.render(this, camera);

      // TODO: mask
    }

    camera.dirty = false;

    // TODO: renderToTexture
  }

  public function postRender() {
		// Finish the drawing operations
    graphics.end();
  }

  // Takes a Image Game Object, or any object that extends it, and draws it to the current context.
  public function batchImage(child:core.gameobjects.Image, frame:Image, camera:Camera) {
    var alpha = camera.alpha * child.alpha;

    // Nothing to see, so abort early
    if (alpha == 0) return;

    var x = child.x - (child.originX * child.width);
    var y = child.y - (child.originY * child.height);

    graphics.drawImage(frame, x - (child.scrollFactorX * camera.scrollX), y - (child.scrollFactorY * camera.scrollY));
  }

  public function destroy() {
    graphics = null;
    game = null;
  }
}