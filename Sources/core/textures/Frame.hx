package core.textures;

/**
 * A Frame is a section of a Texture.
 */
class Frame {
  // The Texture this Frame is a part of.
  public var texture:Texture;

  /**
   * The name of this Frame.
   * The name is unique within the Texture.
   */
  public var name:String;

  // The TextureSource this Frame is a part of.
  public var source:TextureSource;

  // The index of the TextureSource in the Texture sources array.
  public var sourceIndex:Int;

  // X position within the source image to cut from.
  public var cutX:Int;

  // Y position within the source image to cut from.
  public var cutY:Int;

  // The width of the area in the source image to cut.
  public var cutWidth:Int;

  // The height of the area in the source image to cut.
  public var cutHeight:Int;

  // The X rendering offset of this Frame, taking trim into account.
  public var x:Float = 0;

  // The Y rendering offset of this Frame, taking trim into account.
  public var y:Float = 0;

  // The rendering width of this Frame, taking trim into account.
  public var width:Float;

  // The rendering height of this Frame, taking trim into account.
  public var height:Float;

  /**
   * Half the width, floored.
   * Precalculated for the renderer.
   */
  public var halfWidth:Float;

  /**
   * Half the height, floored.
   * Precalculated for the renderer.
   */
  public var halfHeight:Float;

  // The x center of this frame, floored.
  public var centerX:Int;

  // The y center of this frame, floored.
  public var centerY:Int;

  // The horizontal pivot point of this Frame.
  public var pivotX:Float = 0;

  // The vertical pivot point of this Frame.
  public var pivotY:Float = 0;

  // Does this Frame have a custom pivot point?
  public var customPivot:Bool = false;

  /**
   * Over-rides the Renderer setting.
   * -1 = use Renderer Setting
   * 0 = No rounding
   * 1 = Round
   */
  public var autoRound = -1;

  // Any Frame specific custom data can be stored here.
  public var customData = {};

  // The un-modified source frame, trim and UV data.
	public var data = {
		cut:{
			x:0.0, y:0.0, w:0.0, h:0.0, r:0.0, b:0.0
		}, trim:false, sourceSize:{
			w:0.0, h:0.0
		}, spriteSourceSize:{
			x:0.0, y:0.0, w:0.0, h:0.0, r:0.0, b:0.0
		}, radius:0.0, drawImage:{
			x:0.0, y:0.0, width:0.0, height:0.0
    }
  };

  public function new(_texture:Texture, _name:String, _sourceIndex:Int, x:Int, y:Int, _width:Int, _height:Int)  {
    texture = _texture;
    name = _name;
    sourceIndex = _sourceIndex;
		source = texture.source[sourceIndex];

    setSize(_width, _height, x, y);
  }

  /**
   * Sets the width, height, x and y of this Frame.
   *
   * This is called automatically by the constructor
   * and should rarely be changed on-the-fly.
   */
  public function setSize(_width:Int, _height:Int, ?x:Int = 0, ?y:Int = 0) {
    cutX = x;
    cutY = y;
    cutWidth = _width;
    cutHeight = _height;

    width = _width;
    height = _height;

    halfWidth = Math.floor(width * 0.5);
    halfHeight = Math.floor(height * 0.5);

    centerX = Math.floor(width / 2);
    centerY = Math.floor(height / 2);

    data.cut.x = x;
    data.cut.y = y;
    data.cut.w = width;
    data.cut.h = height;
    data.cut.r = x + width;
    data.cut.b = y + height;

    data.sourceSize.w = width;
    data.sourceSize.h = height;

    data.spriteSourceSize.w = width;
    data.spriteSourceSize.h = height;

    data.radius = 0.5 * Math.sqrt(width * width + height * height);

    data.drawImage.x = x;
    data.drawImage.y = y;
    data.drawImage.width = width;
    data.drawImage.height = height;

    return updateUVs();
  }

  /**
   * If the frame was trimmed when added to the Texture Atlas, this records the trim and source data.
   */
  public function setTrim(actualWidth:Int, actualHeight:Int, destX:Int, destY:Int, destWidth:Int, destHeight:Int) {
    data.trim = true;

    data.sourceSize.w = actualWidth;
    data.sourceSize.h = actualHeight;

    data.spriteSourceSize.x = destX;
    data.spriteSourceSize.y = destY;
    data.spriteSourceSize.w = destWidth;
    data.spriteSourceSize.h = destHeight;
    data.spriteSourceSize.r = destX + destWidth;
    data.spriteSourceSize.b = destY + destHeight;
    
    x = destX;
    y = destY;

    width = destWidth;
    height = destHeight;

    halfWidth = destWidth * 0.5;
    halfHeight = destHeight * 0.5;

    centerX = Math.floor(destWidth / 2);
    centerY = Math.floor(destHeight / 2);

    return updateUVs();
  }

