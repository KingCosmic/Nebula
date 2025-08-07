package nebula.graphics;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.collision.BoundingBox;

import nebula.graphics.SpriteFont;
import nebula.graphics.Graphic;
import nebula.graphics.Font;

import nebula.Color;

interface TextOptions {
  /**
   * Text to draw
   */
  var text: String;

  /**
   * Optionally override the font color, currently unsupported by SpriteFont
   */
  var color: Null<Color>;

  /**
   * Optionally specify a font, if none specified a default font is used (System sans-serif 10 pixel)
   */
  var font: Null<Font>;

  /**
   * Optionally specify a maximum width in pixels for our text, and wrap to the next line if needed.
   */
  var maxWidth: Null<Int>;
}

/**
 * Represent Text graphics in excalibur
 *
 * Useful for in game labels, ui, or overlays
 */
class Text extends Graphic {
  public var color: Null<Color>;
  public var maxWidth: Null<Int>;

  public function new(options: TextOptions & GraphicOptions) {
    super(options);
    // This order is important font, color, then text
    this.font = options.font ?? new Font();
    this.color = options.color ?? this.color;
    this.text = options.text;
    this.maxWidth = options.maxWidth;
  }

  public function clone(): Text {
    return new Text({
      text: this.text.slice(),
      color: this.color?.clone() ?? Color.Black,
      font: this.font.clone(),
      maxWidth: this.maxWidth
    });
  }

  private var _text: String = '';
  public var text(get, set): String;
  function get_text() {
    return this._text;
  }

  function set_text(value: String) {
    this._text = value;
    this._calculateDimension();
  }

  private var _font: Font;
  public var font(get, set): Font;
  function get_font(): Font {
    return this._font;
  }
  function set_font(font: Font) {
    this._font = font;
  }

  private var _textWidth: Int = 0;
  public var width(get, never): Int;
  function get_width() {
    if (this._textWidth == 0) {
      this._calculateDimension();
    }
    return this._textWidth * this.scale.x;
  }

  private var _textHeight: Int = 0;
  public var height(get, never): Int;
  function get_height() {
    if (this._textHeight == 0) {
      this._calculateDimension();
    }
    return this._textHeight * this.scale.y;
  }

  private function _calculateDimension() {
    final size = this.font.measureText(this._text, this.maxWidth);
    this._textWidth = size.width;
    this._textHeight = size.height;
  }

  public var localBounds(get, never): BoundingBox;
  function get_localBounds(): BoundingBox {
    return this.font.measureText(this._text, this.maxWidth).scale(this.scale);
  }

  public override function _rotate(_ex: ExcaliburGraphicsContext) {
    // None this is delegated to font
    // This override erases the default behavior
  }

  public override function _flip(_ex: ExcaliburGraphicsContext) {
    // None this is delegated to font
    // This override erases the default behavior
  }

  public override function _preDraw(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void {
    if (this.isStale() || this.font.isStale()) {
      this.font.flipHorizontal = this.flipHorizontal;
      this.font.flipVertical = this.flipVertical;
      this.font.rotation = this.rotation;
      this.font.origin = this.origin;
      this.font.opacity = this.opacity;
    }
    this.font.tint = this.tint;
    super._preDraw(ex, x, y);
  }

  public override function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int) {
    var color = this.color ?? this.font.color;

    final size = this.font.measureText(this._text, this.maxWidth);
    final width = size.width,
          height = size.height;

    this._textWidth = width;
    this._textHeight = height;

    this.font.render(ex, this._text, color, x, y, this.maxWidth);

    if (this.font.showDebug) {
      ex.debug.drawRect(x - width, y - height, width * 2, height * 2);
      if (this.maxWidth != null) {
        ex.debug.drawRect(x, y, this.maxWidth, this.height, {
          color: Color.Yellow
        });
      }
    }
  }
}
