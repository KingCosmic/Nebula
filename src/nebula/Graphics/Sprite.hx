package nebula.Graphics;

import nebula.Graphics.Graphic;
import nebula.Graphics.ImageSource;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

import nebula.Util.Log;

type SourceView = { x: Int; y: Int; width: Int; height: Int };
type DestinationSize = { width: Int; height: Int };

interface SpriteOptions {
  /**
   * Image to create a sprite from
   */
  image: ImageSource;
  /**
   * By default the source is the entire dimension of the {@apilink ImageSource}
   */
  sourceView?: { x: Int; y: Int; width: Int; height: Int };
  /**
   * By default the size of the final sprite is the size of the {@apilink ImageSource}
   */
  destSize?: { width: Int; height: Int };
}

class Sprite extends Graphic {
  private _logger = Logger.getInstance();
  public image: ImageSource;
  public sourceView: SourceView;
  public destSize: DestinationSize;
  private _dirty = true;

  public static from(image: ImageSource, options?: Omit<GraphicOptions & SpriteOptions, 'image'>): Sprite {
    return new Sprite({
      image,
      ...options
    });
  }

  public function new(options: GraphicOptions & SpriteOptions) {
    super(options);
    this.image = options.image;
    final { width, height } = options;
    this.sourceView = options.sourceView ?? { x: 0, y: 0, width: width ?? 0, height: height ?? 0 };
    this.destSize = options.destSize ?? { width: width ?? 0, height: height ?? 0 };
    this._updateSpriteDimensions();
    // Fire when loaded
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    this.image.ready.then(() => {
      this._updateSpriteDimensions();
    });
  }

  public override get width(): Int {
    return Math.abs(this.destSize.width * this.scale.x);
  }

  public override get height(): Int {
    return Math.abs(this.destSize.height * this.scale.y);
  }

  public override set width(newWidth: Int) {
    newWidth /= Math.abs(this.scale.x);
    this.destSize.width = newWidth;
    super.width = Math.ceil(this.destSize.width);
  }

  public override set height(newHeight: Int) {
    newHeight /= Math.abs(this.scale.y);
    this.destSize.height = newHeight;
    super.height = Math.ceil(this.destSize.height);
  }

  private _updateSpriteDimensions() {
    final { width: nativeWidth, height: nativeHeight } = this.image;
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
    return new Sprite({
      image: this.image,
      sourceView: { ...this.sourceView },
      destSize: { ...this.destSize },
      ...this.cloneGraphicOptions()
    });
  }
}
