package core.gameobjects;

import core.gameobjects.components.RenderableMixin;
import core.input.InteractiveObject;
import core.scene.Scene;

class RenderableGameObject extends GameObject implements RenderableMixin {
	/**
	 * If this Game Object is enabled for input then this property will contain an InteractiveObject instance.
	 * Not usually set directly. Instead call `GameObject.setInteractive()`.
	 */
  public var input:Null<InteractiveObject>;
  
	public function new(_scene:Scene, type:String) {
    super(_scene, type);
  }

	/**
	 * Pass this Game Object to the Input Manager to enable it for Input.
	 *
	 * Input works by using hit areas, these are nearly always geometric shapes, such as rectangles or circles, that act as the hit area
	 * for the Game Object. However, you can provide your own hit area shape and callback, should you wish to handle some more advanced
	 * input detection.
	 *
	 * If no arguments are provided it will try and create a rectangle hit area based on the texture frame the Game Object is using. If
	 * this isn't a texture-bound object, such as a Graphics or BitmapText object, this will fail, and you'll need to provide a specific
	 * shape for it to use.
	 *
	 * You can also provide an Input Configuration Object as the only argument to this method.
	 */
	public function setInteractive(?hitArea:Any, ?hitAreaCallback = null, ?dropZone:Bool = false) {
		scene.sys.input.enable(this, hitArea, hitAreaCallback, dropZone);

		return this;
	}

	/**
	 * If this Game Object has previously been enabled for input, this will disable it.
	 *
	 * An object that is disabled for input stops processing or being considered for
	 * input events, but can be turned back on again at any time by simply calling
	 * `setInteractive()` with no arguments provided.
	 *
	 * If want to completely remove interaction from this Game Object then use `removeInteractive` instead.
	 */
	public function disableInteractive() {
		if (input != null)
			input.enabled = false;

		return this;
	}

	/**
	 * If this Game Object has previously been enabled for input, this will queue it
	 * for removal, causing it to no longer be interactive. The removal happens on
	 * the next game step, it is not immediate.
	 *
	 * The Interactive Object that was assigned to this Game Object will be destroyed,
	 * removed from the Input Manager and cleared from this Game Object.
	 *
	 * If you wish to re-enable this Game Object at a later date you will need to
	 * re-create its InteractiveObject by calling `setInteractive` again.
	 *
	 * If you wish to only temporarily stop an object from receiving input then use
	 * `disableInteractive` instead, as that toggles the interactive state, where-as
	 * this erases it completely.
	 *
	 * If you wish to resize a hit area, don't remove and then set it as being
	 * interactive. Instead, access the hitarea object directly and resize the shape
	 * being used. I.e.: `sprite.input.hitArea.setSize(width, height)` (assuming the
	 * shape is a Rectangle, which it is by default.)
	 */
	public function removeInteractive() {
		scene.input.clear(this);

		input = null;

		return this;
	}
}