package core.gameobjects.components;

import core.textures.Frame;

/**
 * Provides methods used for getting and setting the origin of a Game Object.
 * Values are normalized, given in the range 0 to 1.
 * Display values contain the calculated pixel values.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Origin {
	/**
	 * A property indicating that a Game Object has this component.
	 */
	public var _originComponent:Bool = true;

	/**
	 * The horizontal origin of this Game Object.
	 * The origin maps the relationship between the size and position of the Game Object.
	 * The default value is 0.5, meaning all Game Objects are positioned based on their center.
	 * Setting the value to 0 means the position now relates to the left of the Game Object.
	 */
	public var originX:Float = 0.5;

	/**
	 * The vertical origin of this Game Object.
	 * The origin maps the relationship between the size and position of the Game Object.
	 * The default value is 0.5, meaning all Game Objects are positioned based on their center.
	 * Setting the value to 0 means the position now relates to the top of the Game Object.
	 */
	public var originY:Float = 0.5;

	public var _displayOriginX:Float = 0;
	public var _displayOriginY:Float = 0;

	/**
	 * The horizontal display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginX(get, set):Float;

	function get_displayOriginX():Float {
		return this._displayOriginX;
	}
	function set_displayOriginX(value):Float {
		this._displayOriginX = value;
		this.originX = value / this.width;

		return this._displayOriginX;
	}

	/**
	 * The vertical display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginY(get, set):Float;

	function get_displayOriginY():Float {
		return this._displayOriginY;
	}
	function set_displayOriginY(value):Float {
		this._displayOriginY = value;
		this.originY = value / this.height;

		return this._displayOriginY;
	}

	/**
	 * Sets the origin of this Game Object.
	 *
	 * The values are given in the range 0 to 1.
	 */
	public function setOrigin(?x:Float = 0.5, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		this.originX = x;
		this.originY = y;

		return this.updateDisplayOrigin();
	}

	/**
	 * Sets the origin of this Game Object based on the Pivot values in its Frame.
	 */
	// TODO: customPivot
	public function setOriginFromFrame():Dynamic {
		if (this.frame == null || !this.frame.customPivot) {
			return this.setOrigin();
		} else {
			this.originX = this.frame.pivotX;
			this.originY = this.frame.pivotY;
		}
		return this.updateDisplayOrigin();
	}

	/**
	 * Sets the display origin of this Game Object.
	 * The difference between this and setting the origin is that you can use pixel values for setting the display origin.
	 */
	public function setDisplayOrigin(?x:Float = 0, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		this.displayOriginX = x;
		this.displayOriginY = y;

		return this;
	}

	/**
	 * Updates the Display Origin cached values internally stored on this Game Object.
	 * You don't usually call this directly, but it is exposed for edge-cases where you may.
	 */
	public function updateDisplayOrigin():Dynamic {
		this._displayOriginX = this.originX * this.width;
		this._displayOriginY = this.originY * this.height;

		return this;
	}
}