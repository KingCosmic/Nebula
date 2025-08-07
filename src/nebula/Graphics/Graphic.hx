package nebula.graphics;

import nebula.math.Vector;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.collision.BoundingBox;

import nebula.Color;

import nebula.util.Watch;
import nebula.math.AffineMatrix;

interface IGraphicOptions {
  /**
   * The width of the graphic
   */
  var width: Null<Int>;
  /**
   * The height of the graphic
   */
  var height: Null<Int>;
  /**
   * Should the graphic be flipped horizontally
   */
  var flipHorizontal: Null<Bool>;
  /**
   * Should the graphic be flipped vertically
   */
  var flipVertical: Null<Bool>;
  /**
   * The rotation of the graphic
   */
  var rotation: Null<Float>;
  /**
   * The scale of the graphic
   */
  var scale: Null<Vector>;
  /**
   * The opacity of the graphic between (0 -1)
   */
  var opacity: Null<Float>;
  /**
   * The tint of the graphic, this color will be multiplied by the original pixel colors
   */
  var tint: Null<Color>;
  /**
   * The origin of the drawing in pixels to use when applying transforms, by default it will be the center of the image in pixels
   */
  var origin: Null<Vector>;
}

/**
 * A Graphic is the base Excalibur primitive for something that can be drawn to the {@apilink ExcaliburGraphicsContext}.
 * {@apilink Sprite}, {@apilink Animation}, {@apilink GraphicsGroup}, {@apilink Canvas}, {@apilink Rectangle}, {@apilink Circle}, and {@apilink Polygon} all derive from the
 * {@apilink Graphic} abstract class.
 *
 * Implementors of a Graphic must override the abstract {@apilink Graphic._drawImage} method to render an image to the graphics context. Graphic
 * handles all the position, rotation, and scale transformations in {@apilink Graphic._preDraw} and {@apilink Graphic._postDraw}
 */
abstract class Graphic {
  private static var _ID: Int = 0;
  var id = Graphic._ID++;

  public var transform: AffineMatrix = AffineMatrix.identity();
  public var tint: Null<Color>;

  private var _transformStale = true;
  public function isStale() {
    return this._transformStale;
  }

  /**
   * Gets or sets wether to show debug information about the graphic
   */
  public var showDebug: Bool = false;

  private var _flipHorizontal = false;
  /**
   * Gets or sets the flipHorizontal, which will flip the graphic horizontally (across the y axis)
   */
  public var flipHorizontal(get, set): Bool;
  function get_flipHorizontal(): Bool {
    return this._flipHorizontal;
  }

  function set_flipHorizontal(value: Bool) {
    this._flipHorizontal = value;
    this._transformStale = true;
  }

  private var _flipVertical = false;
  /**
   * Gets or sets the flipVertical, which will flip the graphic vertically (across the x axis)
   */
  public var flipVertical(get, set): Bool;
  function get_flipVertical(): Bool {
    return this._flipVertical;
  }
  function set_flipVertical(value: Bool) {
    this._flipVertical = value;
    this._transformStale = true;
  }

  private var _rotation = 0;
  /**
   * Gets or sets the rotation of the graphic
   */
  public var rotation(get, set): Float;
  function get_rotation(): Float {
    return this._rotation;
  }
  function set_rotation(value: Float) {
    this._rotation = value;
    this._transformStale = true;
  }

  /**
   * Gets or sets the opacity of the graphic, 0 is transparent, 1 is solid (opaque).
   */
  public var opacity: Float = 1;

  private var _scale = Vector.One;
  /**
   * Gets or sets the scale of the graphic, this affects the width and
   */
  public var scale(get, set): Vector;
  function get_scale() {
    return this._scale;
  }
  function set_scale(value: Vector) {
    this._scale = watch(value, () -> {
      this._transformStale = true;
    });
    this._transformStale = true;
  }

  private var _origin: Null<Vector>;
  /**
   * Gets or sets the origin of the graphic, if not set the center of the graphic is the origin
   */
  public var origin(get, set): Null<Vector>;
  function get_origin(): Null<Vector> {
    return this._origin;
  }
  function set_origin(value: Null<Vector>) {
    if (value) {
      this._origin = watch(value, () -> {
        this._transformStale = true;
      });
    }
    this._transformStale = true;
  }

