package core.gameobjects.components;

import core.math.Clamp;

/**
 * Provides methods used for setting the alpha properties of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Alpha {
	/**
	 * Private internal value. Holds the global alpha value.
	 */
	public var _alpha:Float = 1;

	/**
	 * Private internal value. Holds the top-left alpha value.
	 */
	public var _alphaTL:Float = 1;

	/**
	 * Private internal value. Holds the top-right alpha value.
	 */
	public var _alphaTR:Float = 1;

	/**
	 * Private internal value. Holds the bottom-left alpha value.
	 */
	public var _alphaBL:Float = 1;

	/**
	 * Private internal value. Holds the bottom-right alpha value.
	 */
	public var _alphaBR:Float = 1;

	/**
	 * Clears all alpha values associated with this Game Object.
	 *
	 * Immediately sets the alpha levels back to 1 (fully opaque).
	 */
	public function clearAlpha():Dynamic {
		return this.setAlpha(1);
	}

	/**
	 * Set the Alpha level of this Game Object. The alpha controls the opacity of the Game Object as it renders.
	 * Alpha values are provided as a float between 0, fully transparent, and 1, fully opaque.
	 *
	 * If your game is running under WebGL you can optionally specify four different alpha values, each of which
	 * correspond to the four corners of the Game Object. Under Canvas only the `topLeft` value given is used.
	 */
	public function setAlpha(topLeft:Float, ?topRight:Float, ?bottomLeft:Float, ?bottomRight:Float):Dynamic {
		//  Treat as if there is only one alpha value for the whole Game Object
		if (topRight == null) {
			this.alpha = topLeft;
		} else {
			this._alphaTL = Clamp.clamp(topLeft, 0, 1);
			this._alphaTR = Clamp.clamp(topRight, 0, 1);
			this._alphaBL = Clamp.clamp(bottomLeft, 0, 1);
			this._alphaBR = Clamp.clamp(bottomRight, 0, 1);
		}
		return this;
	}

	/**
	 * The alpha value of the Game Object.
	 *
	 * This is a global value, impacting the entire Game Object, not just a region of it.
	 */
	public var alpha(get, set):Float;

	function get_alpha():Float {
		return _alpha;
	}

	function set_alpha(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alpha = v;
		this._alphaTL = v;
		this._alphaTR = v;
		this._alphaBL = v;
		this._alphaBR = v;

		if (v == 0) {
			//   this.renderFlags &= ~_FLAG;
		} else {
			//  this.renderFlags |= _FLAG;
    }

		return _alpha;
	}

	/**
	 * The alpha value starting from the top-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaTopLeft(get, set):Float;

	function get_alphaTopLeft():Float {
		return this._alphaTL;
	}

	function set_alphaTopLeft(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaTL = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
    }

		return v;
	}

	/**
	 * The alpha value starting from the top-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaTopRight(get, set):Float;

	function get_alphaTopRight():Float {
		return this._alphaTR;
	}

	function set_alphaTopRight(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaTR = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
    }

		return v;
	}

	/**
	 * The alpha value starting from the bottom-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaBottomLeft(get, set):Float;

	function get_alphaBottomLeft():Float {
		return this._alphaBL;
	}

	function set_alphaBottomLeft(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaBL = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}
		return get_alphaBottomLeft();
	}

	/**
	 * The alpha value starting from the bottom-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaBottomRight(get, set):Float;

	function get_alphaBottomRight():Float {
		return this._alphaBR;
	}

	function set_alphaBottomRight(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaBR = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}
		return get_alphaBottomRight();
	}
}