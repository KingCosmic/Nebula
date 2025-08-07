package nebula.graphics;

import nebula.graphics.Graphic;
import nebula.graphics.ImageSource;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.util.Log;

typedef SourceView = {
  var x: Int; var y: Int; var width: Int; var height: Int;
};
typedef DestinationSize = { var width: Int; var height: Int; };

interface SpriteOptions {
  /**
   * Image to create a sprite from
   */
  var image: ImageSource;
  /**
   * By default the source is the entire dimension of the {@apilink ImageSource}
   */
  var sourceView: Null<{ x: Int, y: Int, width: Int, height: Int }>;
  /**
   * By default the size of the final sprite is the size of the {@apilink ImageSource}
   */
  var destSize: Null<{ width: Int, height: Int }>;
}

class Sprite extends Graphic {
  private var _logger = Logger.getInstance();
  public var image: ImageSource;
  public var sourceView: SourceView;
  public var destSize: DestinationSize;
  private var _dirty = true;

  public static function from(image: ImageSource, ?options: Omit<GraphicOptions & SpriteOptions, 'image'>): Sprite {
    return new Sprite(
      Object.spreadWith({
        image: image,
      },
      options
    ));
  }

  public function new(options: GraphicOptions & SpriteOptions) {
    super(options);
    this.image = options.image;
    final width = options.width,
          height = options.height;
    this.sourceView = options.sourceView ?? { x: 0, y: 0, width: width ?? 0, height: height ?? 0 };
    this.destSize = options.destSize ?? { width: width ?? 0, height: height ?? 0 };
    this._updateSpriteDimensions();
    // Fire when loaded
    this.image.ready.then(() -> {
      this._updateSpriteDimensions();
    });
  }

  override function get_width(): Int {
    return Math.abs(this.destSize.width * this.scale.x);
  }

  override function get_height(): Int {
    return Math.abs(this.destSize.height * this.scale.y);
  }

  override function set_width(newWidth: Int) {
    newWidth /= Math.abs(this.scale.x);
    this.destSize.width = newWidth;
    super.width = Math.ceil(this.destSize.width);
  }

  override function set_height(newHeight: Int) {
    newHeight /= Math.abs(this.scale.y);
    this.destSize.height = newHeight;
    super.height = Math.ceil(this.destSize.height);
  }

  private function _updateSpriteDimensions() {
    final nativeWidth = this.image.width,
          nativeHeight = this.image.height;

    // This code uses || to avoid 0's
    // If the source is not specified, use the native dimension
    this.sourceView.width = this.sourceView?.width || nativeWidth;
    this.sourceView.height = this.sourceView?.height || nativeHeight;

    // If the destination is not specified, use the source if specified, then native
    this.destSize.width = this.destSize?.width || this.sourceView?.width || nativeWidth;
    this.destSize.height = this.destSize?.height || this.sourceView?.height || nativeHeight;

    this.width = Math.ceil(this.destSize.width) * this.scale.x;
    this.height = Math.ceil(this.destSize.height) * this.scale.y;
  }

  private function _preDraw(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void {
    if (this.image.isLoaded() && this._dirty) {
      this._dirty = false;
      this._updateSpriteDimensions();
    }
    super._preDraw(ex, x, y);
  }

  public function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void {
    if (this.image.isLoaded()) {
      ex.drawImage(
        this.image.image,
        this.sourceView.x,
        this.sourceView.y,
        this.sourceView.width,
        this.sourceView.height,
        x,
        y,
        this.destSize.width,
        this.destSize.height
      );
    } else {
      this._logger.warnOnce(
        'ImageSource ${this.image.path}' +
          ' is not yet loaded and won\'t be drawn. Please call .load() or include in a Loader.\n\n ' +
          'Read https://excaliburjs.com/docs/imagesource for more information.'
      );
    }
  }

  public function clone(): Sprite {
    var config = Object.spreadWith({
      image: this.image,
      sourceView: Object.spreadWith(this.sourceView, {}),
      destSize: Object.spreadWith(this.destSize, {}),
    }, this.cloneGraphicOptions());
    
    return new Sprite(config);
  }
}
