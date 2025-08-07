package nebula.graphics;

import nebula.collision.BoundingBox;

import nebula.Color;

import nebula.util.DrawUtil;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;
import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.graphics.Font;

class FontTextInstance {
  public var canvas: HTMLCanvasElement;
  public var ctx: CanvasRenderingContext2D;
  private var _textFragments: Array<{ x: Int, y: Int, canvas: HTMLCanvasElement }> = [];
  public var dimensions: BoundingBox;
  public var disposed: Bool = false;
  private var _lastHashCode: String;

  public function new(
    font: Font,
    text: String,
    color: Color,
    ?maxWidth: Int
  ) {
    this.canvas = document.createElement('canvas');
    final ctx = this.canvas.getContext('2d');
    if (!ctx) {
      throw new Error('Unable to create FontTextInstance, internal canvas failed to create');
    }
    this.ctx = ctx;
    this.dimensions = this.measureText(text);
    this._setDimension(this.dimensions, this.ctx);
    this._lastHashCode = this.getHashCode();
  }

  function measureText(text: String, ?maxWidth: Int): BoundingBox {
    if (this.disposed) {
      throw Error('Accessing disposed text instance! ' + this.text);
    }
    var lines = null;
    if (maxWidth != null) {
      lines = this._getLinesFromText(text, maxWidth);
    } else {
      lines = text.split('\n');
    }

    final maxWidthLine = lines.reduce((a, b) -> {
      return a.length > b.length ? a : b;
    });

    this._applyFont(this.ctx); // font must be applied to the context to measure it
    final metrics = this.ctx.measureText(maxWidthLine);
    var textHeight = Math.abs(metrics.actualBoundingBoxAscent) + Math.abs(metrics.actualBoundingBoxDescent);

    // TODO line height makes the text bounds wonky
    final lineAdjustedHeight = textHeight * lines.length;
    textHeight = lineAdjustedHeight;
    final bottomBounds = lineAdjustedHeight - Math.abs(metrics.actualBoundingBoxAscent);
    final x = 0;
    final y = 0;
    final measurement = new BoundingBox({
      left: x - Math.abs(metrics.actualBoundingBoxLeft) - this.font.padding,
      top: y - Math.abs(metrics.actualBoundingBoxAscent) - this.font.padding,
      bottom: y + bottomBounds + this.font.padding,
      right: x + Math.abs(metrics.actualBoundingBoxRight) + this.font.padding
    });

    return measurement;
  }

  private function _setDimension(textBounds: BoundingBox, bitmap: CanvasRenderingContext2D) {
    var lineHeightRatio = 1;
    if (this.font.lineHeight) {
      lineHeightRatio = this.font.lineHeight / this.font.size;
    }
    // Changing the width and height clears the context properties
    // We double the bitmap width to account for all possible alignment
    // We scale by "quality" so we render text without jaggies
    bitmap.canvas.width = (textBounds.width + this.font.padding * 2) * 2 * this.font.quality;
    bitmap.canvas.height = (textBounds.height + this.font.padding * 2) * 2 * this.font.quality * lineHeightRatio;
  }

  public static function getHashCode(font: Font, text: String, ?color: Color) {
    final hash =
      text +
      '__hashcode__' +
      font.fontString +
      font.showDebug +
      font.textAlign +
      font.baseAlign +
      font.direction +
      font.lineHeight +
      JSON.stringify(font.shadow) +
      (font.padding.toString() +
        font.smoothing.toString() +
        font.lineWidth.toString() +
        font.lineDash.toString() +
        font.strokeColor?.toString() +
        (color ? color.toString() : font.color.toString()));
    return hash;
  }

  function getHashCode(includeColor: Bool = true) {
    return FontTextInstance.getHashCode(this.font, this.text, includeColor ? this.color : undefined);
  }

  private function _applyRasterProperties(ctx: CanvasRenderingContext2D) {
    ctx.translate(this.font.padding, this.font.padding);
    ctx.imageSmoothingEnabled = this.font.smoothing;
    ctx.lineWidth = this.font.lineWidth;
    ctx.setLineDash(this.font.lineDash ?? ctx.getLineDash());
    ctx.strokeStyle = this.font.strokeColor?.toString() ?? '';
    ctx.fillStyle = this.color.toString();
  }

  private function _applyFont(ctx: CanvasRenderingContext2D) {
    ctx.resetTransform();
    ctx.translate(this.font.padding + ctx.canvas.width / 2, this.font.padding + ctx.canvas.height / 2);
    ctx.scale(this.font.quality, this.font.quality);
    ctx.textAlign = this.font.textAlign;
    ctx.textBaseline = this.font.baseAlign;
    ctx.font = this.font.fontString;
    ctx.direction = this.font.direction;

    if (this.font.shadow) {
      if (this.font.shadow.color) {
        ctx.shadowColor = this.font.shadow.color.toString();
      }
      if (this.font.shadow.blur) {
        ctx.shadowBlur = this.font.shadow.blur;
      }
      if (this.font.shadow.offset) {
        ctx.shadowOffsetX = this.font.shadow.offset.x;
        ctx.shadowOffsetY = this.font.shadow.offset.y;
      }
    }
  }

