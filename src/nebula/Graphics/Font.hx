package nebula.graphics;

import nebula.math.Vector;

import nebula.collision.BoundingBox;

import nebula.Color;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.graphics.FontCommon;
import nebula.graphics.Graphic;

import nebula.graphics.Raster;
import nebula.graphics.Filtering;
import nebula.graphics.FontTextInstance;
import nebula.graphics.FontCache;

/**
 * Represents a system or web font in Excalibur
 *
 * If no options specified, the system sans-serif 10 pixel is used
 *
 * If loading a custom web font be sure to have the font loaded before you use it https://erikonarheim.com/posts/dont-test-fonts/
 */
class Font extends Graphic implements FontRenderer {
  /**
   * Set the font filtering mode, by default set to {@apilink ImageFiltering.Blended} regardless of the engine default smoothing
   *
   * If you have a pixel style font that may be a reason to switch this to {@apilink ImageFiltering.Pixel}
   */
  public var filtering: ImageFiltering = ImageFiltering.Blended;
  public function new(options: FontOptions & GraphicOptions & RasterOptions = {}) {
    super(options); // <- Graphics properties

    // Raster properties
    this.smoothing = options?.smoothing ?? this.smoothing;
    this.padding = options?.padding ?? this.padding;
    this.color = options?.color ?? this.color;
    this.strokeColor = options?.strokeColor ?? this.strokeColor;
    this.lineDash = options?.lineDash ?? this.lineDash;
    this.lineWidth = options?.lineWidth ?? this.lineWidth;
    this.filtering = options?.filtering ?? this.filtering;

    // Font specific properties
    this.family = options?.family ?? this.family;
    this.style = options?.style ?? this.style;
    this.bold = options?.bold ?? this.bold;
    this.size = options?.size ?? this.size;
    this.unit = options?.unit ?? this.unit;
    this.textAlign = options?.textAlign ?? this.textAlign;
    this.baseAlign = options?.baseAlign ?? this.baseAlign;
    this.direction = options?.direction ?? this.direction;
    this.lineHeight = options?.lineHeight ?? this.lineHeight;
    this.quality = options?.quality ?? this.quality;
    if (options?.shadow) {
      this.shadow = {};
      this.shadow.blur = options.shadow.blur ?? this.shadow.blur;
      this.shadow.offset = options.shadow.offset ?? this.shadow.offset;
      this.shadow.color = options.shadow.color ?? this.shadow.color;
    }
  }

  public function clone() {
    final options = Object.spreadWith(
      this.cloneGraphicOptions(),
      {
        size: this.size,
        unit: this.unit,
        family: this.family,
        style: this.style,
        bold: this.bold,
        textAlign: this.textAlign,
        baseAlign: this.baseAlign,
        direction: this.direction,
        shadow: this.shadow
          ? {
              blur: this.shadow.blur,
              offset: this.shadow.offset,
              color: this.shadow.color
            }
          : null
      }
    );

    return new Font(options);
  }

  /**
   * Font quality determines the size of the underlying raster text, higher quality means less jagged edges.
   * If quality is set to 1, then just enough raster bitmap is generated to render the text.
   *
   * You can think of quality as how zoomed in to the text you can get before seeing jagged edges.
   *
   * (Default 2)
   */
  public var quality = 2;

  // Raster properties for fonts
  public var padding = 2;
  public var smoothing = false;
  public var lineWidth = 1;
  public var lineDash: Array<Int> = [];
  public var color: Color = Color.Black;
  public var strokeColor: Null<Color>;

  public var family: String = 'sans-serif';
  public var style: FontStyle = FontStyle.Normal;
  public var bold: Bool = false;
  public var unit: FontUnit = FontUnit.Px;
  public var textAlign: TextAlign = TextAlign.Left;
  public var baseAlign: BaseAlign = BaseAlign.Top;
  public var direction: Direction = Direction.LeftToRight;
  /**
   * Font line height in pixels, default line height if unset
   */
  public var lineHeight: Null<Int> = null;
  public var size: Int = 10;
  public var shadow: Null<{ blur: Null<Int>, offset: Null<Vector>, color: Null<Color> }>;

  public var fontString(get, never): String;
  function get_fontString() {
    return '${this.style} ${this.bold ? 'bold' : ''} ${this.size}${this.unit} ${this.family}';
  }

  private var _textBounds: BoundingBox = new BoundingBox();

  public var localBounds(get, never): BoundingBox;
  function get_localBounds(): BoundingBox {
    return this._textBounds;
  }

  private function _drawImage(_ex: ExcaliburGraphicsContext, _x: Int, _y: Int) {
    // TODO weird vestigial drawimage
  }

  private function _rotate(ex: ExcaliburGraphicsContext) {
    // TODO this needs to change depending on the bounding box...
    final origin = this.origin ?? this._textBounds.center;
    ex.translate(origin.x, origin.y);
    ex.rotate(this.rotation);
    ex.translate(-origin.x, -origin.y);
  }

  private function _flip(ex: ExcaliburGraphicsContext) {
    if (this.flipHorizontal) {
      ex.translate(this._textBounds.width / this.scale.x, 0);
      ex.scale(-1, 1);
    }

    if (this.flipVertical) {
      ex.translate(0, -this._textBounds.height / 2 / this.scale.y);
      ex.scale(1, -1);
    }
  }

  private var _textMeasurement = new FontTextInstance(this, '', Color.Black);

  public function measureTextWithoutCache(text: String, ?maxWidth: Int) {
    return this._textMeasurement.measureText(text, maxWidth);
  }

  /**
   * Returns a BoundingBox that is the total size of the text including multiple lines
   *
   * Does not include any padding or adjustment
   * @param text
   * @returns BoundingBox
   */
  public function measureText(text: String, ?maxWidth: Int): BoundingBox {
    return FontCache.measureText(text, this, maxWidth);
  }

  private function _postDraw(ex: ExcaliburGraphicsContext): Void {
    ex.restore();
  }

  public function render(ex: ExcaliburGraphicsContext, text: String, colorOverride: Color, x: Int, y: Int, ?maxWidth: Int) {
    final textInstance = FontCache.getTextInstance(text, this, colorOverride);

    // Apply affine transformations
    this._textBounds = textInstance.dimensions;
    this._preDraw(ex, x, y);

    textInstance.render(ex, x, y, maxWidth);

    this._postDraw(ex);
  }
}
