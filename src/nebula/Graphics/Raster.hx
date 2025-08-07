package nebula.graphics;

import nebula.graphics.Graphic;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.Color;
import nebula.math.Vector;

import nebula.collision.BoundingBox;

import nebula.util.Watch;
import nebula.util.Util;

import nebula.graphics.Filtering;

interface RasterOptions extends GraphicOptions {
  /**
   * Optionally specify a quality number, which is how much to scale the internal Raster. Default is 1.
   *
   * For example if the quality is set to 2, it doubles the internal raster bitmap in memory.
   *
   * Adjusting this value can be useful if you are working with small rasters.
   */
  var quality: Null<Int>;
  /**
   * Optionally specify "smoothing" if you want antialiasing to apply to the raster's bitmap context, by default `false`
   */
  var smoothing: Null<Bool>;

  /**
   * Optionally specify the color of the raster's bitmap context, by default {@apilink Color.Black}
   */
  var color: Null<Color>;

  /**
   * Optionally specify the stroke color of the raster's bitmap context, by default undefined
   */
  var strokeColor: Null<Color>;

  /**
   * Optionally specify the line width of the raster's bitmap, by default 1 pixel
   */
  var lineWidth: Null<Int>;

  /**
   * Optionally specify the line dash of the raster's bitmap, by default `[]` which means none
   */
  var lineDash: Null<Array<Int>>;

  /**
   * Optionally specify the line end style, default is "butt".
   */
  var lineCap: Null<String>;

  /**
   * Optionally specify the padding to apply to the bitmap
   */
  var padding: Null<Int>;

  /**
   * Optionally specify what image filtering mode should be used, {@apilink ImageFiltering.Pixel} for pixel art,
   * {@apilink ImageFiltering.Blended} for hi-res art
   *
   * By default unset, rasters defer to the engine antialiasing setting
   */
  var filtering: Null<ImageFiltering>;
}

/**
 * A Raster is a Graphic that needs to be first painted to a HTMLCanvasElement before it can be drawn to the
 * {@apilink ExcaliburGraphicsContext}. This is useful for generating custom images using the 2D canvas api.
 *
 * Implementors must implement the {@apilink Raster.execute} method to rasterize their drawing.
 */
abstract class Raster extends Graphic {
  public var filtering: Null<ImageFiltering>;
  public var lineCap: String;
  public var quality: Int = 1;

  public var _bitmap: HTMLCanvasElement;
  public var _ctx: CanvasRenderingContext2D;
  private var _dirty: Bool = true;

  public function new(?options: RasterOptions) {
    super(omit(options, ['width', 'height'])); // rasters do some special sauce with width/height
    if (options) {
      this.quality = options.quality ?? this.quality;
      this.color = options.color ?? Color.Black;
      this.strokeColor = options?.strokeColor;
      this.smoothing = options.smoothing ?? this.smoothing;
      this.lineWidth = options.lineWidth ?? this.lineWidth;
      this.lineDash = options.lineDash ?? this.lineDash;
      this.lineCap = options.lineCap ?? this.lineCap;
      this.padding = options.padding ?? this.padding;
      this.filtering = options.filtering ?? this.filtering;
    }
    this._bitmap = document.createElement('canvas');
    // get the default canvas width/height as a fallback
    final bitmapWidth = options?.width ?? this._bitmap.width;
    final bitmapHeight = options?.height ?? this._bitmap.height;
    this.width = bitmapWidth;
    this.height = bitmapHeight;
    final maybeCtx = this._bitmap.getContext('2d');
    if (!maybeCtx) {
      /* istanbul ignore next */
      throw new Error('Browser does not support 2d canvas drawing, cannot create Raster graphic');
    } else {
      this._ctx = maybeCtx;
    }
  }

  public function cloneRasterOptions(): RasterOptions {
    return {
      color: this.color ? this.color.clone() : undefined,
      strokeColor: this.strokeColor ? this.strokeColor.clone() : undefined,
      smoothing: this.smoothing,
      lineWidth: this.lineWidth,
      lineDash: this.lineDash,
      lineCap: this.lineCap,
      quality: this.quality,
      padding: this.padding
    };
  }

  /**
   * Gets whether the graphic is dirty, this means there are changes that haven't been re-rasterized
   */
  public var dirty(get, never): Bool;
  function get_dirty() {
    return this._dirty;
  }

  /**
   * Flags the graphic as dirty, meaning it must be re-rasterized before draw.
   * This should be called any time the graphics state changes such that it affects the outputted drawing
   */
  public function flagDirty() {
    this._dirty = true;
  }

  private var _originalWidth: Null<Int>;
  /**
   * Gets or sets the current width of the Raster graphic. Setting the width will cause the raster
   * to be flagged dirty causing a re-raster on the next draw.
   *
   * Any `padding`s or `quality` set will be factored into the width
   */
  public var width(get, set): Int;
  function get_width() {
    return Math.abs(this._getTotalWidth() * this.scale.x);
  }
  function set_width(value: Int) {
    value /= Math.abs(this.scale.x);
    this._bitmap.width = value;
    this._originalWidth = value;
    this.flagDirty();
  }

