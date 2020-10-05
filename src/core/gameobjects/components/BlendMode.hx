package core.gameobjects.components;

import core.gameobjects.GameObject;
import core.renderer.BlendModes;

/**
 * Provides methods used for setting the blend mode of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface BlendMode {
	/**
	 * Private internal value. Holds the current blend mode.
	 */
	public var _blendMode:Int = BlendModes.NORMAL;

	/**
	 * Sets the Blend Mode being used by this Game Object.
	 *
	 * This can be a const, such as `Phaser.BlendModes.SCREEN`, or an integer, such as 4 (for Overlay)
	 *
	 * Under WebGL only the following Blend Modes are available:
	 *
	 * * ADD
	 * * MULTIPLY
	 * * SCREEN
	 * * ERASE
	 *
	 * Canvas has more available depending on browser support.
	 *
	 * You can also create your own custom Blend Modes in WebGL.
	 *
	 * Blend modes have different effects under Canvas and WebGL, and from browser to browser, depending
	 * on support. Blend Modes also cause a WebGL batch flush should it encounter a new blend mode. For these
	 * reasons try to be careful about the construction of your Scene and the frequency of which blend modes
	 * are used.
	 */
	public var blendMode(get, set):Int;

	function get_blendMode():Int {
		return this._blendMode;
	}

	function set_blendMode(value:Int):Int {
		if (value >= -1) {
			this._blendMode = value;
		}
		return get_blendMode();
	}

	/**
	 * Sets the Blend Mode being used by this Game Object.
	 *
	 * This can be a const, such as `Phaser.BlendModes.SCREEN`, or an integer, such as 4 (for Overlay)
	 *
	 * Under WebGL only the following Blend Modes are available:
	 *
	 * * ADD
	 * * MULTIPLY
	 * * SCREEN
	 * * ERASE (only works when rendering to a framebuffer, like a Render Texture)
	 *
	 * Canvas has more available depending on browser support.
	 *
	 * You can also create your own custom Blend Modes in WebGL.
	 *
	 * Blend modes have different effects under Canvas and WebGL, and from browser to browser, depending
	 * on support. Blend Modes also cause a WebGL batch flush should it encounter a new blend mode. For these
	 * reasons try to be careful about the construction of your Scene and the frequency in which blend modes
	 * are used.
	 */
	public function setBlendMode(value:Int):GameObject {
		this.blendMode = value;
		return this;
	}
}