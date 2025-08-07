package nebula.graphics;

import nebula.math.Vector;
import nebula.util.Log;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.graphics.FontCommon;
import nebula.graphics.Graphic;
import nebula.graphics.Sprite;
import nebula.graphics.SpriteSheet;

import nebula.collision.BoundingBox;

interface SpriteFontOptions {
  /**
   * Alphabet string in spritesheet order (default is row column order)
   * example: 'abcdefghijklmnopqrstuvwxyz'
   */
  var alphabet: String;
  /**
   * {@apilink SpriteSheet} to source character sprites from
   */
  var spriteSheet: SpriteSheet;
  /**
   * Optionally ignore case in the supplied text;
   */
  var caseInsensitive: Null<Bool>;
  /**
   * Optionally override the text line height, useful for multiline text. If unset will use default.
   */
  var lineHeight: Null<Int>;
  /**
   * Optionally adjust the spacing between character sprites
   */
  var spacing: Null<Int>;
  /**
   * Optionally specify a "shadow"
   */
  var shadow: Null<{ offset: Vector }>;
}

class SpriteFont extends Graphic implements FontRenderer {
  private var _text: String = '';
  public var alphabet: String = '';
  public var spriteSheet: SpriteSheet;

  public var shadow: Null<{ offset: Vector }> = null;
  public var caseInsensitive: Bool = false;
  public var spacing: Int = 0;
  public var lineHeight: Null<Int> = null;

  private var _logger = Logger.getInstance();

  public function new(options: SpriteFontOptions & GraphicOptions) {
    super(options);
    final alphabet = options.alphabet,
          spriteSheet = options.spriteSheet,
          caseInsensitive = options.caseInsensitive,
          spacing = options.spacing,
          shadow = options.shadow,
          lineHeight = options.lineHeight;

    this.alphabet = alphabet;
    this.spriteSheet = spriteSheet;
    this.caseInsensitive = caseInsensitive ?? this.caseInsensitive;
    this.spacing = spacing ?? this.spacing;
    this.shadow = shadow ?? this.shadow;
    this.lineHeight = lineHeight ?? this.lineHeight;
  }

  private function _getCharacterSprites(text: String): Array<Sprite> {
    final results: Array<Sprite> = [];
    // handle case insensitive
    final textToRender = this.caseInsensitive ? text.toLocaleLowerCase() : text;
    final alphabet = this.caseInsensitive ? this.alphabet.toLocaleLowerCase() : this.alphabet;

    // for each letter in text
    for (letter in textToRender) {
      // find the sprite index in alphabet , if there is an error pick the first
      var spriteIndex = alphabet.indexOf(letter);
      if (spriteIndex == -1) {
        spriteIndex = 0;
        this._logger.warnOnce('SpriteFont - Cannot find letter \'${letter}\' in configured alphabet \'${alphabet}\'.');
        this._logger.warnOnce('There maybe be more issues in the SpriteFont configuration. No additional warnings will be logged.');
      }

      final letterSprite = this.spriteSheet.sprites[spriteIndex];
      if (letterSprite) {
        results.push(letterSprite);
      } else {
        this._logger.warnOnce("SpriteFont - Cannot find sprite for '${letter}' at index '${spriteIndex}' in configured SpriteSheet");
        this._logger.warnOnce('There maybe be more issues in the SpriteFont configuration. No additional warnings will be logged.');
      }
    }
    return results;
  }

  public function measureText(text: String, ?maxWidth: Int): BoundingBox {
    final lines = this._getLinesFromText(text, maxWidth);
    final maxWidthLine = lines.reduce((a, b) -> {
      return a.length > b.length ? a : b;
    });
    final sprites = this._getCharacterSprites(maxWidthLine);
    var width = 0;
    var height = 0;
    for (sprite in sprites) {
      width += sprite.width + this.spacing;
      height = Math.max(height, sprite.height);
    }
    return BoundingBox.fromDimension(width * this.scale.x, height * lines.length * this.scale.y, Vector.Zero);
  }

  function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int, ?maxWidth: Int): Void {
    var xCursor = 0;
    var yCursor = 0;
    var height = 0;
    final lines = this._getLinesFromText(this._text, maxWidth);
    for (line in lines) {
      for (sprite in this._getCharacterSprites(line)) {
        // draw it in the right spot and increase the cursor by sprite width
        sprite.draw(ex, x + xCursor, y + yCursor);
        xCursor += sprite.width + this.spacing;
        height = Math.max(height, sprite.height);
      }
      xCursor = 0;
      yCursor += this.lineHeight ?? height;
    }
  }

  function render(ex: ExcaliburGraphicsContext, text: String, _color: Color, x: Int, y: Int, ?maxWidth: Int) {
    // SpriteFont doesn't support _color, yet...
    this._text = text;
    final bounds = this.measureText(text, maxWidth);
    this.width = bounds.width;
    this.height = bounds.height;
    if (this.shadow) {
      ex.save();
      ex.translate(this.shadow.offset.x, this.shadow.offset.y);
      this._preDraw(ex, x, y);
      this._drawImage(ex, 0, 0, maxWidth);
      this._postDraw(ex);
      ex.restore();
    }

    this._preDraw(ex, x, y);
    this._drawImage(ex, 0, 0, maxWidth);
    this._postDraw(ex);
  }

  function clone(): SpriteFont {
    return new SpriteFont({
      alphabet: this.alphabet,
      spriteSheet: this.spriteSheet,
      spacing: this.spacing
    });
  }

  /**
   * Return array of lines split based on the \n character, and the maxWidth? constraint
   * @param text
   * @param maxWidth
   */
  private var _cachedText: Null<String>;
  private var _cachedLines: Null<Array<String>>;
  private var _cachedRenderWidth: Null<Int>;
  private function _getLinesFromText(text: String, ?maxWidth: Int) {
    if (this._cachedText == text && this._cachedRenderWidth == maxWidth && this._cachedLines.length) {
      return this._cachedLines;
    }

    final lines = text.split('\n');

    if (maxWidth == null) {
      return lines;
    }

    // If the current line goes past the maxWidth, append a new line without modifying the underlying text.
    for (i in 0...lines.length) {
      var line = lines[i];
      var newLine = '';
      // Note: we subtract the spacing to counter the initial padding on the left side.
      if (this.measureText(line).width > maxWidth) {
        while (this.measureText(line).width > maxWidth) {
          newLine = line[line.length - 1] + newLine;
          line = line.slice(0, -1); // Remove last character from line
        }

        // Update the array with our new values
        lines[i] = line;
        lines[i + 1] = newLine;
      }
    }

    this._cachedText = text;
    this._cachedLines = lines;
    this._cachedRenderWidth = maxWidth;

    return lines;
  }
}
