package nebula.graphics.context;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.graphics.ImageSource;
import nebula.graphics.SpriteFont;
import nebula.graphics.SpriteSheet;

import nebula.math.Vector;

// import debugFont from './debug-font.png';

/**
 * Internal debug text helper
 */
class DebugText {
  public function new() {
    // We fire and forget, we don't care if it's loaded or not
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    this.load();
  }

  /**
   * base64 font
   */
  public var fontSheet = debugFont;
  public var size: Int = 16;
  private var _imageSource: ImageSource;
  private var _spriteSheet: SpriteSheet;
  private var _spriteFont: SpriteFont;
  public function load() {
    this._imageSource = new ImageSource(this.fontSheet);
    return this._imageSource.load().then(() -> {
      this._spriteSheet = SpriteSheet.fromImageSource({
        image: this._imageSource,
        grid: {
          rows: 4,
          columns: 16,
          spriteWidth: 16,
          spriteHeight: 16
        }
      });
      this._spriteFont = new SpriteFont({
        alphabet: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ,!\'&."?-()+# ',
        caseInsensitive: true,
        spriteSheet: this._spriteSheet,
        spacing: -6
      });
    });
  }

  /**
   * Writes debug text using the built in sprint font
   * @param ctx
   * @param text
   * @param pos
   */
  public function write(ctx: ExcaliburGraphicsContext, text: String, pos: Vector) {
    if (this._imageSource.isLoaded()) {
      this._spriteFont.render(ctx, text, null, pos.x, pos.y);
    }
  }
}
