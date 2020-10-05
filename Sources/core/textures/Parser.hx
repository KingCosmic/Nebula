package core.textures;

import core.textures.Texture;

class Parser {
	// Adds an Image Element to a Texture.
	static public function image(texture:Texture, sourceIndex:Int) {
		var source = texture.source[sourceIndex];
		texture.add('__BASE', sourceIndex, 0, 0, source.width, source.height);
		return texture;
	}

	// Parses a Sprite Sheet and adds the Frames to the Texture.
	// In Phaser terminology a Sprite Sheet is a texture containing different frames, but each frame is the exact
	// same size and cannot be trimmed or rotated.
	static public function spriteSheet(texture:Texture, sourceIndex:Int, x:Int, y:Int, width:Int, height:Int, ?config:{frameWidth:Int,frameHeight:Int,startFrame:Int,endFrame:Int,margin:Int,spacing:Int}) {
		if (config == null) {
			config = {
				frameWidth: 0,
				frameHeight: 0,
				startFrame: 0,
				endFrame: -1,
				margin: 0,
				spacing: 0
			}
		}
		var frameWidth = config.frameWidth != null ? config.frameWidth : null;
		var frameHeight = config.frameHeight != null ? config.frameHeight : frameWidth;

		// If missing we can't proceed
		if (frameWidth == null) {
			throw 'TextureManager.SpriteSheet: Invalid frameWidth given.';
		}

		// Add in a __BASE entry (for the entire atlas)
		var source = texture.source[sourceIndex];

		texture.add('__BASE', sourceIndex, 0, 0, source.width, source.height);

		var startFrame:Int = config.startFrame != null ? config.startFrame : 0;
		var endFrame = config.endFrame != null ? config.endFrame : -1;
		var margin = config.margin != null ? config.margin : 0;
		var spacing = config.spacing != null ? config.spacing : 0;

		var row = Math.floor((width - margin + spacing) / (frameWidth + spacing));
		var column = Math.floor((height - margin + spacing) / (frameHeight + spacing));
    var total = row * column;

		if (total == 0) {
			trace('SpriteSheet frame dimensions will result in zero frames for texture: ' + texture.key);
		}

		if (startFrame > total || startFrame < -total) {
			startFrame = 0;
		}

		if (startFrame < 0) {
			// Allow negative skipframes.
			startFrame = total + startFrame;
		}

		if (endFrame != -1) {
			total = startFrame + (endFrame + 1);
		}

		var fx = margin;
		var fy = margin;
		var ax = 0;
		var ay = 0;

		for (i in 0...total) {
			ax = 0;
			ay = 0;

			var w = fx + frameWidth;
			var h = fy + frameHeight;

			if (w > width) {
				ax = w - width;
			}

			if (h > height) {
				ay = h - height;
			}

			texture.add(Std.string(i), sourceIndex, x + fx, y + fy, frameWidth - ax, frameHeight - ay);

			fx += frameWidth + spacing;

			if (fx + frameWidth > width) {
				fx = margin;
				fy += frameHeight + spacing;
			}
		}

		return texture;
	}
}
