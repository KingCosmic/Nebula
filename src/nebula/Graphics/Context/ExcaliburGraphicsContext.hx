package nebula.Graphics.Context;

import nebula.Math.Vector;
import nebula.Color;
import nebula.Screen;

import nebula.Graphics.PostProcessor.PostProcessor;

import nebula.Math.AffineMatrix;

import nebula.Graphics.Context.Material;

import nebula.Graphics.Filtering;

type HTMLImageSource = HTMLImageElement | HTMLCanvasElement;

interface AntialiasOptions {
  /**
   * Turns on the special pixel art sampler in excalibur's image shader for sub pixel
   * anti-aliasing
   *
   * Default false
   */
  pixelArtSampler?: Bool;
  /**
   * Configures the webgl's getContext('webgl2', {antialias: true | false}) or configures
   * Canvas2D imageSmoothing = true;
   *
   * **Note** this option is incompatible with `multiSampleAntialiasing`
   *
   * Default false
   */
  nativeContextAntialiasing?: Bool;
  /**
   * Configures the internal render buffer multi-sampling settings
   *
   * Default true, with max samples that the platform supports
   */
  multiSampleAntialiasing?:
    | Bool
    | {
        /**
         * Optionally specify number of samples (will be clamped to the max the platform supports)
         *
         * Default most platforms are 16 samples
         */
        samples: Int;
      };
  /**
   * Sets the default image filtering for excalibur
   *
   * Default {@apilink ImageFiltering.Blended}
   */
  filtering?: ImageFiltering;
  /**
   * Sets the canvas image rendering CSS style
   *
   * Default 'auto'
   */
  canvasImageRendering?: 'pixelated' | 'auto';
}

final DefaultAntialiasOptions: Required<AntialiasOptions> = {
  pixelArtSampler: false,
  nativeContextAntialiasing: false,
  multiSampleAntialiasing: true,
  filtering: ImageFiltering.Blended,
  canvasImageRendering: 'auto'
};

final DefaultPixelArtOptions: Required<AntialiasOptions> = {
  pixelArtSampler: true,
  nativeContextAntialiasing: false,
  multiSampleAntialiasing: true,
  filtering: ImageFiltering.Blended,
  canvasImageRendering: 'auto'
};

interface ExcaliburGraphicsContextOptions {
  /**
   * Target existing html canvas element
   */
  canvasElement: HTMLCanvasElement;
  /**
   * Enables antialiasing on the canvas context (smooths pixels with default canvas sampling)
   */
  antialiasing?: Bool;
  /**
   * Enable the sub pixel antialiasing pixel art sampler for nice looking pixel art
   */
  pixelArtSampler?: Bool;
  /**
   * Enable canvas transparency
   */
  enableTransparency?: Bool;
  /**
   * Enable or disable multi-sample antialiasing in the internal render buffer.
   *
   * If true the max number of samples will be used
   *
   * By default enabled
   */
  multiSampleAntialiasing?:
    | Bool
    | {
        /**
         * Specify number of samples to use during the multi sample anti-alias, if not specified the max will be used.
         * Limited by the hardware (usually 16)
         */
        samples: Int;
      };
  /**
   * UV padding in pixels to use in the internal image rendering
   *
   * Recommended .25 - .5 of a pixel
   */
  uvPadding?: Int;
  /**
   * Hint the power preference to the graphics context
   */
  powerPreference?: 'default' | 'high-performance' | 'low-power';
  /**
   * Snaps the pixel to an integer value (floor)
   */
  snapToPixel?: Bool;
  /**
   * Current clearing color of the context
   */
  backgroundColor?: Color;
  /**
   * Feature flag that enables draw sorting will removed in v0.29
   */
  useDrawSorting?: Bool;
}

interface ExcaliburGraphicsContextState {
  opacity: Float;
  z: Int;
  tint: Null<Color>;
  material: Null<Material>;
}
interface LineGraphicsOptions {
  color?: Color;
}

interface RectGraphicsOptions {
  color?: Color;
}

interface PointGraphicsOptions {
  color: Color;
  size: Int;
}

interface DebugDraw {
  /**
   * Draw a debugging rectangle to the screen
   * @param x
   * @param y
   * @param width
   * @param height
   * @param rectOptions
   */
  drawRect(x: Int, y: Int, width: Int, height: Int, rectOptions?: RectGraphicsOptions): Void;
  /**
   * Draw a debugging line to the screen
   * @param start '
   * @param end
   * @param lineOptions
   */
  drawLine(start: Vector, end: Vector, lineOptions?: LineGraphicsOptions): Void;
  /**
   * Draw a debugging point to the screen
   * @param point
   * @param pointOptions
   */
  drawPoint(point: Vector, pointOptions?: PointGraphicsOptions): Void;

