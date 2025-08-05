package nebula.Graphics.Context;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

import nebula.Math.Matrix;
import nebula.Math.Vector;

import nebula.Graphics.Context.TransformStack;
import nebula.Graphics.Context.StateStack;
import nebula.Graphics.Context.DebugStack;
import nebula.Graphics.Context.RenderTarget;
import nebula.Graphics.Context.TextureLoader;
import nebula.Graphics.Context.Renderer;

import nebula.Graphics.PostProcessor.PostProcessor;

import nebula.Screen;

import nebula.Util.Log;

import nebula.Color;

import nebula.Graphics.Context.LineRenderer.LineRenderer;
import nebula.Graphics.Context.PointRenderer.PointRenderer;
import nebula.Graphics.Context.ScreenPassPainter.ScreenPassPainter;
import nebula.Graphics.Context.ImageRenderer.ImageRenderer;
import nebula.Graphics.Context.RectangleRenderer.RectangleRenderer;
import nebula.Graphics.Context.CircleRenderer.CircleRenderer;
import nebula.Graphics.Context.MaterialRenderer.MaterialRenderer;
import nebula.Graphics.Context.ParticleRenderer.ParticalRenderer;
import nebula.Graphics.Context.ImageRendererV2.ImageRendererV2;

import nebula.Util.Pool;

import nebula.Graphics.Context.DrawCall;

import nebula.Math.AffineMatrix;

import nebula.Graphics.Context.Material;
import nebula.Graphics.Context.Shader;

import nebula.Flags;
import nebula.GarbageCollector;

final pixelSnapEpsilon: Float = 0.0001;

class ExcaliburGraphicsContextWebGLDebug implements DebugDraw {
  private _debugText = new DebugText();
  public function new(private _webglCtx: ExcaliburGraphicsContextWebGL) {}

  /**
   * Draw a debugging rectangle to the context
   * @param x
   * @param y
   * @param width
   * @param height
   */
  drawRect(x: Int, y: Int, width: Int, height: Int, rectOptions: RectGraphicsOptions = { color: Color.Black }): Void {
    this.drawLine(vec(x, y), vec(x + width, y), { ...rectOptions });
    this.drawLine(vec(x + width, y), vec(x + width, y + height), { ...rectOptions });
    this.drawLine(vec(x + width, y + height), vec(x, y + height), { ...rectOptions });
    this.drawLine(vec(x, y + height), vec(x, y), { ...rectOptions });
  }

  /**
   * Draw a debugging line to the context
   * @param start
   * @param end
   * @param lineOptions
   */
  drawLine(start: Vector, end: Vector, lineOptions?: LineGraphicsOptions): Void {
    this._webglCtx.draw<LineRenderer>('ex.line', start, end, lineOptions?.color ?? Color.Black);
  }

  /**
   * Draw a debugging point to the context
   * @param point
   * @param pointOptions
   */
  drawPoint(point: Vector, pointOptions: PointGraphicsOptions = { color: Color.Black, size: 5 }): Void {
    this._webglCtx.draw<PointRenderer>('ex.point', point, pointOptions.color, pointOptions.size);
  }

  drawText(text: String, pos: Vector) {
    this._debugText.write(this._webglCtx, text, pos);
  }
}

interface WebGLGraphicsContextInfo {
  transform: TransformStack;
  state: StateStack;
  ortho: Matrix;
  context: ExcaliburGraphicsContextWebGL;
}

interface ExcaliburGraphicsContextWebGLOptions extends ExcaliburGraphicsContextOptions {
  context?: WebGL2RenderingContext;
  garbageCollector?: { garbageCollector: GarbageCollector; collectionInterval: Int };
  handleContextLost?: (e: Event) => Void;
  handleContextRestored?: (e: Event) => Void;
}

class ExcaliburGraphicsContextWebGL implements ExcaliburGraphicsContext {
  private _logger = Logger.getInstance();
  private _renderers: Map<String, RendererPlugin> = new Map<String, RendererPlugin>();
  private _lazyRenderersFactory: Map<String, () => RendererPlugin> = new Map<String, () => RendererPlugin>();
  public imageRenderer: 'ex.image' | 'ex.image-v2' = Flags.isEnabled('use-legacy-image-renderer') ? 'ex.image' : 'ex.image-v2';
  private _isDrawLifecycle = false;
  public useDrawSorting = true;

