package core.gameobjects.components;

import core.textures.Frame;

/**
 * Provides methods used for getting and setting the size of a Game Object.
 */
@mixin interface Size {
	/**
	 * A property indicating that a Game Object has this component.
	 */
	public var _sizeComponent:Bool = true;

	/**
	 * The native (un-scaled) width of this Game Object.
	 */
	public var width:Float = 0;

	/**
	 * The native (un-scaled) height of this Game Object.
	 *
	 * Changing this value will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or use
	 * the `displayHeight` property.
	 */
	public var height:Float = 0;

	/**
	 * The displayed width of this Game Object.
	 *
	 * This value takes into account the scale factor.
	 *
	 * Setting this value will adjust the Game Object's scale property.
	 */
	public var displayWidth(get, set):Float;

	function get_displayWidth():Float {
		return Math.abs(scaleX * frame.realWidth);
  }

	function set_displayWidth(value:Float):Float {
    scaleX = value / frame.realWidth;

		return Math.abs(scaleX * frame.realWidth);
	}

	/**
	 * The displayed height of this Game Object.
	 *
	 * This value takes into account the scale factor.
	 *
	 * Setting this value will adjust the Game Object's scale property.
	 */
	public var displayHeight(get, set):Float;

	function get_displayHeight():Float {
		return Math.abs(scaleY * frame.realHeight);
  }

	function set_displayHeight(value:Float):Float {
    scaleY = value / frame.realHeight;

		return Math.abs(scaleY * frame.realHeight);
	}

	/**
	 * Sets the size of this Game Object to be that of the given Frame.
	 *
	 * This will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or call the
	 * `setDisplaySize` method, which is the same thing as changing the scale but allows you
	 * to do so by giving pixel values.
	 *
	 * If you have enabled this Game Object for input, changing the size will _not_ change the
	 * size of the hit area. To do this you should adjust the `input.hitArea` object directly.
	 */
	// TODO: Impliment Frame
	public function setSizeToFrame(?_frame:Frame = null):Dynamic {
    if (_frame == null) _frame = frame;

		this.width = _frame.realWidth;
		this.height = _frame.realHeight;

		return this;
	}

	/**
	 * Sets the internal size of this Game Object, as used for frame or physics body creation.
	 *
	 * This will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or call the
	 * `setDisplaySize` method, which is the same thing as changing the scale but allows you
	 * to do so by giving pixel values.
	 *
	 * If you have enabled this Game Object for input, changing the size will _not_ change the
	 * size of the hit area. To do this you should adjust the `input.hitArea` object directly.
	 */
	public function setSize(width:Float, height:Float):Dynamic {
		this.width = width;
		this.height = height;

		return this;
	}

	/**
	 * Sets the display size of this Game Object.
	 *
	 * Calling this will adjust the scale.
	 */
	public function setDisplaySize(width:Float, height:Float):Dynamic {
		this.displayWidth = width;
		this.displayHeight = height;

		return this;
	}
}