  public function new(?options: GraphicOptions) {
    if (options) {
      this.origin = options.origin ?? this.origin;
      this.flipHorizontal = options.flipHorizontal ?? this.flipHorizontal;
      this.flipVertical = options.flipVertical ?? this.flipVertical;
      this.rotation = options.rotation ?? this.rotation;
      this.opacity = options.opacity ?? this.opacity;
      this.scale = options.scale ?? this.scale;
      this.tint = options.tint ?? this.tint;
      if (options.width) {
        this._width = options.width;
      }

      if (options.height) {
        this._height = options.height;
      }
    }
  }

  public function cloneGraphicOptions(): GraphicOptions {
    return {
      width: this.width / this.scale.x,
      height: this.height / this.scale.y,
      origin: this.origin ? this.origin.clone() : null,
      flipHorizontal: this.flipHorizontal,
      flipVertical: this.flipVertical,
      rotation: this.rotation,
      opacity: this.opacity,
      scale: this.scale ? this.scale.clone() : null,
      tint: this.tint ? this.tint.clone() : null
    };
  }

  private var _width: Int = 0;

  /**
   * Gets or sets the width of the graphic (always positive)
   */
  public var width(get, set): Int;
  function get_width() {
    return Math.abs(this._width * this.scale.x);
  }
  function set_width(value: Int) {
    this._width = value;
    this._transformStale = true;
  }

  private var _height: Int = 0;

  /**
   * Gets or sets the height of the graphic (always positive)
   */
  public var height(get, set): Int;
  function get_height() {
    return Math.abs(this._height * this.scale.y);
  }
  function set_height(value: Int) {
    this._height = value;
    this._transformStale = true;
  }

  /**
   * Gets a copy of the bounds in pixels occupied by the graphic on the the screen. This includes scale.
   */
  public var localBounds(get, never): BoundingBox;
  function get_localBounds(): BoundingBox {
    return BoundingBox.fromDimension(this.width, this.height, Vector.Zero);
  }

  /**
   * Draw the whole graphic to the context including transform
   * @param ex The excalibur graphics context
   * @param x
   * @param y
   */
  public function draw(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void {
    this._preDraw(ex, x, y);
    this._drawImage(ex, 0, 0);
    this._postDraw(ex);
  }

  /**
   * Meant to be overridden by the graphic implementation to draw the underlying image (HTMLCanvasElement or HTMLImageElement)
   * to the graphics context without transform. Transformations like position, rotation, and scale are handled by {@apilink Graphic._preDraw}
   * and {@apilink Graphic._postDraw}
   * @param ex The excalibur graphics context
   * @param x
   * @param y
   */
  private abstract function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void;

  /**
   * Apply affine transformations to the graphics context to manipulate the graphic before {@apilink Graphic._drawImage}
   * @param ex
   * @param x
   * @param y
   */
  private function _preDraw(ex: ExcaliburGraphicsContext, x: Int, y: Int): Void {
    ex.save();
    ex.translate(x, y);
    if (this._transformStale) {
      this.transform.reset();
      this.transform.scale(Math.abs(this.scale.x), Math.abs(this.scale.y));
      this._rotate(this.transform);
      this._flip(this.transform);
      this._transformStale = false;
    }
    ex.multiply(this.transform);
    // it is important to multiply alphas so graphics respect the current context
    ex.opacity = ex.opacity * this.opacity;
    if (this.tint) {
      ex.tint = this.tint;
    }
  }

  private function _rotate(ex: AffineMatrix) {
    final scaleDirX = this.scale.x > 0 ? 1 : -1;
    final scaleDirY = this.scale.y > 0 ? 1 : -1;
    final origin = this.origin ?? vec(this.width / 2, this.height / 2);
    ex.translate(origin.x, origin.y);
    ex.rotate(this.rotation);
    // This is for handling direction changes 1 or -1, that way we don't have mismatched translates()
    ex.scale(scaleDirX, scaleDirY);
    ex.translate(-origin.x, -origin.y);
  }

  private function _flip(ex: AffineMatrix) {
    if (this.flipHorizontal) {
      ex.translate(this.width / this.scale.x, 0);
      ex.scale(-1, 1);
    }

    if (this.flipVertical) {
      ex.translate(0, this.height / this.scale.y);
      ex.scale(1, -1);
    }
  }

  /**
   * Apply any additional work after {@apilink Graphic._drawImage} and restore the context state.
   * @param ex
   */
  private function _postDraw(ex: ExcaliburGraphicsContext): Void {
    if (this.showDebug) {
      ex.debug.drawRect(0, 0, this.width, this.height);
    }
    ex.restore();
  }

  /**
   * Returns a new instance of the graphic that has the same properties
   */
  abstract function clone(): Graphic;
}