  private _drawCallPool = new Pool<DrawCall>(() => new DrawCall(), undefined, 4000);

  private _drawCallIndex = 0;
  private _drawCalls: DrawCall[] = new Array(4000).fill(null);

  // Main render target
  private _renderTarget!: RenderTarget;

  // Quad boundary MSAA
  private _msaaTarget!: RenderTarget;

  // Postprocessing is a tuple with 2 render targets, these are flip-flopped during the postprocessing process
  private _postProcessTargets: RenderTarget[] = [];

  private _screenRenderer!: ScreenPassPainter;

  private _postprocessors: PostProcessor[] = [];

  /**
   * Meant for internal use only. Access the internal context at your own risk and no guarantees this will exist in the future.
   * @internal
   */
  public __gl: WebGL2RenderingContext;

  private _transform = new TransformStack();
  private _state = new StateStack();
  private _ortho!: Matrix;

  /**
   * Snaps the drawing x/y coordinate to the nearest whole pixel
   */
  public snapToPixel: Bool = false;

  /**
   * Native context smoothing
   */
  public readonly smoothing: Bool = false;

  /**
   * Whether the pixel art sampler is enabled for smooth sub pixel anti-aliasing
   */
  public readonly pixelArtSampler: Bool = false;

  /**
   * UV padding in pixels to use in internal image rendering to prevent texture bleed
   *
   */
  public uvPadding = 0.01;

  public backgroundColor: Color = Color.ExcaliburBlue;

  public textureLoader: TextureLoader;

  public materialScreenTexture!: Null<WebGLTexture>;

  public get z(): Int {
    return this._state.current.z;
  }

  public set z(value: Int) {
    this._state.current.z = value;
  }

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

  public get width() {
    return this.__gl.canvas.width;
  }

  public get height() {
    return this.__gl.canvas.height;
  }

  public get ortho(): Matrix {
    return this._ortho;
  }

  /**
   * Checks the underlying webgl implementation if the requested internal resolution is supported
   * @param dim
   */
  public checkIfResolutionSupported(dim: Resolution): Bool {
    // Slight hack based on this thread https://groups.google.com/g/webgl-dev-list/c/AHONvz3oQTo
    var supported = true;
    if (dim.width > 4096 || dim.height > 4096) {
      supported = false;
    }
    return supported;
  }

  public readonly multiSampleAntialiasing: Bool = true;
  public readonly samples?: Int;
  public readonly transparency: Bool = true;
  private _isContextLost = false;

  public function new(options: ExcaliburGraphicsContextWebGLOptions) {
    final {
      canvasElement,
      context,
      enableTransparency,
      antialiasing,
      uvPadding,
      multiSampleAntialiasing,
      pixelArtSampler,
      powerPreference,
      snapToPixel,
      backgroundColor,
      useDrawSorting,
      garbageCollector,
      handleContextLost,
      handleContextRestored
    } = options;
    this.__gl =
      context ??
      (canvasElement.getContext('webgl2', {
        antialias: antialiasing ?? this.smoothing,
        premultipliedAlpha: false,
        alpha: enableTransparency ?? this.transparency,
        depth: false,
        powerPreference: powerPreference ?? 'high-performance'
      }) as WebGL2RenderingContext);
    if (!this.__gl) {
      throw Error('Failed to retrieve webgl context from browser');
    }

    if (handleContextLost) {
      this.__gl.canvas.addEventListener('webglcontextlost', handleContextLost, false);
    }

    if (handleContextRestored) {
      this.__gl.canvas.addEventListener('webglcontextrestored', handleContextRestored, false);
    }

    this.__gl.canvas.addEventListener('webglcontextlost', () => {
      this._isContextLost = true;
    });

    this.__gl.canvas.addEventListener('webglcontextrestored', () => {
      this._isContextLost = false;
    });

    this.textureLoader = new TextureLoader(this.__gl, garbageCollector);
    this.snapToPixel = snapToPixel ?? this.snapToPixel;
    this.smoothing = antialiasing ?? this.smoothing;
    this.transparency = enableTransparency ?? this.transparency;
    this.pixelArtSampler = pixelArtSampler ?? this.pixelArtSampler;
    this.uvPadding = uvPadding ?? this.uvPadding;
    this.multiSampleAntialiasing = typeof multiSampleAntialiasing === 'boolean' ? multiSampleAntialiasing : this.multiSampleAntialiasing;
    this.samples = typeof multiSampleAntialiasing === 'object' ? multiSampleAntialiasing.samples : undefined;
    this.backgroundColor = backgroundColor ?? this.backgroundColor;
    this.useDrawSorting = useDrawSorting ?? this.useDrawSorting;
    this._drawCallPool.disableWarnings = true;
    this._drawCallPool.preallocate();
    this._init();
  }

