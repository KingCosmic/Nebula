package nebula;

import kha.Display;
import nebula.gameobjects.components.TransformMatrix;
import nebula.gameobjects.GameObject;
import nebula.gameobjects.DisplayList;
import nebula.textures.Frame;
import nebula.cameras.Camera;
import nebula.structs.Size;
import nebula.scene.Scene;
import kha.math.Vector2;
import kha.Framebuffer;
import kha.System;
import kha.Scaler;
import kha.Color;
import kha.Image;

/**
 * The game class prepares a backbuffer to which states draw. The
 * backbuffer is defined by the game's rendering resolution (width
 * and height). It also handles states and state changes.
 */
class Renderer {
  // The Phaser Game isntance that owns this renderer.
  public var game:Game;

  /*
   * Our backbuffer our game is rendered to.
   * 
   * we set this to our targetted resolution then scale it to the canvas.
   */
  public var backbuffer:Image;

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
	public var framebuffer:Framebuffer;

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

    // our backbuffer we render to.
    backbuffer = Image.createRenderTarget(Display.primary.width, Display.primary.height);

    init();
  }

  // Prepares the game canvas for rendering.
  public function init() {
    game.scale.on('RESIZE', onResize);

    var baseSize = game.scale.baseSize;

    resize(baseSize.width, baseSize.height);
  }

  // TODO: make sure this onResize and resize stuff is necessary.

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

  public function preRender(_buffer:Framebuffer) {
    framebuffer = _buffer;

    final graphics = backbuffer.g2;

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
    backbuffer.g2.end();

    framebuffer.g2.begin(true);

		Scaler.scale(backbuffer, framebuffer, System.screenRotation);

		framebuffer.g2.end();
  }

  // Takes a Image Game Object, or any object that extends it, and draws it to the current context.
	public function batchImage(child:GameObject, frame:Frame, camera:Camera) {
    var alpha = camera.alpha * child.alpha;

    // Nothing to see, so abort early
    if (alpha == 0) return;

    var x = Math.round(child.x - (child.originX * child.displayWidth));
    var y = Math.round(child.y - (child.originY * child.displayHeight));

    var realX:Float = cast Scaler.transformX(x, y, backbuffer, framebuffer, System.screenRotation);
    var realY:Float = cast Scaler.transformY(x, y, backbuffer, framebuffer, System.screenRotation);

    // grab our backbuffer so we can draw to it.
    final g = backbuffer.g2;


    /*
    if (child.isCropped) {
      var crop = child._crop;

			if (crop.flipX != sprite.flipX || crop.flipY != sprite.flipY) {
				frame.updateCropUVs(crop, sprite.flipX, sprite.flipY);
      }
      
      x = -child.displayOriginX + crop.x;
      y = -child.displayOriginY + crop.y;

      if (child.flipX) {
        if (x >= 0) {
          x = -(x + crop.cw);
        } else if (x < 0) {
          x = (Math.abs(x) - crop.cw);
        }
      }

      if (child.flipY) {
        if (y >= 0) {
          y = -(y + crop.ch);
        } else if (y < 0) {
          y = (Math.abs(y) - crop.ch);
        }
      }
    }*/

    var flipX = 1;
    var flipY = 1;

    if (child.flipX) {
      // TODO: add custom pivot
      realX += (-frame.realWidth + (child.displayOriginX * 2));

      flipX = -1;
    }

    // Auto-invert the flipY if this is coming from a GLTexture
    if (child.flipY) {
      // TODO: add custom pivot
      realY += (-frame.realHeight + (child.displayOriginY * 2));

      flipY = -1;
    }

    _tempMatrix2.applyITRS(child.x, child.y, child.rotation, child.scale * flipX, child.scaleY * flipY);

		// grab our childs center.
		var cameraPos = new Vector2(child.scrollFactorX * camera.scrollX, child.scrollFactorY * camera.scrollY);

		// rotate our graphics.
		g.rotate(child.rotation, realX - cameraPos.x, realY - cameraPos.y);

    // set our alpha.
    g.pushOpacity(alpha);

		g.drawScaledSubImage(
      frame.source.image,
      frame.cutX,
      frame.cutY,
      frame.cutWidth,
      frame.cutHeight,
      realX - cameraPos.x,
      realY - cameraPos.y,
      frame.cutWidth * child.scaleX,
      frame.cutHeight * child.scaleY
    );

		g.rotate(-child.rotation, realX - cameraPos.x, realY - cameraPos.y);
		g.popOpacity();
  }

  public function destroy() {
    backbuffer = null;
    framebuffer = null;
    game = null;
  }
}