  /**
   * Draw debug text
   * @param text
   * @param pos
   */
  drawText(text: String, pos: Vector): Void;
}

interface ExcaliburGraphicsContext {
  width: Int;
  height: Int;

  /**
   * Excalibur will automatically sort draw calls by z and priority for maximal draw performance,
   * this can disrupt a specific desired painter order.
   *
   * To force a specific draw call order, use {@apilink ExcaliburGraphicsContext.z}
   *
   * By default `useDrawSorting` is `true`, to opt out set this to `false`
   */
  useDrawSorting: Bool;

  /**
   * Set the current z context for the graphics context. Draw calls issued to the context will use this z
   * to inform their sort order.
   *
   * Note it is important to all {@apilink ExcaliburGraphicsContext.save} and {@apilink ExcaliburGraphicsContext.restore} when modifying state.
   */
  z: Int;

  /**
   * Snaps all drawings to the nearest pixel truncated down, by default false
   */
  snapToPixel: Bool;

  /**
   * Enable smoothed drawing (also known as anti-aliasing), by default true
   */
  smoothing: Bool;

  /**
   * Set the background color of the graphics context, default is {@apilink Color.ExcaliburBlue}
   */
  backgroundColor: Color;

  /**
   * Sets the opacity of the current {@apilink Graphic} being drawn, default is 1
   */
  opacity: Float;

  /**
   * Sets the tint color to be multiplied by any images drawn, default is black 0xFFFFFFFF
   */
  tint: Null<Color>;

  /**
   * Resets the current transform to the identity matrix
   */
  resetTransform(): Void;

  /**
   * Gets the current transform
   */
  getTransform(): AffineMatrix;

  /**
   * Multiplies the current transform by a matrix
   * @param m
   */
  multiply(m: AffineMatrix): Void;

  /**
   * Update the context with the current viewport dimensions (used in resizing)
   */
  updateViewport(resolution: Resolution): Void;

  /**
   * Access the debug drawing api
   */
  debug: DebugDraw;

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

  /**
   * Draw a solid line to the Excalibur Graphics context
   * @param start
   * @param end
   * @param color
   * @param thickness
   */
  drawLine(start: Vector, end: Vector, color: Color, thickness: Int): Void;

  /**
   * Draw a solid rectangle to the Excalibur Graphics context
   * @param pos
   * @param width
   * @param height
   * @param color
   */
  drawRectangle(pos: Vector, width: Int, height: Int, color: Color, stroke?: Color, strokeThickness?: Int): Void;

  /**
   * Draw a circle to the Excalibur Graphics context
   * @param pos
   * @param radius
   * @param color
   * @param stroke Optionally specify the stroke color
   * @param thickness
   */
  drawCircle(pos: Vector, radius: Float, color: Color, stroke?: Color, thickness?: Int): Void;

  /**
   * Save the current state of the canvas to the stack (transforms and opacity)
   */
  save(): Void;

  /**
   * Restore the state of the canvas from the stack
   */
  restore(): Void;

  /**
   * Translate the origin of the context by an x and y
   * @param x
   * @param y
   */
  translate(x: Int, y: Int): Void;

  /**
   * Rotate the context about the current origin
   */
  rotate(angle: Float): Void;

  /**
   * Scale the context by an x and y factor
   * @param x
   * @param y
   */
  scale(x: Float, y: Float): Void;

  /**
   * Add a post processor to the graphics context
   *
   * Post processors are run in the order they were added.
   * @param postprocessor
   */
  addPostProcessor(postprocessor: PostProcessor): Void;

  /**
   * Remove a specific post processor from the graphics context
   * @param postprocessor
   */
  removePostProcessor(postprocessor: PostProcessor): Void;

  /**
   * Remove all post processors from the graphics context
   */
  clearPostProcessors(): Void;

  /**
   * Updates all post processors in the graphics context
   *
   * Called internally by Excalibur
   * @param elapsed
   * @internal
   */
  updatePostProcessors(elapsed: Int): Void;

  /**
   * Gets or sets the material to be used in the current context's drawings
   *
   * This allows customs shaders to be used but draw calls are no longer batched by default.
   * @param material
   */
  material: Null<Material>;

  /**
   * Creates and initializes the material which compiles the internal shader
   * @param options
   * @returns
   */
  createMaterial(options: Omit<MaterialOptions, 'graphicsContext'>): Material;

  /**
   * Clears the screen with the current background color
   */
  clear(): Void;

  /**
   * Flushes the batched draw calls to the screen
   */
  flush(): Void;

  beginDrawLifecycle(): Void;

  endDrawLifecycle(): Void;

  dispose(): Void;
}
