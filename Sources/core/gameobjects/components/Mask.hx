package core.gameobjects.components;

import core.scene.Scene;

/**
 * Provides methods used for getting and setting the mask of a Game Object.
 */
@mixin interface Mask {
	// To-Do//
	public var mask:{}; // Bitmap mask or Geometry mask, WIP

	/**
	 * Sets the mask that this Game Object will use to render with.
	 *
	 * The mask must have been previously created and can be either a GeometryMask or a BitmapMask.
	 * Note: Bitmap Masks only work on WebGL. Geometry Masks work on both WebGL and Canvas.
	 *
	 * If a mask is already set on this Game Object it will be immediately replaced.
	 *
	 * Masks are positioned in global space and are not relative to the Game Object to which they
	 * are applied. The reason for this is that multiple Game Objects can all share the same mask.
	 *
	 * Masks have no impact on physics or input detection. They are purely a rendering component
	 * that allows you to limit what is visible during the render pass.
	 */
	public function setMask(mask:{}):GameObject {
		this.mask = mask;
		return this;
	}

	/**
	 * Clears the mask that this Game Object was using.
	 */
	public function clearMask(destoryMask:Bool = false):GameObject {
		if (destoryMask && this.mask != null) {
			this.mask = null;
		}
		return this;
	}

	/**
	 * Creates and returns a Bitmap Mask. This mask can be used by any Game Object,
	 * including this one.
	 *
	 * Note: Bitmap Masks only work on WebGL. Geometry Masks work on both WebGL and Canvas.
	 *
	 * To create the mask you need to pass in a reference to a renderable Game Object.
	 * A renderable Game Object is one that uses a texture to render with, such as an
	 * Image, Sprite, Render Texture or BitmapText.
	 *
	 * If you do not provide a renderable object, and this Game Object has a texture,
	 * it will use itself as the object. This means you can call this method to create
	 * a Bitmap Mask from any renderable Game Object.
	 */
	public function createBitmapMask(renderable:GameObject = null):Void { // To-Do, Phaser.GameObjects.GameObject:Phaser.Display.Masks.BitmapMask
	}

	/**
	 * Creates and returns a Geometry Mask. This mask can be used by any Game Object,
	 * including this one.
	 *
	 * To create the mask you need to pass in a reference to a Graphics Game Object.
	 *
	 * If you do not provide a graphics object, and this Game Object is an instance
	 * of a Graphics object, then it will use itself to create the mask.
	 *
	 * This means you can call this method to create a Geometry Mask from any Graphics Game Object.
	 */
	public function createGeometryMask(graphics:{}):Void { // To-Do, Phaser.GameObjects.Graphics:Phaser.Display.Masks.GeometryMask
	}
}