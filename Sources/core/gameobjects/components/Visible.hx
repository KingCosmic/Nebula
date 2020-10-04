package core.gameobjects.components;

/**
 * Provides methods used for setting the visibility of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Visible {
	// bitmask flag for GameObject.renderMask
	// static var _FLAG:Int = 1; //0001

	/**
	 * Private internal value. Holds the visible value.
	 */
	private var _visible:Bool = true;

	/**
	 * The visible state of the Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public var visible(get, set):Bool;

	function get_visible():Bool {
		return this._visible;
	}

	function set_visible(value:Bool):Bool {
		if (value) {
			this._visible = true;
			// this.renderFlags |= _FLAG;
		} else {
			this._visible = false;
			// this.renderFlags &= ~_FLAG;
		}
		return get_visible();
	}

	/**
	 * Sets the visibility of this Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public function setVisible(value:Bool):GameObject {
		this.visible = value;
		return this;
	}
}