  /**
   * Takes a crop data object and, based on the rectangular region given, calculates the
   * required UV coordinates in order to crop this Frame for WebGL and Canvas rendering.
   *
   * This is called directly by the Game Object Texture Components `setCrop` method.
   * Please use that method to crop a Game Object.
   */
	public function setCropUVs(crop:{
		u0:Float,
		v0:Float,
		u1:Float,
		v1:Float,
		x:Float,
		y:Float,
		cx:Float,
		cy:Float,
		cw:Float,
		ch:Float,
		width:Float,
		height:Float,
		flipX:Bool,
		flipY:Bool
	}, x:Float, y:Float, width:Float, height:Float, flipX:Bool, flipY:Bool) {
		var cx = cutX;
		var cy = cutY;
		var cw = cutWidth;
		var ch = cutHeight;
		var rw = realWidth;
		var rh = realHeight;

    x = Math.max(0, Math.min(rw, x));
		y = Math.max(0, Math.min(rh, y));

    width = Math.max(0, Math.min(rw - x, width));
		height = Math.max(0, Math.min(rh - y, height));

		var ox = cx + x;
		var oy = cy + y;
		var ow = width;
		var oh = height;

		var data = this.data;

		if (data.trim) {
			var ss = data.spriteSourceSize;

			//  Need to check for intersection between the cut area and the crop area
			//  If there is none, we set UV to be empty, otherwise set it to be the intersection area

			width = Math.max(0, Math.min(cw - x, width));
			height = Math.max(0, Math.min(ch - y, height));

			var cropRight = x + width;
			var cropBottom = y + height;

			var intersects = !(ss.r < x || ss.b < y || ss.x > cropRight || ss.y > cropBottom);

			if (intersects) {
				var ix = Math.max(ss.x, x);
				var iy = Math.max(ss.y, y);
				var iw = Math.min(ss.r, cropRight) - ix;
				var ih = Math.min(ss.b, cropBottom) - iy;

				ow = iw;
				oh = ih;

				if (flipX) {
					ox = cx + (cw - (ix - ss.x) - iw);
				} else {
					ox = cx + (ix - ss.x);
				}

				if (flipY) {
					oy = cy + (ch - (iy - ss.y) - ih);
				} else {
					oy = cy + (iy - ss.y);
				}

				x = ix;
				y = iy;

				width = iw;
				height = ih;
			} else {
				ox = 0;
				oy = 0;
				ow = 0;
				oh = 0;
			}
		} else {
			if (flipX) {
				ox = cx + (cw - x - width);
			}

			if (flipY) {
				oy = cy + (ch - y - height);
			}
		}

		var tw = this.source.width;
		var th = this.source.height;

		//  Map the given coordinates into UV space, clamping to the 0-1 range.

		crop.u0 = Math.max(0, ox / tw);
		crop.v0 = Math.max(0, oy / th);
		crop.u1 = Math.min(1, (ox + ow) / tw);
		crop.v1 = Math.min(1, (oy + oh) / th);

		crop.x = x;
		crop.y = y;

		crop.cx = ox;
		crop.cy = oy;
		crop.cw = ow;
		crop.ch = oh;

		crop.width = width;
		crop.height = height;

		crop.flipX = flipX;
    crop.flipY = flipY;

		return crop;
  }

  /**
   * Takes a crop data object and recalculates the UVs based on the dimensions inside the crop object.
   * Called automatically by `setFrame`.
   */
	public function updateCropUvs(crop:{
		u0:Float,
		v0:Float,
		u1:Float,
		v1:Float,
		x:Float,
		y:Float,
		cx:Float,
		cy:Float,
		cw:Float,
		ch:Float,
		width:Float,
		height:Float,
		flipX:Bool,
		flipY:Bool
	}, flipX:Bool, flipY:Bool) {
    return setCropUVs(crop, crop.x, crop.y, crop.width, crop.height, flipX, flipY);
  }

  /**
   * Directly sets the canvas and WebGL UV data for this frame.
   *
   * Use this if you need to override the values that are generated automatically
   * when the Frame is created.
   */
  public function setUVs(width:Int, height:Int, u0:Int, v0:Int, u1:Int, v1:Int) {

    data.drawImage.width = width;
    data.drawImage.height = height;

  }

  public function updateUVs() {

  }

  /**
   * Destroys this Frame by nulling its reference to the parent Texture and and data objects.
   */
  public function destroy() {
    source = null;
    texture = null;
    customData = null;
    data = null;
  }

  public var realWidth(get, null):Float;

  function get_realWidth() {
    return data.sourceSize.w;
  }

  public var realHeight(get, null):Float;

  function get_realHeight() {
    return data.sourceSize.h;
  }

  public var radius(get, null):Float;

  function get_radius() {
    return data.radius;
  }

  public var trimmed(get, null):Bool;

  function get_trimmed() {
    return data.trim;
  }

  public var canvasData(get, null):{};

  function get_canvasData() {
    return data.drawImage;
  }
}