  private _disposed = false;
  public dispose() {
    if (!this._disposed) {
      this._disposed = true;
      this.textureLoader.dispose();
      for (const renderer of this._renderers.values()) {
        renderer.dispose();
      }
      this._renderers.clear();
      this._drawCallPool.dispose();
      this._drawCalls.length = 0;
      this.__gl = null as any;
    }
  }

  private _init() {
    final gl = this.__gl;
    // Setup viewport and view matrix
    this._ortho = Matrix.ortho(0, gl.canvas.width, gl.canvas.height, 0, 400, -400);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

    // Clear background
    gl.clearColor(this.backgroundColor.r / 255, this.backgroundColor.g / 255, this.backgroundColor.b / 255, this.backgroundColor.a);
    gl.clear(gl.COLOR_BUFFER_BIT);

    // Enable alpha blending
    // https://www.realtimerendering.com/blog/gpus-prefer-premultiplication/
    gl.enable(gl.BLEND);
    gl.blendEquation(gl.FUNC_ADD);
    gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
    gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
    gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
    gl.depthMask(false);
    // Setup builtin renderers
    this.register(
      new ImageRenderer({
        uvPadding: this.uvPadding,
        pixelArtSampler: this.pixelArtSampler
      })
    );
    this.register(new MaterialRenderer());
    this.register(new RectangleRenderer());
    this.register(new CircleRenderer());
    this.register(new PointRenderer());
    this.register(new LineRenderer());
    this.lazyRegister<ParticleRenderer>('ex.particle', () => new ParticleRenderer());
    this.register(
      new ImageRendererV2({
        uvPadding: this.uvPadding,
        pixelArtSampler: this.pixelArtSampler
      })
    );

    this.materialScreenTexture = gl.createTexture();
    if (!this.materialScreenTexture) {
      throw new Error('Could not create screen texture!');
    }
    gl.bindTexture(gl.TEXTURE_2D, this.materialScreenTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.bindTexture(gl.TEXTURE_2D, null);

    this._screenRenderer = new ScreenPassPainter(this);

    this._renderTarget = new RenderTarget({
      gl,
      transparency: this.transparency,
      width: gl.canvas.width,
      height: gl.canvas.height
    });

    this._postProcessTargets = [
      new RenderTarget({
        gl,
        transparency: this.transparency,
        width: gl.canvas.width,
        height: gl.canvas.height
      }),
      new RenderTarget({
        gl,
        transparency: this.transparency,
        width: gl.canvas.width,
        height: gl.canvas.height
      })
    ];

    this._msaaTarget = new RenderTarget({
      gl,
      transparency: this.transparency,
      width: gl.canvas.width,
      height: gl.canvas.height,
      antialias: this.multiSampleAntialiasing,
      samples: this.samples
    });
  }

  public register<T extends RendererPlugin>(renderer: T) {
    this._renderers.set(renderer.type, renderer);
    renderer.initialize(this.__gl, this);
  }

  public lazyRegister<TRenderer extends RendererPlugin>(type: TRenderer['type'], renderer: () => TRenderer) {
    this._lazyRenderersFactory.set(type, renderer);
  }

  public get(rendererName: string): RendererPlugin | undefined {
    var maybeRenderer = this._renderers.get(rendererName);
    if (!maybeRenderer) {
      final lazyFactory = this._lazyRenderersFactory.get(rendererName);
      if (lazyFactory) {
        this._logger.debug('lazy init renderer:', rendererName);
        maybeRenderer = lazyFactory();
        this.register(maybeRenderer);
      }
    }
    return maybeRenderer;
  }

  private _currentRenderer: RendererPlugin | undefined;

  private _isCurrentRenderer(renderer: RendererPlugin): Bool {
    if (!this._currentRenderer || this._currentRenderer === renderer) {
      return true;
    }
    return false;
  }

  public beginDrawLifecycle() {
    this._isDrawLifecycle = true;
  }

  public endDrawLifecycle() {
    this._isDrawLifecycle = false;
  }

  public function draw<TRenderer extends RendererPlugin>(rendererName: TRenderer['type'], ...args: Parameters<TRenderer['draw']>) {
    if (process.env.NODE_ENV === 'development') {
      if (args.length > 9) {
        throw new Error('Only 10 or less renderer arguments are supported!;');
      }
    }
    if (!this._isDrawLifecycle) {
      this._logger.warnOnce(
        'Attempting to draw outside the the drawing lifecycle (preDraw/postDraw) is not supported and is a source of bugs/errors.\n' +
          'If you want to do custom drawing, use Actor.graphics, or any onPreDraw or onPostDraw handler.'
      );
    }
    if (this._isContextLost) {
      this._logger.errorOnce('Unable to draw ${rendererName}, the webgl context is lost');
      return;
    }

    final renderer = this.get(rendererName);
    if (renderer) {
      if (this.useDrawSorting) {
        final drawCall = this._drawCallPool.get();
        drawCall.z = this._state.current.z;
        drawCall.priority = renderer.priority;
        drawCall.renderer = rendererName;
        this.getTransform().clone(drawCall.transform);
        drawCall.state.z = this._state.current.z;
        drawCall.state.opacity = this._state.current.opacity;
        drawCall.state.tint = this._state.current.tint;
        drawCall.state.material = this._state.current.material;
        drawCall.args[0] = args[0];
        drawCall.args[1] = args[1];
        drawCall.args[2] = args[2];
        drawCall.args[3] = args[3];
        drawCall.args[4] = args[4];
        drawCall.args[5] = args[5];
        drawCall.args[6] = args[6];
        drawCall.args[7] = args[7];
        drawCall.args[8] = args[8];
        drawCall.args[9] = args[9];
        this._drawCalls[this._drawCallIndex++] = drawCall;
      } else {
        // Set the current renderer if not defined
        if (!this._currentRenderer) {
          this._currentRenderer = renderer;
        }

        if (!this._isCurrentRenderer(renderer)) {
          // switching graphics means we must flush the previous
          this._currentRenderer.flush();
        }

        // If we are still using the same renderer we can add to the current batch
        renderer.draw(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]);

        this._currentRenderer = renderer;
      }
    } else {
      throw Error('No renderer with name ${rendererName} has been registered');
    }
  }

