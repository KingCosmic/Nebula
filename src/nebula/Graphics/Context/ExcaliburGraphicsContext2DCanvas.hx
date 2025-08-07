package nebula.graphics.context;

import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.graphics.context.StateStack;
import nebula.graphics.context.DebugText;
import nebula.graphics.context.Material;

import nebula.graphics.GraphicsDiagnostics;
import nebula.graphics.postprocessor.PostProcessor;

import nebula.math.Vector;
import nebula.math.AffineMatrix;

import nebula.Screen;
import nebula.Color;

final pixelSnapEpsilon: Float = 0.0001;

class ExcaliburGraphicsContext2DCanvasDebug implements DebugDraw {
  private var _debugText = new DebugText();
  public function new(_ex: ExcaliburGraphicsContext2DCanvas) {}
  /**
   * Draw a debug rectangle to the context
   * @param x
   * @param y
   * @param width
   * @param height
   */
  function drawRect(x: Int, y: Int, width: Int, height: Int): Void {
    this._ex.__ctx.save();
    this._ex.__ctx.strokeStyle = 'red';
    this._ex.__ctx.strokeRect(
      this._ex.snapToPixel ? ~~(x + pixelSnapEpsilon) : x,
      this._ex.snapToPixel ? ~~(y + pixelSnapEpsilon) : y,
      this._ex.snapToPixel ? ~~(width + pixelSnapEpsilon) : width,
      this._ex.snapToPixel ? ~~(height + pixelSnapEpsilon) : height
    );
    this._ex.__ctx.restore();
  }

  function drawLine(start: Vector, end: Vector, lineOptions: LineGraphicsOptions = { color: Color.Black }): Void {
    this._ex.__ctx.save();
    this._ex.__ctx.beginPath();
    this._ex.__ctx.strokeStyle = lineOptions.color?.toString() ?? '';
    this._ex.__ctx.moveTo(
      this._ex.snapToPixel ? ~~(start.x + pixelSnapEpsilon) : start.x,
      this._ex.snapToPixel ? ~~(start.y + pixelSnapEpsilon) : start.y
    );
    this._ex.__ctx.lineTo(
      this._ex.snapToPixel ? ~~(end.x + pixelSnapEpsilon) : end.x,
      this._ex.snapToPixel ? ~~(end.y + pixelSnapEpsilon) : end.y
    );
    this._ex.__ctx.lineWidth = 2;
    this._ex.__ctx.stroke();
    this._ex.__ctx.closePath();
    this._ex.__ctx.restore();
  }

  function drawPoint(point: Vector, pointOptions: PointGraphicsOptions = { color: Color.Black, size: 5 }): Void {
    this._ex.__ctx.save();
    this._ex.__ctx.beginPath();
    this._ex.__ctx.fillStyle = pointOptions.color.toString();
    this._ex.__ctx.arc(
      this._ex.snapToPixel ? ~~(point.x + pixelSnapEpsilon) : point.x,
      this._ex.snapToPixel ? ~~(point.y + pixelSnapEpsilon) : point.y,
      pointOptions.size,
      0,
      Math.PI * 2
    );
    this._ex.__ctx.fill();
    this._ex.__ctx.closePath();
    this._ex.__ctx.restore();
  }

  function drawText(text: String, pos: Vector) {
    this._debugText.write(this._ex, text, pos);
  }
}

interface ExcaliburGraphicsContext2DOptions extends ExcaliburGraphicsContextOptions {
  var context: Null<CanvasRenderingContext2D>;
}

class ExcaliburGraphicsContext2DCanvas implements ExcaliburGraphicsContext {
  /**
   * Meant for internal use only. Access the internal context at your own risk and no guarantees this will exist in the future.
   * @internal
   */
  public var __ctx: CanvasRenderingContext2D;
  public var width(get, never): Int;
  function get_width() {
    return this.__ctx.canvas.width;
  }

  public var height(get, never): Int;
  function get_height() {
    return this.__ctx.canvas.height;
  }

  /**
   * Unused in Canvas implementation
   */
  public var useDrawSorting: Bool = false;

  /**
   * Unused in Canvas implementation
   */
  public var z: Int = 0;

