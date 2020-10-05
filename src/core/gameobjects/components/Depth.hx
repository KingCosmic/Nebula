package core.gameobjects.components;

import core.gameobjects.GameObject;

/**
 * Provides methods used for setting the depth of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface Depth {
	/**
	 * Private internal value. Holds the depth of the Game Object.
	 */
	public var _depth:Int = 0;

	/**
	 * The depth of this Game Object within the Scene.
	 *
	 * The depth is also known as the 'z-index' in some environments, and allows you to change the rendering order
	 * of Game Objects, without actually moving their position in the display list.
	 *
	 * The default depth is zero. A Game Object with a higher depth
	 * value will always render in front of one with a lower value.
	 *
	 * Setting the depth will queue a depth sort event within the Scene.
	 */
	public var depth(get, set):Int;

	function get_depth():Int {
		return this._depth;
	}

	function set_depth(value:Int):Int {
		this.scene.sys.queueDepthSort();
		this._depth = value;
		return get_depth();
	}

	/**
	 * The depth of this Game Object within the Scene.
	 *
	 * The depth is also known as the 'z-index' in some environments, and allows you to change the rendering order
	 * of Game Objects, without actually moving their position in the display list.
	 *
	 * The default depth is zero. A Game Object with a higher depth
	 * value will always render in front of one with a lower value.
	 *
	 * Setting the depth will queue a depth sort event within the Scene.
	 */
	public function setDepth(value:Int = 0):GameObject {
		this.depth = value;
		return this;
	}
}