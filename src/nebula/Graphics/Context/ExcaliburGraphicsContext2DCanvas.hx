package nebula.Graphics.Context;

import nebula.Graphics.Context.ExcaliburGraphicsContext;
import nebula.Graphics.Context.StateStack;
import nebula.Graphics.Context.DebugText;
import nebula.Graphics.Context.Material;

import nebula.Graphics.GraphicsDiagnostics;
import nebula.Graphics.PostProcessor.PostProcessor;

import nebula.Math.Vector;
import nebula.Math.AffineMatrix;

import nebula.Screen;
import nebula.Color;

final pixelSnapEpsilon: Float = 0.0001;

class ExcaliburGraphicsContext2DCanvasDebug implements DebugDraw {
  private _debugText = new DebugText();
  public functiton new(private _ex: ExcaliburGraphicsContext2DCanvas) {}
  /**
   * Draw a debug rectangle to the context
   * @param x
   * @param y
   * @param width
   * @param height
   */
  drawRect(x: Int, y: Int, width: Int, height: Int): Void {
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

  drawLine(start: Vector, end: Vector, lineOptions: LineGraphicsOptions = { color: Color.Black }): Void {
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

  drawPoint(point: Vector, pointOptions: PointGraphicsOptions = { color: Color.Black, size: 5 }): Void {
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

  drawText(text: String, pos: Vector) {
    this._debugText.write(this._ex, text, pos);
  }
}

interface ExcaliburGraphicsContext2DOptions extends ExcaliburGraphicsContextOptions {
  context?: CanvasRenderingContext2D;
}

class ExcaliburGraphicsContext2DCanvas implements ExcaliburGraphicsContext {
  /**
   * Meant for internal use only. Access the internal context at your own risk and no guarantees this will exist in the future.
   * @internal
   */
  public __ctx!: CanvasRenderingContext2D;
  public get width() {
    return this.__ctx.canvas.width;
  }

  public get height() {
    return this.__ctx.canvas.height;
  }

  /**
   * Unused in Canvas implementation
   */
  public readonly useDrawSorting: boolean = false;

  /**
   * Unused in Canvas implementation
   */
  public z: Int = 0;

  public backgroundColor: Color = Color.ExcaliburBlue;

  private _state = new StateStack();

  public get opacity(): Float {
    return this._state.current.opacity;
  }

  public set opacity(value: Float) {
    this._state.current.opacity = value;
  }

  public get tint(): Null<Color> {
    return this._state.current.tint;
  }

  public set tint(color: Null<Color>) {
    this._state.current.tint = color;
  }

  public snapToPixel: Bool = false;

  public get smoothing(): Bool {
    return this.__ctx.imageSmoothingEnabled;
  }

  public set smoothing(value: Bool) {
    this.__ctx.imageSmoothingEnabled = value;
  }

  public function new(options: ExcaliburGraphicsContext2DOptions) {
    final { canvasElement, context, enableTransparency, snapToPixel, antialiasing: smoothing, backgroundColor } = options;
    this.__ctx =
      context ??
      (canvasElement.getContext('2d', {
        alpha: enableTransparency ?? true
      }) as CanvasRenderingContext2D);
    if (!this.__ctx) {
      throw new Error('Cannot build new ExcaliburGraphicsContext2D for some reason!');
    }
    this.backgroundColor = backgroundColor ?? this.backgroundColor;
    this.snapToPixel = snapToPixel ?? this.snapToPixel;
    this.smoothing = smoothing ?? this.smoothing;
  }

  public resetTransform(): Void {
    this.__ctx.resetTransform();
  }

  public updateViewport(_resolution: Resolution): Void {
    // pass
  }

  /**
   * Draw an image to the Excalibur Graphics context at an x and y coordinate using the images width and height
   */
  drawImage(image: HTMLImageSource, x: Int, y: Int): Void;
  /**
   *
   * Draw an image to the Excalibur Graphics context at an x and y coordinate with a specific width and height
   */
  drawImage(image: HTMLImageSource, x: Int, y: Int, width: Int, height: Int): Void;
  /**
   *
   * Draw an image to the Excalibur Graphics context specifying the source image coordinates (sx, sy, swidth, sheight)
   * and to a specific destination on the context (dx, dy, dwidth, dheight)
   */
  drawImage(
    image: HTMLImageSource,
    sx: Int,
    sy: Int,
    swidth?: Int,
    sheight?: Int,
    dx?: Int,
    dy?: Int,
    dwidth?: Int,
    dheight?: Int
  ): Void;

  drawImage(
    image: HTMLImageSource,
    sx: Int,
    sy: Int,
    swidth?: Int,
    sheight?: Int,
    dx?: Int,
    dy?: Int,
    dwidth?: Int,
    dheight?: Int
  ): Void {
    if (swidth === 0 || sheight === 0) {
      return; // zero dimension dest exit early
    } else if (dwidth === 0 || dheight === 0) {
      return; // zero dimension dest exit early
    } else if (image.width === 0 || image.height === 0) {
      return; // zero dimension source exit early
    }

    this.__ctx.globalAlpha = this.opacity;
    final args = [image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight]
      .filter((a) => a !== undefined)
      .map((a) => (typeof a === 'number' && this.snapToPixel ? ~~a : a));
    this.__ctx.drawImage.apply(this.__ctx, args as any);
    GraphicsDiagnostics.DrawCallCount++;
    GraphicsDiagnostics.DrawnImagesCount = 1;
  }

  public drawLine(start: Vector, end: Vector, color: Color, thickness = 1) {
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

  public drawRectangle(pos: Vector, width: Int, height: Int, color: Color) {
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

  public drawCircle(pos: Vector, radius: Float, color: Color, stroke?: Color, thickness?: Int) {
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

  debug = new ExcaliburGraphicsContext2DCanvasDebug(this);

  /**
   * Save the current state of the canvas to the stack (transforms and opacity)
   */
  save(): Void {
    this.__ctx.save();
    this._state.save();
  }

  /**
   * Restore the state of the canvas from the stack
   */
  restore(): Void {
    this.__ctx.restore();
    this._state.restore();
  }

  /**
   * Translate the origin of the context by an x and y
   * @param x
   * @param y
   */
  translate(x: Int, y: Int): Void {
    this.__ctx.translate(this.snapToPixel ? ~~(x + pixelSnapEpsilon) : x, this.snapToPixel ? ~~(y + pixelSnapEpsilon) : y);
  }

  /**
   * Rotate the context about the current origin
   */
  rotate(angle: Int): Void {
    this.__ctx.rotate(angle);
  }

  /**
   * Scale the context by an x and y factor
   * @param x
   * @param y
   */
  scale(x: Float, y: Float): Void {
    this.__ctx.scale(x, y);
  }

  public getTransform(): AffineMatrix {
    throw new Error('Not implemented');
  }

  public multiply(_m: AffineMatrix): Void {
    this.__ctx.setTransform(this.__ctx.getTransform().multiply(_m.toDOMMatrix()));
  }

  public addPostProcessor(_postprocessor: PostProcessor) {
    // pass
  }

  public removePostProcessor(_postprocessor: PostProcessor) {
    // pass
  }

  public clearPostProcessors() {
    // pass
  }

  public updatePostProcessors(elapsed: Int) {
    // pass
  }

  public beginDrawLifecycle() {
    // pass
  }

  public endDrawLifecycle() {
    // pass
  }

  public set material(material: Null<Material>) {
    this._state.current.material = material;
  }

  public get material(): Null<Material> {
    return this._state.current.material;
  }

  public createMaterial(options: Omit<MaterialOptions, 'graphicsContext'>): Material {
    // pass
    return null as dynamic;
  }

  clear(): Void {
    // Clear frame
    this.__ctx.clearRect(0, 0, this.width, this.height);
    this.__ctx.fillStyle = this.backgroundColor.toString();
    this.__ctx.fillRect(0, 0, this.width, this.height);
    GraphicsDiagnostics.clear();
  }

  /**
   * Flushes the batched draw calls to the screen
   */
  flush(): Void {
    // pass
  }

  dispose(): Void {
    this.__ctx = undefined as dynamic;
  }
}