  public resetTransform(): Void {
    this._transform.reset();
  }

  public updateViewport(resolution: Resolution): Void {
    final gl = this.__gl;
    this._ortho = this._ortho = Matrix.ortho(0, resolution.width, resolution.height, 0, 400, -400);

    this._renderTarget.setResolution(gl.canvas.width, gl.canvas.height);
    this._msaaTarget.setResolution(gl.canvas.width, gl.canvas.height);
    this._postProcessTargets[0].setResolution(gl.canvas.width, gl.canvas.height);
    this._postProcessTargets[1].setResolution(gl.canvas.width, gl.canvas.height);
  }

  private _imageToWidth = new Map<HTMLImageSource, Int>();
  private _getImageWidth(image: HTMLImageSource) {
    var maybeWidth = this._imageToWidth.get(image);
    if (maybeWidth === undefined) {
      maybeWidth = image.width;
      this._imageToWidth.set(image, maybeWidth);
    }
    return maybeWidth;
  }

  private _imageToHeight = new Map<HTMLImageSource, Int>();
  private _getImageHeight(image: HTMLImageSource) {
    var maybeHeight = this._imageToHeight.get(image);
    if (maybeHeight === undefined) {
      maybeHeight = image.height;
      this._imageToHeight.set(image, maybeHeight);
    }
    return maybeHeight;
  }

