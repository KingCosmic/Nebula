package nebula;

import nebula.Engine;
import nebula.Color;
import nebula.Math.Vector;
import nebula.Graphics.Text;
import nebula.Graphics;
import nebula.Graphics.Font;
import nebula.Actor;

/**
 * Option for creating a label
 */
interface LabelOptions {
  /**
   * Specify the label text
   */
  var text: Null<String>;

  /**
   * Specify a max width for the text in pixels, if specified the text will wrap.
   *
   * **Not supported in SpriteFont**
   */
  var maxWidth: Null<Int>;
  /**
   * Specify the color of the text (does not apply to SpriteFonts)
   */
  var color: Null<Color>;
  var x: Null<Float>;
  var y: Null<Float>;
  var pos: Null<Vector>;
  /**
   * Optionally specify a sprite font, will take precedence over any other {@apilink Font}
   */
  var spriteFont: Null<SpriteFont>;
  /**
   * Specify a custom font
   */
  var font: Null<Font>;
}

/**
 * Labels are the way to draw small amounts of text to the screen. They are
 * actors and inherit all of the benefits and capabilities.
 */
class Label extends Actor {
  private var _font: Font = new Font();
  private var _text: Text = new Text({ text: '', font: this._font });

  public var maxWidth(get, set): Int;
  function get_maxWidth(): Null<Int> {
    return this._text.maxWidth;
  }
  function set_maxWidth(width: Null<Int>) {
    this._text.maxWidth = width;
  }

  public var font(get, set): Font;
  function get_font(): Font {
    return this._font;
  }
  function set_font(newFont: Font) {
    this._font = newFont;
    this._text.font = newFont;
  }

  /**
   * The text to draw.
   */
  public var text(get, set): String;
  function get_text(): String {
    return this._text.text;
  }
  function set_text(text: String) {
    this._text.text = text;
  }

  override function get_color(): Color {
    return this._text.color;
  }

  override function set_color(color: Color) {
    if (this._text) {
      this._text.color = color;
    }
  }

  public var opacity(get, set): Float;
  function get_opacity(): Float {
    return this.graphics.opacity;
  }
  function set_opacity(opacity: Float) {
    this.graphics.opacity = opacity;
  }

  private var _spriteFont: SpriteFont;
  /**
   * The {@apilink SpriteFont} to use, if any. Overrides {@apilink Font | `font`} if present.
   */
  public var spriteFont(get, set): SpriteFont;
  function get_spriteFont(): SpriteFont {
    return this._spriteFont;
  }
  function set_spriteFont(sf: SpriteFont) {
    this._spriteFont = sf;
    this._text.font = this._spriteFont;
  }

  /**
   * Build a new label
   * @param options
   */
  public function new(?options: LabelOptions & ActorArgs) {
    super(options);

    var mOptions = Object.spreadWith({ text: '' }, options);
    final text = mOptions.text, pos = mOptions.pos, x = mOptions.x, y = mOptions.y,
          font = mOptions.font, color = mOptions.color, maxWidth = mOptions.maxWidth;

    this.pos = pos ?? (x && y ? vec(x, y) : this.pos);
    this.text = text ?? this.text;
    this.font = font ?? this.font;
    this.maxWidth = maxWidth ?? this.maxWidth;
    this.spriteFont = spriteFont ?? this.spriteFont;
    this._text.color = color ?? this.color;
    final gfx = this.get(GraphicsComponent);
    gfx.anchor = Vector.Zero;
    gfx.use(this._text);
  }

  public function _initialize(engine: Engine) {
    super._initialize(engine);
  }

  /**
   * Returns the width of the text in the label (in pixels);
   */
  public function getTextWidth(): Int {
    return this._text.width;
  }
}
