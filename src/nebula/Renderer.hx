package nebula;

import nebula.structs.TransformMatrix;
import nebula.gameobjects.GameObject;
import nebula.scene.DisplayList;
import nebula.cameras.Camera;
import nebula.assets.Frame;
import nebula.structs.Size;
import nebula.scene.Scene;

import kha.math.Vector2;
import kha.Framebuffer;
import kha.Display;
import kha.System;
import kha.Scaler;
import kha.Color;
import kha.Image;

typedef RendererConfig = {
  backBuffer:Vector2,
  backgroundColor:Color
}

// TODO: swap this to use transformation matrix's
// instead of simple maths and see if that helps
// with the scaling issues.

/**
 * The game class prepares a backbuffer to which states draw. The
 * backbuffer is defined by the game's rendering resolution (width
 * and height). It also handles states and state changes.
 */
class Renderer {
	// The Nebula Game isntance that owns this renderer.
	public var game:Game;

	/*
	 * Our backbuffer our game is rendered to.
	 * 
	 * we set this to our targetted resolution then scale it to the canvas.
	 */
	public var backbuffer:Image;

	// The total number of Game Objects which were rendered in a frame.
	public var drawCount:Int = 0;

	// The local configuration settings of the Renderer.
	public var config = {
		clearBeforeRender: true,
		backgroundColor: Color.fromBytes(0, 0, 0),
		antialias: false,
		roundPixels: false
	}

	// current Graphics (updated every time notifyFrames runs)
	public var framebuffer:Framebuffer;

	// Should the Canvas use Image Smoothing or not when drawing Sprites?
	public var antialias:Bool = true;

	public function new(_game:Game, _config:RendererConfig) {
		game = _game;

    // TODO: swap rendering to the backbuffer.
    // maybe? idk

		// our backbuffer we render to.
		backbuffer = Image.createRenderTarget(Display.primary.width, Display.primary.height);

		init();
	}

	// Prepares the game canvas for rendering.
	public function init() {}

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

		final graphics = framebuffer.g2;

		// Start drawing, and clear the framebuffer
		graphics.begin(config.clearBeforeRender, config.backgroundColor);

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
		// backbuffer.g2.end();

		// framebuffer.g2.begin(true);

		// Scaler.scale(backbuffer, framebuffer, System.screenRotation);

		framebuffer.g2.end();
	}

	// Takes a Image Game Object, or any object that extends it, and draws it to the current context.
	public function batchImage(child:GameObject, frame:Frame, camera:Camera) {
		var alpha = camera.alpha * child.alpha;

		// Nothing to see, so abort early
		if (alpha == 0)
			return;

		var x = child.x - (child.originX * child.displayWidth);
		var y = child.y - (child.originY * child.displayHeight);

		// grab our backbuffer so we can draw to it.
		final g = framebuffer.g2;

		var flipX = 1;
		var flipY = 1;

		if (child.flipX) {
			// TODO: add custom pivot
			x += (-frame.realWidth + (child.displayOriginX * 2));

			flipX = -1;
		}

		if (child.flipY) {
			// TODO: add custom pivot
			y += (-frame.realHeight + (child.displayOriginY * 2));

			flipY = -1;
		}

		// grab our childs center.
		var cameraPos = new Vector2(child.scrollFactorX * camera.scrollX, child.scrollFactorY * camera.scrollY);

		// rotate our graphics.
		g.rotate(child.rotation, x - cameraPos.x, y - cameraPos.y);

		// set our alpha.
		g.pushOpacity(alpha);

		g.drawScaledSubImage(frame.source.image, frame.cutX, frame.cutY, frame.cutWidth, frame.cutHeight, x - cameraPos.x, y - cameraPos.y,
			frame.cutWidth * child.scaleX, frame.cutHeight * child.scaleY);

		g.rotate(-child.rotation, x - cameraPos.x, y - cameraPos.y);
		g.popOpacity();
	}

	public function destroy() {
		backbuffer = null;
		framebuffer = null;
		game = null;
	}
}