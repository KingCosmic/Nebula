package core.gameobjects.components;

/**
 * Provides methods used for visually flipping a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Flip {
	/**
	 * The horizontally flipped state of the Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public var flipX:Bool = false;

	/**
	 * The vertically flipped state of the Game Object.
	 *
	 * A Game Object that is flipped vertically will render inversed on the vertical axis (i.e. upside down)
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public var flipY:Bool = false;

	/**
	 * Toggles the horizontal flipped state of this Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function toggleFlipX():GameObject {
		this.flipX = !this.flipX;

		return this;
	}

	/**
	 * Toggles the vertical flipped state of this Game Object.
	 */
	public function toggleFlipY():GameObject {
		this.flipY = !this.flipY;

		return this;
	}

	/**
	 * Sets the horizontal flipped state of this Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function setFlipX(value:Bool):GameObject {
		this.flipX = value;

		return this;
	}

	/**
	 * Sets the vertical flipped state of this Game Object.
	 */
	public function setFlipY(value:Bool):GameObject {
		this.flipY = value;

		return this;
	}

	/**
	 * Sets the horizontal and vertical flipped state of this Game Object.
	 *
	 * A Game Object that is flipped will render inversed on the flipped axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function setFlip(x:Bool, y:Bool):GameObject {
		this.flipX = x;
		this.flipY = y;

		return this;
	}

	/**
	 * Resets the horizontal and vertical flipped state of this Game Object back to their default un-flipped state.
	 */
	public function resetFlip():GameObject {
		this.flipX = false;
		this.flipY = false;

		return this;
	}
}