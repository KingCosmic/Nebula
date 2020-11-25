package nebula.gameobjects;

import nebula.gameobjects.GameObject;
import nebula.cameras.Camera;
import nebula.scene.Scene;
import kha.math.Vector2;
import nebula.Renderer;

typedef NineSliceConfig = {
	left:Int,
	top:Int,
	right:Int,
	bottom:Int,
	width:Int,
	height:Int
}

class NineSlice extends GameObject {
	// How far from the left should we cut?
	public var left:Int = 0;

	// How far from the top should we cut?
	public var top:Int = 0;

	// How far from the right should we cut?
	public var right:Int = 0;

	// How far from the bottom should we cut?
	public var bottom:Int = 0;

	public function new(_s:Scene, _x:Float, _y:Float, _texture:String, ?_frame:String = '', config:NineSliceConfig) {
		super(_s, 'NineSlice');

		left = config.left;
		top = config.top;
		right = config.right;
		bottom = config.bottom;

		setPosition(_x, _y);
		setTexture(_texture, _frame);

		width = config.width;
		height = config.height;
	}

	/**
	 * Update our render target.
	 */
	public function renderNineSlice(renderer:Renderer, x:Float, y:Float) {
		// grab our graphics to render to and our source image.
		final g = renderer.framebuffer.g2;
		final img = frame.source.image;

		// some variables so I can keep my head when debugging.
		// this is where we're drawing it to.
		var drawX:Float = x;
		var drawY:Float = y;
		var drawWidth:Float = 0;
		var drawHeight:Float = 0;

		// this is where we're cutting from.
		var cutX:Float = 0;
		var cutY:Float = 0;
		var cutWidth:Float = img.width;
		var cutHeight:Float = 0;

		// render the top left corner.
		cutWidth = right;
		cutHeight = top;

		g.drawSubImage(img, drawX, drawY, cutX, cutY, cutWidth, cutHeight);

		// render the top border.
		cutX = left;
		cutWidth = img.width - (left + right);
		cutHeight = top;
		drawX = x + left;
		drawWidth = Std.int(width) - (left + right);
		drawHeight = top;

		g.drawScaledSubImage(img, cutX, cutY, cutWidth, cutHeight, drawX, drawY, drawWidth, drawHeight);

		// render the top right corner.
		drawX = x + Std.int(width) - right;
		cutX = img.width - right;
		cutWidth = right;
		cutHeight = top;

		g.drawSubImage(img, drawX, drawY, cutX, cutY, cutWidth, cutHeight);

		// render the left border.
		cutX = 0;
		cutY = top;
		cutWidth = left;
		cutHeight = img.height - (top + bottom);
		drawX = x;
		drawY = y + top;
		drawWidth = left;
		drawHeight = Std.int(height) - (top + bottom);

		g.drawScaledSubImage(img, cutX, cutY, cutWidth, cutHeight, drawX, drawY, drawWidth, drawHeight);

		// render the center piece.
		cutX = left;
		cutY = top;
		cutWidth = img.width - (left + right);
		cutHeight = img.height - (top + bottom);
		drawX = x + left;
		drawY = y + top;
		drawWidth = Std.int(width) - (left + right);
		drawHeight = Std.int(height) - (top + bottom);

		g.drawScaledSubImage(img, cutX, cutY, cutWidth, cutHeight, drawX, drawY, drawWidth, drawHeight);

		// render the right border.
		cutX = img.width - right;
		cutY = top;
		cutWidth = right;
		cutHeight = Std.int(img.height) - (top + bottom);
		drawX = x + (Std.int(width) - right);
		drawY = y + top;
		drawWidth = right;
		drawHeight = Std.int(height) - (top + bottom);

		g.drawScaledSubImage(img, cutX, cutY, cutWidth, cutHeight, drawX, drawY, drawWidth, drawHeight);

		// render the bottom left corner.
		drawX = x;
		drawY = y + (Std.int(height) - bottom);
		cutX = 0;
		cutY = img.height - bottom;
		cutWidth = left;
		cutHeight = bottom;

		g.drawSubImage(img, drawX, drawY, cutX, cutY, cutWidth, cutHeight);

		// render the bottom border.
		cutX = left;
		cutY = img.width - bottom;
		cutWidth = img.width - (left + right);
		cutHeight = bottom;
		drawX = x + left;
		drawY = y + (Std.int(height) - bottom);
		drawWidth = Std.int(width) - (left + right);
		drawHeight = bottom;

		g.drawScaledSubImage(img, cutX, cutY, cutWidth, cutHeight, drawX, drawY, drawWidth, drawHeight);

		// render the bottom right corner.
		drawX = x + (Std.int(width) - right);
		drawY = y + (Std.int(height) - bottom);
		cutX = img.width - right;
		cutY = img.height - bottom;
		cutWidth = right;
		cutHeight = bottom;

		g.drawSubImage(img, drawX, drawY, cutX, cutY, cutWidth, cutHeight);
	}

	override public function render(renderer:Renderer, camera:Camera) {
		var calcAlpha = camera.alpha * alpha;

		// Nothing to see, so abort early
		if (calcAlpha == 0)
			return;

		var calcX = x - (originX * width);
		var calcY = y - (originY * height);

		// grab our backbuffer so we can draw to it.
		final g = renderer.framebuffer.g2;

		// grab our childs center.
		var cameraPos = new Vector2(scrollFactorX * camera.scrollX, scrollFactorY * camera.scrollY);

		// rotate our graphics.
		g.rotate(rotation, calcX - cameraPos.x, calcY - cameraPos.y);

		// set our alpha.
		g.pushOpacity(alpha);

		renderNineSlice(renderer, calcX - cameraPos.y, calcY - cameraPos.y);

		g.rotate(-rotation, calcX - cameraPos.x, calcY - cameraPos.y);
		g.popOpacity();
	}
}