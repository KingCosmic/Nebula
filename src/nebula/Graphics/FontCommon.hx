package nebula.graphics;

import nebula.collision.BoundingBox;

import nebula.Color;

import nebula.math.Vector;

import nebula.graphics.context.ExcaliburGraphicsContext;

/**
 * Enum representing the different font size units
 * https://developer.mozilla.org/en-US/docs/Web/CSS/font-size
 */
enum FontUnit {
  /**
   * Em is a scalable unit, 1 em is equal to the current font size of the current element, parent elements can effect em values
   */
  Em;
  /**
   * Rem is similar to the Em, it is a scalable unit. 1 rem is equal to the font size of the root element
   */
  Rem;
  /**
   * Pixel is a unit of length in screen pixels
   */
  Px;
  /**
   * Point is a physical unit length (1/72 of an inch)
   */
  Pt;
  /**
   * Percent is a scalable unit similar to Em, the only difference is the Em units scale faster when Text-Size stuff
   */
  Percent;
}

/**
 * Enum representing the different horizontal text alignments
 */
enum TextAlign {
  /**
   * The text is left-aligned.
   */
  Left;
  /**
   * The text is right-aligned.
   */
  Right;
  /**
   * The text is centered.
   */
  Center;
  /**
   * The text is aligned at the normal start of the line (left-aligned for left-to-right locales,
   * right-aligned for right-to-left locales).
   */
  Start;
  /**
   * The text is aligned at the normal end of the line (right-aligned for left-to-right locales,
   * left-aligned for right-to-left locales).
   */
  End;
}

/**
 * Enum representing the different baseline text alignments
 */
enum BaseAlign {
  /**
   * The text baseline is the top of the em square.
   */
  Top;
  /**
   * The text baseline is the hanging baseline.  Currently unsupported; this will act like
   * alphabetic.
   */
  Hanging;
  /**
   * The text baseline is the middle of the em square.
   */
  Middle;
  /**
   * The text baseline is the normal alphabetic baseline.
   */
  Alphabetic;
  /**
   * The text baseline is the ideographic baseline; this is the bottom of
   * the body of the characters, if the main body of characters protrudes
   * beneath the alphabetic baseline.  Currently unsupported; this will
   * act like alphabetic.
   */
  Ideographic;
  /**
   * The text baseline is the bottom of the bounding box.  This differs
   * from the ideographic baseline in that the ideographic baseline
   * doesn't consider descenders.
   */
  Bottom;
}

/**
 * Enum representing the different possible font styles
 */
enum FontStyle {
  Normal;
  Italic;
  Oblique;
}

/**
 * Enum representing the text direction, useful for other languages, or writing text in reverse
 */
enum Direction {
  LeftToRight;
  RightToLeft;
}

/**
 * Font rendering option
 */
interface FontOptions {
  /**
   * Optionally the size of the font in the specified {@apilink FontUnit} by default 10.
   */
  var size: Null<Int>;
  /**
   * Optionally specify unit to measure fonts in, by default Pixels
   */
  var unit: Null<FontUnit>;
  /**
   * Optionally specify the font family, by default 'sans-serif'
   */
  var family: Null<String>;
  /**
   * Optionally specify the font style, by default Normal
   */
  var style: Null<FontStyle>;
  /**
   * Optionally set whether the font is bold, by default false
   */
  var bold: Null<Bool>;
  /**
   * Optionally specify the text align, by default Left
   */
  var textAlign: Null<TextAlign>;
  /**
   * Optionally specify the text base align, by default Alphabetic
   */
  var baseAlign: Null<BaseAlign>;
  /**
   * Optionally specify the text direction, by default LeftToRight
   */
  var direction: Null<Direction>;
  /**
   * Optionally override the text line height in pixels, useful for multiline text. If unset will use default.
   */
  var lineHeight: Null<Int>;
  /**
   * Optionally specify the quality of the text bitmap, it is a multiplier on the size size, by default 2.
   * Higher quality text has a higher memory impact
   */
  var quality: Null<Int>;
  /**
   * Optionally specify a text shadow, by default none is specified
   */
  var shadow: Null<{
    blur: Null<Int>,
    offset: Null<Vector>,
    color: Null<Color>,
  }>;
}

/**
 * @internal
 */
interface FontRenderer {
  function measureText(text: String): BoundingBox;
  function render(ex: ExcaliburGraphicsContext, text: String, color: Color, x: Int, y: Int): Void;
}
