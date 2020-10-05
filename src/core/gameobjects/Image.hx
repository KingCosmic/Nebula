package core.gameobjects;

import core.gameobjects.RenderableGameObject;
import core.cameras.Camera;
import core.scene.Scene;

/**
 * An Image Game Object.
 *
 * An Image is a light-weight Game Object useful for the display of static images in your game,
 * such as logos, backgrounds, scenery or other non-animated elements. Images can have input
 * events and physics bodies, or be tweened, tinted or scrolled. The main difference between an
 * Image and a Sprite is that you cannot animate an Image as they do not have the Animation component.
 */
class Image extends RenderableGameObject {
	public function new(scene:Scene, x:Float, y:Float, texture:String, ?frame:String = '') {
		super(scene, 'Image');

		this._crop = this.resetCropObject();
		this.setTexture(texture, frame);
		this.setPosition(x, y);
		this.setSizeToFrame();
		this.setOriginFromFrame();
		this.initPipeline();
	}

	/**
	 * Renders this Game Object with the Canvas Renderer to the given Camera.
	 * The object will not render if any of its renderFlags are set or it is being actively filtered out by the Camera.
	 * This method should not be called directly. It is a utility function of the Render module.
	 */
	override public function render(renderer:Renderer, camera:Camera) {
    renderer.batchImage(this, frame, camera);
	}
}