  public var backgroundColor: Color = Color.ExcaliburBlue;

  private var _state = new StateStack();

  public var opacity(get, set): Float;
  function get_opacity(): Float {
    return this._state.current.opacity;
  }

  function set_opacity(value: Float) {
    this._state.current.opacity = value;
  }

  public var tint(get, set): Null<Color>;
  function get_tint(): Null<Color> {
    return this._state.current.tint;
  }
  function set_tint(color: Null<Color>) {
    this._state.current.tint = color;
  }

  public var snapToPixel: Bool = false;

  public var smoothing(get, set): Bool;
  function get_smoothing(): Bool {
    return this.__ctx.imageSmoothingEnabled;
  }
  function set_smoothing(value: Bool) {
    this.__ctx.imageSmoothingEnabled = value;
  }

  public function new(options: ExcaliburGraphicsContext2DOptions) {
    final canvasElement = options.canvasElement,
          context = options.context,
          enableTransparency = options.enableTransparency,
          snapToPixel = options.snapToPixel,
          smoothing = options.antialiasing,
          backgroundColor = options.backgroundColor;
    this.__ctx =
      context ??
      (canvasElement.getContext('2d', {
        alpha: enableTransparency ?? true
      }));
    if (!this.__ctx) {
      throw new Error('Cannot build new ExcaliburGraphicsContext2D for some reason!');
    }
    this.backgroundColor = backgroundColor ?? this.backgroundColor;
    this.snapToPixel = snapToPixel ?? this.snapToPixel;
    this.smoothing = smoothing ?? this.smoothing;
  }

  public function resetTransform(): Void {
    this.__ctx.resetTransform();
  }

  public function updateViewport(_resolution: Resolution): Void {
    // pass
  }

  /**
   * Draw an image to the Excalibur Graphics context at an x and y coordinate using the images width and height
   */
  function drawImage(image: HTMLImageSource, x: Int, y: Int): Void;
  /**
   *
   * Draw an image to the Excalibur Graphics context at an x and y coordinate with a specific width and height
   */
  function drawImage(image: HTMLImageSource, x: Int, y: Int, width: Int, height: Int): Void;
  /**
   *
   * Draw an image to the Excalibur Graphics context specifying the source image coordinates (sx, sy, swidth, sheight)
   * and to a specific destination on the context (dx, dy, dwidth, dheight)
   */
  function drawImage(
    image: HTMLImageSource,
    sx: Int,
    sy: Int,
    ?swidth: Int,
    ?sheight: Int,
    ?dx: Int,
    ?dy: Int,
    ?dwidth: Int,
    ?dheight: Int
  ): Void;

  function drawImage(
    image: HTMLImageSource,
    sx: Int,
    sy: Int,
    ?swidth: Int,
    ?sheight: Int,
    ?dx: Int,
    ?dy: Int,
    ?dwidth: Int,
    ?dheight: Int
  ): Void {
    if (swidth == 0 || sheight == 0) {
      return; // zero dimension dest exit early
    } else if (dwidth == 0 || dheight == 0) {
      return; // zero dimension dest exit early
    } else if (image.width == 0 || image.height == 0) {
      return; // zero dimension source exit early
    }

    this.__ctx.globalAlpha = this.opacity;
    final args = [image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight]
      .filter((a) -> a != null)
      .map((a) -> (Std.isTypeOf(a, Int) && this.snapToPixel ? ~~a : a));
    this.__ctx.drawImage.apply(this.__ctx, args);
    GraphicsDiagnostics.DrawCallCount++;
    GraphicsDiagnostics.DrawnImagesCount = 1;
  }

  public function drawLine(start: Vector, end: Vector, color: Color, thickness = 1) {
    this.__ctx.save();
    this.__ctx.beginPath();
    this.__ctx.strokeStyle = color.toString();
    this.__ctx.moveTo(
      this.snapToPixel ? ~~(start.x + pixelSnapEpsilon) : start.x,
      this.snapToPixel ? ~~(start.y + pixelSnapEpsilon) : start.y
    );
    this.__ctx.lineTo(this.snapToPixel ? ~~(end.x + pixelSnapEpsilon) : end.x, this.snapToPixel ? ~~(end.y + pixelSnapEpsilon) : end.y);
    this.__ctx.lineWidth = thickness;
    this.__ctx.stroke();
    this.__ctx.closePath();
    this.__ctx.restore();
  }