  drawImage(image: HTMLImageSource, x: Int, y: Int): Void;
  drawImage(image: HTMLImageSource, x: Int, y: Int, width: Int, height: Int): Void;
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
  ): void;
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
    } else if (this._getImageWidth(image) === 0 || this._getImageHeight(image) === 0) {
      return; // zero dimension source exit early
    }

    if (!image) {
      Logger.getInstance().warn('Cannot draw a null or undefined image');
      // tslint:disable-next-line: no-console
      if (console.trace) {
        // tslint:disable-next-line: no-console
        console.trace();
      }
      return;
    }

    if (this._state.current.material) {
      this.draw<MaterialRenderer>('ex.material', image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
    } else {
      if (this.imageRenderer === 'ex.image') {
        this.draw<ImageRenderer>(this.imageRenderer, image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
      } else {
        this.draw<ImageRendererV2>(this.imageRenderer, image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
      }
    }
  }

  public drawLine(start: Vector, end: Vector, color: Color, thickness = 1) {
    this.draw<RectangleRenderer>('ex.rectangle', start, end, color, thickness);
  }

  public drawRectangle(pos: Vector, width: Int, height: Int, color: Color, stroke?: Color, strokeThickness?: Int) {
    this.draw<RectangleRenderer>('ex.rectangle', pos, width, height, color, stroke, strokeThickness);
  }

  public drawCircle(pos: Vector, radius: Float, color: Color, stroke?: Color, thickness?: Int) {
    this.draw<CircleRenderer>('ex.circle', pos, radius, color, stroke, thickness);
  }

  debug = new ExcaliburGraphicsContextWebGLDebug(this);

  public save(): Void {
    this._transform.save();
    this._state.save();
  }

  public restore(): Void {
    this._transform.restore();
    this._state.restore();
  }

  public translate(x: Int, y: Int): Void {
    this._transform.translate(this.snapToPixel ? ~~(x + pixelSnapEpsilon) : x, this.snapToPixel ? ~~(y + pixelSnapEpsilon) : y);
  }

  public rotate(angle: Int): Void {
    this._transform.rotate(angle);
  }

  public scale(x: Int, y: Int): Void {
    this._transform.scale(x, y);
  }

  public transform(matrix: AffineMatrix) {
    this._transform.current = matrix;
  }

  public getTransform(): AffineMatrix {
    return this._transform.current;
  }

  public multiply(m: AffineMatrix) {
    this._transform.current.multiply(m, this._transform.current);
  }

  public addPostProcessor(postprocessor: PostProcessor) {
    this._postprocessors.push(postprocessor);
    postprocessor.initialize(this);
  }

  public removePostProcessor(postprocessor: PostProcessor) {
    final index = this._postprocessors.indexOf(postprocessor);
    if (index !== -1) {
      this._postprocessors.splice(index, 1);
    }
  }

  public clearPostProcessors() {
    this._postprocessors.length = 0;
  }

  private _totalPostProcessorTime = 0;
  public updatePostProcessors(elapsed: Int) {
    for (final postprocessor of this._postprocessors) {
      final shader = postprocessor.getShader();
      shader.use();
      final uniforms = shader.getUniformDefinitions();
      this._totalPostProcessorTime += elapsed;

      if (uniforms.find((u) => u.name === 'u_time_ms')) {
        shader.setUniformFloat('u_time_ms', this._totalPostProcessorTime);
      }
      if (uniforms.find((u) => u.name === 'u_elapsed_ms')) {
        shader.setUniformFloat('u_elapsed_ms', elapsed);
      }
      if (uniforms.find((u) => u.name === 'u_resolution')) {
        shader.setUniformFloatVector('u_resolution', vec(this.width, this.height));
      }

      if (postprocessor.onUpdate) {
        postprocessor.onUpdate(elapsed);
      }
    }
  }

  public set material(material: Null<Material>) {
    this._state.current.material = material;
  }

  public get material(): Null<Material> {
    return this._state.current.material;
  }

  /**
   * Creates and initializes the material which compiles the internal shader
   * @param options
   * @returns Material
   */
  public createMaterial(options: Omit<MaterialOptions, 'graphicsContext'>): Material {
    final material = new Material({ ...options, graphicsContext: this });
    return material;
  }

  public createShader(options: Omit<ShaderOptions, 'graphicsContext'>): Shader {
    final { name, vertexSource, fragmentSource, uniforms, images, startingTextureSlot } = options;
    final shader = new Shader({
      name,
      graphicsContext: this,
      vertexSource,
      fragmentSource,
      uniforms,
      images,
      startingTextureSlot
    });
    shader.compile();
    return shader;
  }

  clear() {
    final gl = this.__gl;
    final currentTarget = this.multiSampleAntialiasing ? this._msaaTarget : this._renderTarget;
    currentTarget.use();
    gl.clearColor(this.backgroundColor.r / 255, this.backgroundColor.g / 255, this.backgroundColor.b / 255, this.backgroundColor.a);
    // Clear the context with the newly set color. This is
    // the function call that actually does the drawing.
    gl.clear(gl.COLOR_BUFFER_BIT);
  }

  /**
   * Flushes all batched rendering to the screen
   */
  flush() {
    if (this._isContextLost) {
      this._logger.errorOnce('Unable to flush the webgl context is lost');
      return;
    }

    // render target captures all draws and redirects to the render target
    var currentTarget = this.multiSampleAntialiasing ? this._msaaTarget : this._renderTarget;
    currentTarget.use();

    if (this.useDrawSorting) {
      // null out unused draw calls
      for (var i = this._drawCallIndex; i < this._drawCalls.length; i++) {
        this._drawCalls[i] = null as any;
      }
      // sort draw calls
      // Find the original order of the first instance of the draw call
      final originalSort = new Map<string, number>();
      for (final [name] of this._renderers) {
        var firstIndex = 0;
        for (firstIndex = 0; firstIndex < this._drawCallIndex; firstIndex++) {
          if (this._drawCalls[firstIndex].renderer === name) {
            break;
          }
        }
        originalSort.set(name, firstIndex);
      }

      this._drawCalls.sort((a, b) => {
        if (a === null || b === null) {
          return 0;
        }
        final zIndex = a.z - b.z;
        final originalSortOrder = originalSort.get(a.renderer)! - originalSort.get(b.renderer)!;
        final priority = a.priority - b.priority;
        if (zIndex === 0) {
          // sort by z first
          if (priority === 0) {
            // sort by priority
            return originalSortOrder; // use the original order to inform draw call packing to maximally preserve painter order
          }
          return priority;
        }
        return zIndex;
      });

      final oldTransform = this._transform.current;
      final oldState = this._state.current;

      if (this._drawCalls.length && this._drawCallIndex) {
        var currentRendererName = this._drawCalls[0].renderer;
        var currentRenderer = this.get(currentRendererName);
        for (var i = 0; i < this._drawCallIndex; i++) {
          // hydrate the state for renderers
          this._transform.current = this._drawCalls[i].transform;
          this._state.current = this._drawCalls[i].state;

          if (this._drawCalls[i].renderer !== currentRendererName) {
            // switching graphics renderer means we must flush the previous
            currentRenderer!.flush();
            currentRendererName = this._drawCalls[i].renderer;
            currentRenderer = this.get(currentRendererName);
          }

          // ! hack to grab screen texture before materials run because they might want it
          if (currentRenderer instanceof MaterialRenderer && this.material?.isUsingScreenTexture) {
            currentTarget.copyToTexture(this.materialScreenTexture!);
            currentTarget.use();
          }
          // If we are still using the same renderer we can add to the current batch
          currentRenderer!.draw(...this._drawCalls[i].args);
        }
        if (currentRenderer!.hasPendingDraws()) {
          currentRenderer!.flush();
        }
      }

      // reset state
      this._transform.current = oldTransform;
      this._state.current = oldState;

      // reclaim draw calls
      this._drawCallPool.done();
      this._drawCallIndex = 0;
      this._imageToHeight.clear();
      this._imageToWidth.clear();
    } else {
      // This is the final flush at the moment to draw any leftover pending draw
      for (final renderer of this._renderers.values()) {
        if (renderer.hasPendingDraws()) {
          renderer.flush();
        }
      }
    }

    currentTarget.disable();

    // post process step
    if (this._postprocessors.length > 0) {
      currentTarget.toRenderSource().use();
    }

    // flip flop render targets for post processing
    for (var i = 0; i < this._postprocessors.length; i++) {
      currentTarget = this._postProcessTargets[i % 2];
      this._postProcessTargets[i % 2].use();
      this._screenRenderer.renderWithPostProcessor(this._postprocessors[i]);
      this._postProcessTargets[i % 2].toRenderSource().use();
    }

    // Final blit to the screen
    currentTarget.blitToScreen();
  }
}
