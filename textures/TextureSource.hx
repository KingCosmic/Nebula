package core.textures;

/**
 * A Texture Source is the encapsulation of the actual source data for a Texture.
 *
 * This is typically an Image Element, loaded from the file system or network, a Canvas Element or a Video Element.
 *
 * A Texture can contain multiple Texture Sources, which only happens when a multi-atlas is loaded.
 */
class TextureSource {
  // The Renderer this TextureSource belongs to.
  public var renderer:Renderer;

  // The Texture this TextureSource belongs to.
  public var texture:Texture;

  // The source of the image data.
  public var source:kha.Image;

  // The image data.
  public var image:kha.Image;

  // The resolution of the source image.
  public var resolution = 1;

  /**
   * The width of the source image. If not specified in the constructor it will check
   * the `naturalWidth` and then `width` properties of the source image.
   */
  public var width:Int;

  /**
   * The height of the source image. If not specified in the constructor it will check
   * the `naturalHeight` and then `height` properties of the source image.
   */
  public var height:Int;

  /**
   * The Scale Mode the image will use when rendering.
   * Either Linear or Nearest.
   */
  public var scaleMode:Int = 0;

  // Are the source image dimensions a power of two?
  public var isPowerOf2:Bool = false;

  // idk what this is used for in kha so it's here.
  public var flipY:Bool = false;

  public function new(_texture:Texture, _source:kha.Image, ?_width:Int, ?_height:Int, ?_flipY:Bool = false)  {
    var game = _texture.manager.game;

    renderer = game.renderer;
    texture = _texture;
    source = _source;
    image = source;

    width = _width |  source.width | 0;
    height = _height | source.height | 0;

		isPowerOf2 = (width > 0 && (width & (width - 1)) == 0 && height > 0 && (height & (height - 1)) == 0);
  
    init(game);
  }

  // Creates a WebGL Texture, if required, and sets the Texture filter mode.
  public function init(game:Game) {

  }

  public function update() {}

  /**
   * Destroys this Texture Source and nulls the references.
   */
  public function destroy() {
    renderer = null;
    texture = null;
    source = null;
    image = null;
  }
}