  private function _drawText(ctx: CanvasRenderingContext2D, lines: Array<String>, lineHeight: Int): Void {
    this._applyRasterProperties(ctx);
    this._applyFont(ctx);

    for (i in 0...lines.length) {
      final line = lines[i];
      if (this.color) {
        ctx.fillText(line, 0, i * lineHeight);
      }

      if (this.font.strokeColor) {
        ctx.strokeText(line, 0, i * lineHeight);
      }
    }

    if (this.font.showDebug) {
      // Horizontal line
      /* istanbul ignore next */
      line(ctx, Color.Green, -ctx.canvas.width / 2, 0, ctx.canvas.width / 2, 0, 2);
      // Vertical line
      /* istanbul ignore next */
      line(ctx, Color.Red, 0, -ctx.canvas.height / 2, 0, ctx.canvas.height / 2, 2);
    }
  }

  private function _splitTextBitmap(bitmap: CanvasRenderingContext2D) {
    final textImages: Array<{ x: Int, y: Int, canvas: HTMLCanvasElement }> = [];
    var currentX = 0;
    var currentY = 0;
    // 4k is the max for mobile devices
    final width = Math.min(4096, bitmap.canvas.width);
    final height = Math.min(4096, bitmap.canvas.height);

    // Splits the original bitmap into 4k max chunks
    while (currentX < bitmap.canvas.width) {
      while (currentY < bitmap.canvas.height) {
        // create new bitmap
        final canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        final ctx = canvas.getContext('2d');
        if (!ctx) {
          throw new Error('Unable to split internal FontTextInstance bitmap, failed to create internal canvas');
        }

        // draw current slice to new bitmap in < 4k chunks
        ctx.drawImage(bitmap.canvas, currentX, currentY, width, height, 0, 0, width, height);

        textImages.push({ x: currentX, y: currentY, canvas: canvas });
        currentY += height;
      }
      currentX += width;
      currentY = 0;
    }
    return textImages;
  }

  public function flagDirty() {
    this._dirty = true;
  }
  private var _dirty = true;
  private var _ex: Null<ExcaliburGraphicsContext>;
  public function render(ex: ExcaliburGraphicsContext, x: Int, y: Int, ?maxWidth: Int) {
    if (this.disposed) {
      throw Error('Accessing disposed text instance! ' + this.text);
    }
    this._ex = ex;
    final hashCode = this.getHashCode();
    if (this._lastHashCode != hashCode) {
      this._dirty = true;
    }

    // Calculate image chunks
    if (this._dirty) {
      this.dimensions = this.measureText(this.text, maxWidth);
      this._setDimension(this.dimensions, this.ctx);
      final lines = this._getLinesFromText(this.text, maxWidth);
      final lineHeight = this.font.lineHeight ?? this.dimensions.height / lines.length;

      // draws the text to the main bitmap
      this._drawText(this.ctx, lines, lineHeight);

      // clear any out old fragments
      if (Std.isOfType(ex, ExcaliburGraphicsContextWebGL)) {
        for (frag in this._textFragments) {
          ex.textureLoader.delete(frag.canvas);
        }
      }

      // splits to < 4k fragments for large text
      this._textFragments = this._splitTextBitmap(this.ctx);

      if (Std.isOfType(ex, ExcaliburGraphicsContextWebGL)) {
        for (frag in this._textFragments) {
          ex.textureLoader.load(frag.canvas, { filtering: this.font.filtering }, true);
        }
      }
      this._lastHashCode = hashCode;
      this._dirty = false;
    }

    // draws the bitmap fragments to excalibur graphics context
    for (frag in this._textFragments) {
      ex.drawImage(
        frag.canvas,
        0,
        0,
        frag.canvas.width,
        frag.canvas.height,
        frag.x / this.font.quality + x - this.ctx.canvas.width / this.font.quality / 2,
        frag.y / this.font.quality + y - this.ctx.canvas.height / this.font.quality / 2,
        frag.canvas.width / this.font.quality,
        frag.canvas.height / this.font.quality
      );
    }
  }

  function dispose() {
    this.disposed = true;
    this.dimensions = null;
    this.canvas = null;
    this.ctx = null;
    if (Std.isOfType(this._ex, ExcaliburGraphicsContextWebGL)) {
      for (frag in this._textFragments) {
        this._ex.textureLoader.delete(frag.canvas);
      }
    }
    this._textFragments.length = 0;
  }

  /**
   * Return array of lines split based on the \n character, and the maxWidth? constraint
   * @param text
   * @param maxWidth
   */
  private var _cachedText: Null<String>;
  private var _cachedLines: Null<Array<String>>;
  private var _cachedRenderWidth: Null<Int>;
  private function _getLinesFromText(text: String, ?maxWidth: Int): Array<String> {
    if (this._cachedText == text && this._cachedRenderWidth == maxWidth && this._cachedLines?.length) {
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
