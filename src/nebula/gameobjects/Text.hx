package nebula.gameobjects;

import nebula.gameobjects.GameObject;
import nebula.cameras.Camera;
import nebula.scene.Scene;
import kha.math.Vector2;
import nebula.Renderer;
import kha.Color;
import kha.Font;

typedef TextStyle = {
	?fontName:String,
	?fontSize:Int,
	?backgroundColor:Color,
	?color:Color
};

class Text extends GameObject {
	public var text:String = '';

	public var font:Null<Font> = null;

	public var fontSize:Int = 16;

  public var color:Color = Color.White;

	public function new(_s:Scene, ?_x:Float = 0, ?_y:Float = 0, ?text:String = '', ?style:TextStyle) {
		super(_s, 'Text');

		setPosition(_x, _y);
		setOrigin(0, 0);

    style = (style != null) ? style : { fontName: null, fontSize: 16, color: Color.White };

		font = scene.assets.getFont(style.fontName);
		fontSize = style.fontSize;
    color = style.color;

		setText(text);
	}

	public function calculateSize() {
		width = font.width(fontSize, text);
		height = fontSize;
	}

	public function setText(value:String) {
		text = value;

		calculateSize();
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

		// set our font.
		g.font = font;
		g.fontSize = fontSize;
    g.color = color;

		// draw our text
		g.drawString(text, calcX - cameraPos.x, calcY - cameraPos.y);

		// remove our transformations.
		g.rotate(-rotation, calcX - cameraPos.x, calcY - cameraPos.y);
		g.popOpacity();
	}
}