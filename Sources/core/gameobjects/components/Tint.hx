package core.gameobjects.components;

/**
 * Provides methods used for setting the tint of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Tint {

	function GetColor(value):Float {
		return (value >> 16) + (value & 0xff00) + ((value & 0xff) << 16);
	}

	/**
	 * Private internal value. Holds the top-left tint value.
	 */
	public var _tintTL:Float = 16777215;

	/**
	 * Private internal value. Holds the top-right tint value.
	 */
	public var _tintTR:Float = 16777215;

	/**
	 * Private internal value. Holds the bottom-left tint value.
	 */
	public var _tintBL:Float = 16777215;

	/**
	 * Private internal value. Holds the bottom-right tint value.
	 */
	public var _tintBR:Float = 16777215;

	/**
	 * Private internal value. Holds if the Game Object is tinted or not.
	 */
	public var _isTinted:Bool = false;

	/**
	 * Fill or additive?
	 */
	public var tintFill:Bool = false;

	/**
	 * Clears all tint values associated with this Game Object.
	 *
	 * Immediately sets the color values back to 0xffffff and the tint type to 'additive',
	 * which results in no visible change to the texture.
	 */
	public function clearTint():GameObject {
		this.setTint(0xffffff);
		this._isTinted = false;
		return this;
	}

	/**
	 * Sets an additive tint on this Game Object.
	 *
	 * The tint works by taking the pixel color values from the Game Objects texture, and then
	 * multiplying it by the color value of the tint. You can provide either one color value,
	 * in which case the whole Game Object will be tinted in that color. Or you can provide a color
	 * per corner. The colors are blended together across the extent of the Game Object.
	 *
	 * To modify the tint color once set, either call this method again with new values or use the
	 * `tint` property to set all colors at once. Or, use the properties `tintTopLeft`, `tintTopRight,
	 * `tintBottomLeft` and `tintBottomRight` to set the corner color values independently.
	 *
	 * To remove a tint call `clearTint`.
	 *
	 * To swap this from being an additive tint to a fill based tint set the property `tintFill` to `true`.
	 */
	public function setTint(?topLeft:Int = 0xffffff, ?topRight:Int = null, ?bottomLeft:Int = null, ?bottomRight:Int = null):GameObject {
		if (topRight == null) {
			topRight = topLeft;
			bottomLeft = topLeft;
			bottomRight = topLeft;
		}
		this._tintTL = GetColor(topLeft);
		this._tintTR = GetColor(topRight);
		this._tintBL = GetColor(bottomLeft);
		this._tintBR = GetColor(bottomRight);

		this._isTinted = true;

		this.tintFill = false;

		return this;
	}

	/**
	 * Sets a fill-based tint on this Game Object.
	 *
	 * Unlike an additive tint, a fill-tint literally replaces the pixel colors from the texture
	 * with those in the tint. You can use this for effects such as making a player flash 'white'
	 * if hit by something. You can provide either one color value, in which case the whole
	 * Game Object will be rendered in that color. Or you can provide a color per corner. The colors
	 * are blended together across the extent of the Game Object.
	 *
	 * To modify the tint color once set, either call this method again with new values or use the
	 * `tint` property to set all colors at once. Or, use the properties `tintTopLeft`, `tintTopRight,
	 * `tintBottomLeft` and `tintBottomRight` to set the corner color values independently.
	 *
	 * To remove a tint call `clearTint`.
	 *
	 * To swap this from being a fill-tint to an additive tint set the property `tintFill` to `false`.
	 */
	public function setTintFill(?topLeft:Int = 0xffffff, ?topRight:Int, ?bottomLeft:Int, ?bottomRight:Int):GameObject {
		this.setTint(topLeft, topRight, bottomLeft, bottomRight);

		this.tintFill = true;

		return this;
	}

	/**
	 * The tint value being applied to the top-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var tintTopLeft(get, set):Int;

	function get_tintTopLeft():Int {
		return Std.int(this._tintTL);
	}

	function set_tintTopLeft(value:Int):Int {
		this._tintTL = GetColor(value);
		this._isTinted = true;
		return Std.int(this._tintTL);
	}

	/**
	 * The tint value being applied to the top-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var tintTopRight(get, set):Int;

	function get_tintTopRight():Int {
		return Std.int(this._tintTR);
	}

	function set_tintTopRight(value:Int):Int {
		this._tintTR = GetColor(value);
		this._isTinted = true;
		return Std.int(this._tintTR);
	}

	/**
	 * The tint value being applied to the bottom-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var tintBottomLeft(get, set):Int;

	function get_tintBottomLeft():Int {
		return Std.int(this._tintBL);
	}

	function set_tintBottomLeft(value:Int):Int {
		this._tintBL = GetColor(value);
		this._isTinted = true;
		return Std.int(this._tintBL);
	}

	/**
	 * The tint value being applied to the bottom-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var tintBottomRight(get, set):Int;

	function get_tintBottomRight():Int {
		return Std.int(this._tintBR);
	}

	function set_tintBottomRight(value:Int):Int {
		this._tintBR = GetColor(value);
		this._isTinted = true;
		return Std.int(this._tintBR);
	}

	/**
	 * The tint value being applied to the whole of the Game Object.
	 * This property is a setter-only. Use the properties `tintTopLeft` etc to read the current tint value.
	 */
	public var tint(null, set):Int;

	function set_tint(value:Int):Int {
		this.setTint(value, value, value, value);
		return get_tintTopLeft();
	}

	/**
	 * Does this Game Object have a tint applied to it or not?
	 */
	public var isTinted(get, null):Bool;

	function get_isTinted():Bool {
		return this._isTinted;
	}
}