  public function drawRectangle(pos: Vector, width: Int, height: Int, color: Color) {
    this.__ctx.save();
    this.__ctx.fillStyle = color.toString();
    this.__ctx.fillRect(
      this.snapToPixel ? ~~(pos.x + pixelSnapEpsilon) : pos.x,
      this.snapToPixel ? ~~(pos.y + pixelSnapEpsilon) : pos.y,
      this.snapToPixel ? ~~(width + pixelSnapEpsilon) : width,
      this.snapToPixel ? ~~(height + pixelSnapEpsilon) : height
    );
    this.__ctx.restore();
  }

  public function drawCircle(pos: Vector, radius: Float, color: Color, ?stroke: Color, ?thickness: Int) {
    this.__ctx.save();
    this.__ctx.beginPath();
    if (stroke) {
      this.__ctx.strokeStyle = stroke.toString();
    }
    if (thickness) {
      this.__ctx.lineWidth = thickness;
    }
    this.__ctx.fillStyle = color.toString();
    this.__ctx.arc(
      this.snapToPixel ? ~~(pos.x + pixelSnapEpsilon) : pos.x,
      this.snapToPixel ? ~~(pos.y + pixelSnapEpsilon) : pos.y,
      radius,
      0,
      Math.PI * 2
    );
    this.__ctx.fill();
    if (stroke) {
      this.__ctx.stroke();
    }
    this.__ctx.closePath();
    this.__ctx.restore();
  }

  var debug = new ExcaliburGraphicsContext2DCanvasDebug(this);

  /**
   * Save the current state of the canvas to the stack (transforms and opacity)
   */
  function save(): Void {
    this.__ctx.save();
    this._state.save();
  }

  /**
   * Restore the state of the canvas from the stack
   */
  function restore(): Void {
    this.__ctx.restore();
    this._state.restore();
  }

  /**
   * Translate the origin of the context by an x and y
   * @param x
   * @param y
   */
  function translate(x: Int, y: Int): Void {
    this.__ctx.translate(this.snapToPixel ? ~~(x + pixelSnapEpsilon) : x, this.snapToPixel ? ~~(y + pixelSnapEpsilon) : y);
  }

  /**
   * Rotate the context about the current origin
   */
  function rotate(angle: Int): Void {
    this.__ctx.rotate(angle);
  }

  /**
   * Scale the context by an x and y factor
   * @param x
   * @param y
   */
  function scale(x: Float, y: Float): Void {
    this.__ctx.scale(x, y);
  }

  public function getTransform(): AffineMatrix {
    throw new Error('Not implemented');
  }

  public function multiply(_m: AffineMatrix): Void {
    this.__ctx.setTransform(this.__ctx.getTransform().multiply(_m.toDOMMatrix()));
  }

  public function addPostProcessor(_postprocessor: PostProcessor) {
    // pass
  }

  public function removePostProcessor(_postprocessor: PostProcessor) {
    // pass
  }

  public function clearPostProcessors() {
    // pass
  }

  public function updatePostProcessors(elapsed: Int) {
    // pass
  }

  public function beginDrawLifecycle() {
    // pass
  }

  public function endDrawLifecycle() {
    // pass
  }

  public var material(get, set): Null<Material>;
  function set_material(material: Null<Material>) {
    this._state.current.material = material;
  }
  function get_material(): Null<Material> {
    return this._state.current.material;
  }

  public function createMaterial(options: Omit<MaterialOptions, 'graphicsContext'>): Null<Material> {
    // pass
    return null;
  }

  function clear(): Void {
    // Clear frame
    this.__ctx.clearRect(0, 0, this.width, this.height);
    this.__ctx.fillStyle = this.backgroundColor.toString();
    this.__ctx.fillRect(0, 0, this.width, this.height);
    GraphicsDiagnostics.clear();
  }

  /**
   * Flushes the batched draw calls to the screen
   */
  function flush(): Void {
    // pass
  }

  function dispose(): Void {
    this.__ctx = null;
  }
}
