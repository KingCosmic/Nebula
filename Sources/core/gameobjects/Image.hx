package core.gameobjects;
import core.gameobjects.components.Alpha;
import core.gameobjects.components.BlendMode;
import core.gameobjects.components.Depth;
import core.gameobjects.components.Flip;
import core.gameobjects.components.GetBounds;
import core.gameobjects.components.Mask;
import core.gameobjects.components.Origin;
import core.gameobjects.components.Pipeline;
import core.gameobjects.components.ScrollFactor;
import core.gameobjects.components.Size;
import core.gameobjects.components.TextureCrop;
import core.gameobjects.components.Tint;
import core.gameobjects.components.Transform_mixin;
import core.gameobjects.components.Visible;
import core.cameras.Camera;
import core.scene.Scene;

/* MIXINS
* @extends Phaser.GameObjects.Components.Alpha
* @extends Phaser.GameObjects.Components.BlendMode
* @extends Phaser.GameObjects.Components.Depth
* @extends Phaser.GameObjects.Components.Flip
* @extends Phaser.GameObjects.Components.GetBounds
* @extends Phaser.GameObjects.Components.Mask
* @extends Phaser.GameObjects.Components.Origin
* @extends Phaser.GameObjects.Components.Pipeline
* @extends Phaser.GameObjects.Components.ScrollFactor
* @extends Phaser.GameObjects.Components.Size
* @extends Phaser.GameObjects.Components.TextureCrop
* @extends Phaser.GameObjects.Components.Tint
* @extends Phaser.GameObjects.Components.Transform
* @extends Phaser.GameObjects.Components.Visible
*/

/**
 * An Image Game Object.
 *
 * An Image is a light-weight Game Object useful for the display of static images in your game,
 * such as logos, backgrounds, scenery or other non-animated elements. Images can have input
 * events and physics bodies, or be tweened, tinted or scrolled. The main difference between an
 * Image and a Sprite is that you cannot animate an Image as they do not have the Animation component.
 */
class Image extends GameObject implements Alpha implements BlendMode implements Depth implements Flip implements GetBounds implements Mask implements Transform implements Origin implements Pipeline implements ScrollFactor  implements Size implements TextureCrop implements Tint implements Visible  {
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
  * The internal crop data object, as used by `setCrop` and passed to the `Frame.setCropUVs` method.
  */ //To-Do Why Isn't this used by a Component?
  private var _crop:{
    u0:Float,
    v0:Float,
    u1:Float,
    v1:Float,
    x:Float,
    y:Float,
    cx:Float,
    cy:Float,
    cw:Float,
    ch:Float,
    width:Float,
    height:Float,
    flipX:Bool,
    flipY:Bool
};
  
  /**
   * Renders this Game Object with the Canvas Renderer to the given Camera.
   * The object will not render if any of its renderFlags are set or it is being actively filtered out by the Camera.
   * This method should not be called directly. It is a utility function of the Render module.
   */
  override public function render(renderer:Renderer, camera:Camera) {
    renderer.batchImage(this, texture.source[0].source, camera);
  }
}