  private var _originalHeight: Null<Int>;
  /**
   * Gets or sets the current height of the Raster graphic. Setting the height will cause the raster
   * to be flagged dirty causing a re-raster on the next draw.
   *
   * Any `padding` or `quality` set will be factored into the height
   */
  public var height(get, set): Int;
  function get_height() {
    return Math.abs(this._getTotalHeight() * this.scale.y);
  }
  function set_height(value: Int) {
    value /= Math.abs(this.scale.y);
    this._bitmap.height = value;
    this._originalHeight = value;
    this.flagDirty();
  }

  private function _getTotalWidth() {
    return ((this._originalWidth ?? this._bitmap.width) + this.padding * 2) * 1;
  }

  private function _getTotalHeight() {
    return ((this._originalHeight ?? this._bitmap.height) + this.padding * 2) * 1;
  }

  /**
   * Returns the local bounds of the Raster including the padding
   */
  public var localBounds(get, never): BoundingBox;
  function get_localBounds() {
    return BoundingBox.fromDimension(this._getTotalWidth() * this.scale.x, this._getTotalHeight() * this.scale.y, Vector.Zero);
  }

  private var _smoothing: Bool = false;
  /**
   * Gets or sets the smoothing (anti-aliasing of the graphic). Setting the height will cause the raster
   * to be flagged dirty causing a re-raster on the next draw.
   */
  public var smoothing(get, set): Bool;
  function get_smoothing() {
    return this._smoothing;
  }
  function set_smoothing(value: Bool) {
    this._smoothing = value;
    this.flagDirty();
  }

  private var _color: Color = watch(Color.Black, () -> this.flagDirty());
  /**
   * Gets or sets the fillStyle of the Raster graphic. Setting the fillStyle will cause the raster to be
   * flagged dirty causing a re-raster on the next draw.
   */
  public var color(get, set): Color;
  function get_color() {
    return this._color;
  }
  function set_color(value) {
    this.flagDirty();
    this._color = watch(value, () -> this.flagDirty());
  }

  private var _strokeColor: Null<Color>;
  /**
   * Gets or sets the strokeStyle of the Raster graphic. Setting the strokeStyle will cause the raster to be
   * flagged dirty causing a re-raster on the next draw.
   */
  public var strokeColor(get, set): Null<Color>;
  function get_strokeColor() {
    return this._strokeColor;
  }
  function set_strokeColor(value: Null<Color>) {
    this.flagDirty();
    if (value) {
      this._strokeColor = watch(value, () -> this.flagDirty());
    }
  }

  private var _lineWidth: Int = 1;
  /**
   * Gets or sets the line width of the Raster graphic. Setting the lineWidth will cause the raster to be
   * flagged dirty causing a re-raster on the next draw.
   */
  public var lineWidth(get, set): Int;
  function get_lineWidth() {
    return this._lineWidth;
  }
  function set_lineWidth(value: Int) {
    this._lineWidth = value;
    this.flagDirty();
  }

  private var _lineDash: Array<Int> = [];
  public var lineDash(get, set): Array<Int>;
  function get_lineDash() {
    return this._lineDash;
  }
  function set_lineDash(value: Array<Int>) {
    this._lineDash = value;
    this.flagDirty();
  }

  private var _padding: Int = 0;
  public var padding(get, set): Int;
  function get_padding() {
    return this._padding;
  }
  function set_padding(value: Int) {
    this._padding = value;
    this.flagDirty();
  }

  /**
   * Rasterize the graphic to a bitmap making it usable as in excalibur. Rasterize is called automatically if
   * the graphic is {@apilink Raster.dirty} on the next {@apilink Graphic.draw} call
   */
  public function rasterize(): Void {
    this._dirty = false;
    this._ctx.clearRect(0, 0, this._getTotalWidth(), this._getTotalHeight());
    this._ctx.save();
    this._applyRasterProperties(this._ctx);
    this.execute(this._ctx);
    this._ctx.restore();
  }

  private function _applyRasterProperties(ctx: CanvasRenderingContext2D) {
    this._bitmap.width = this._getTotalWidth() * this.quality;
    this._bitmap.height = this._getTotalHeight() * this.quality;
    // Do a bad thing to pass the filtering as an attribute
    this._bitmap.setAttribute('filtering', this.filtering);
    this._bitmap.setAttribute('forceUpload', 'true');
    ctx.scale(this.quality, this.quality);
    ctx.translate(this.padding, this.padding);
    ctx.imageSmoothingEnabled = this.smoothing;
    ctx.lineWidth = this.lineWidth;
    ctx.setLineDash(this.lineDash ?? ctx.getLineDash());
    ctx.lineCap = this.lineCap;
    ctx.strokeStyle = this.strokeColor?.toString() ?? '';
    ctx.fillStyle = this.color?.toString();
  }

  private function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int) {
    if (this._dirty) {
      this.rasterize();
    }
    ex.scale(1 / this.quality, 1 / this.quality);
    ex.drawImage(this._bitmap, x, y);
  }

  /**
   * Executes drawing implementation of the graphic, this is where the specific drawing code for the graphic
   * should be implemented. Once `rasterize()` the graphic can be drawn to the {@apilink ExcaliburGraphicsContext} via `draw(...)`
   * @param ctx Canvas to draw the graphic to
   */
  abstract function execute(ctx: CanvasRenderingContext2D): Void;
}
