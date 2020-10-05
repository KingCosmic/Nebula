package core.gameobjects.components;

import core.geom.rectangle.Rectangle;
import core.textures.Frame;
import core.textures.Texture;
import core.gameobjects.GameObject;

/**
 * Provides methods used for getting and setting the texture of a Game Object.
 */
@mixin interface TextureCrop {
	// bitmask flag for GameObject.renderMask
	// static var _FLAG:Int = 8; // 1000

	/**
	 * The Texture this Game Object is using to render with.
	 */
	// is CanvasTexture To-Do
	public var texture:Texture = null;

	/**
	 * The Texture Frame this Game Object is using to render with.
	 */
	// is Phaser.Textures.Frame To-Do
	public var frame:Frame = null;

	/**
	 * A boolean flag indicating if this Game Object is being cropped or not.
	 * You can toggle this at any time after `setCrop` has been called, to turn cropping on or off.
	 * Equally, calling `setCrop` with no arguments will reset the crop and disable it.
	 */
  public var isCropped:Bool = false;
  
	/**
	 * The internal crop data object, as used by `setCrop` and passed to the `Frame.setCropUVs` method.
	 */ // To-Do Why Isn't this used by a Component?
	public var _crop:{
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
	};

	/**
	 * Applies a crop to a texture based Game Object, such as a Sprite or Image.
	 *
	 * The crop is a rectangle that limits the area of the texture frame that is visible during rendering.
	 *
	 * Cropping a Game Object does not change its size, dimensions, physics body or hit area, it just
	 * changes what is shown when rendered.
	 *
	 * The crop coordinates are relative to the texture frame, not the Game Object, meaning 0 x 0 is the top-left.
	 *
	 * Therefore, if you had a Game Object that had an 800x600 sized texture, and you wanted to show only the left
	 * half of it, you could call `setCrop(0, 0, 400, 600)`.
	 *
	 * It is also scaled to match the Game Object scale automatically. Therefore a crop rect of 100x50 would crop
	 * an area of 200x100 when applied to a Game Object that had a scale factor of 2.
	 *
	 * You can either pass in numeric values directly, or you can provide a single Rectangle object as the first argument.
	 *
	 * Call this method with no arguments at all to reset the crop, or toggle the property `isCropped` to `false`.
	 *
	 * You should do this if the crop rectangle becomes the same size as the frame itself, as it will allow
	 * the renderer to skip several internal calculations.
	 */
	// TODO: Rectangle Version
	public function setCrop(?x:Float, ?y:Float, ?width:Float, ?height:Float):GameObject {
		if (x == null) {
			this.isCropped = false;
		} else if (this.frame != null) {
			this.frame.setCropUVs(this._crop, x, y, width, height, this.flipX, this.flipY); // this._crop
			this.isCropped = true;
		}
		return this;
	}

	/**
	 * Sets the texture and frame this Game Object will use to render with.
	 *
	 * Textures are referenced by their string-based keys, as stored in the Texture Manager.
	 */
	public function setTexture(key:String, frame:String):GameObject {
		texture = scene.sys.textures.get(key);
		return setFrame(frame);
	}

	/**
	 * Sets the frame this Game Object will use to render with.
	 *
	 * The Frame has to belong to the current Texture being used.
	 *
	 * It can be either a string or an index.
	 * Calling `setFrame` will modify the `width` and `height` properties of your Game Object.
	 * It will also change the `origin` if the Frame has a custom pivot point, as exported from packages like Texture Packer.
	 */
	// TODO: set up frame functions/variables
	public function setFrame(key:String, ?updateSize:Bool = true, ?updateOrigin:Bool = true):GameObject {
		this.frame = texture.get(key);

		if (this._sizeComponent != null && updateSize) {
			this.setSizeToFrame();
		}

		if (this._originComponent != null && updateOrigin) /*Reflect.hasField(this,"_originComponent ")*/ {
			if (this.frame.customPivot) {
				this.setOrigin(this.frame.pivotX, this.frame.pivotY);
			} else {
				this.updateDisplayOrigin();
			}
		}
		return this;
	}

	/**
	 * Internal method that returns a blank, well-formed crop object for use by a Game Object.
	 */
	private function resetCropObject():{
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
	} {
		return {
			u0: 0,
			v0: 0,
			u1: 0,
			v1: 0,
			x: 0,
			y: 0,
			cx: 0,
			cy: 0,
			cw: 0,
			ch: 0,
			width: 0,
			height: 0,
			flipX: false,
			flipY: false
		};
	}
}