package nebula.graphics;

import nebula.util.Future;
import nebula.graphics.Filtering;
import nebula.graphics.Graphic;
import nebula.graphics.ImageSource;
import nebula.graphics.Sprite;
import nebula.graphics.Wrapping;

interface TiledSpriteOptions {
  var image: ImageSource;
  /**
   * Source view into the {@link ImageSource image}
   */
  var sourceView: Null<SourceView>;
  /**
   * Optionally override {@link ImageFiltering filtering}
   */
  var filtering: Null<ImageFiltering>;
  /**
   * Optionally override {@link ImageWrapping wrapping} , default wrapping is Repeat for TiledSprite
   */
  var wrapping: Null<ImageWrapConfiguration>;
  /**
   * Total width in pixels for the tiling to take place over
   */
  var width: Int;
  /**
   * Total height in pixels for the tiling to take place over
   */
  var height: Int;
}

class TiledSprite extends Sprite {
  private var _ready = new Future<Void>();
  public var ready = this._ready.promise;
  private var _options: TiledSpriteOptions & GraphicOptions;
  public function new(options: TiledSpriteOptions & GraphicOptions) {
    super({
      image: options.image,
      sourceView: options.sourceView,
      destSize: { width: options.width, height: options.height },
      flipHorizontal: options.flipHorizontal,
      flipVertical: options.flipVertical,
      rotation: options.rotation,
      scale: options.scale,
      opacity: options.opacity,
      tint: options.tint,
      origin: options.origin
    });
    this._options = options;

    if (this.image.isLoaded()) {
      this._applyTiling();
    } else {
      this.image.ready.then(() -> this._applyTiling());
    }
  }

  public static function fromSprite(sprite: Sprite, ?options: Partial<Omit<TiledSpriteOptions & GraphicOptions, 'image'>>): TiledSprite {
    var config = Object.spreadWith(
      {
        sourceView: Object.spreadWith(sprite.sourceView, {}),
        width: sprite.width,
        height: sprite.height,
        image: sprite.image
      },
      options
    );

    return new TiledSprite(config);
  }

  private function _applyTiling() {
    final width = this._options.width,
          height = this._options.height,
          filtering = this._options.filtering,
          wrapping = this._options.wrapping;

    final spriteCanvas = document.createElement('canvas')!;
    spriteCanvas.width = this.sourceView.width;
    spriteCanvas.height = this.sourceView.height;
    final spriteCtx = spriteCanvas.getContext('2d')!;

    spriteCtx.drawImage(
        this.image.image,
        this.sourceView.x, this.sourceView.y,
        this.sourceView.width, this.sourceView.height,
        0, 0,
        this.sourceView.width, this.sourceView.height);

    final tiledImageSource = ImageSource.fromHtmlCanvasElement(spriteCanvas, {
        wrapping: wrapping ?? ImageWrapping.Repeat,
        filtering: filtering
      });
    if (width) {
      this.destSize.width = width;
      this.sourceView.width = width;
    }
    if (height) {
      this.destSize.height = height;
      this.sourceView.height = height;
    }
    this.sourceView.x = 0;
    this.sourceView.y = 0;
    this.image = tiledImageSource;
    // this._ready.resolve();
    this.image.ready.then(() -> this._ready.resolve());
  }
}
