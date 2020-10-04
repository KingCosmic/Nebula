package core.gameobjects.components;

import core.textures.Frame;
import core.textures.Texture;

/**
 * Provides methods used for getting and setting the texture of a Game Object.
 */
@mixin interface TextureMixin {
	/**
	 * The Texture this Game Object is using to render with.
	 */
	public var texture:Texture; // To-Do

	/**
	 * The Texture Frame this Game Object is using to render with.
	 */
	public var frame:Frame;

	/**
	 * Internal flag. Not to be set by this Game Object.
	 */
	public var isCropped:Bool;

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
	 *
	 * Calling `setFrame` will modify the `width` and `height` properties of your Game Object.
	 * It will also change the `origin` if the Frame has a custom pivot point, as exported from packages like Texture Packer.
	 */
	public function setFrame(key:String, ?updateSize:Bool = true, ?updateOrigin:Bool = true):GameObject {
		this.frame = texture.get(key);
		if (this._sizeComponent != null && updateSize) {
			this.setSizeToFrame();
		}
		if (this._originComponent != null && updateOrigin)
			/*Reflect.hasField(this,"_originComponent ")*/ {
			if (this.frame.customPivot) {
				this.setOrigin(this.frame.pivotX, this.frame.pivotY);
			} else {
				this.updateDisplayOrigin();
			}
		}
		return this;
	}
}