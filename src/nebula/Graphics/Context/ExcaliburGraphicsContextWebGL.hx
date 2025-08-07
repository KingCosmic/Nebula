package nebula.graphics.context;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.math.Matrix;
import nebula.math.Vector;

import nebula.graphics.context.TransformStack;
import nebula.graphics.context.StateStack;
import nebula.graphics.context.DebugText;
import nebula.graphics.context.RenderTarget;
import nebula.graphics.context.TextureLoader;
import nebula.graphics.context.Renderer;

import nebula.graphics.postprocessor.PostProcessor;

import nebula.Screen;

import nebula.util.Log;

import nebula.Color;

import nebula.graphics.context.linerenderer.LineRenderer;
import nebula.graphics.context.pointrenderer.PointRenderer;
import nebula.graphics.context.screenpasspainter.ScreenPassPainter;
import nebula.graphics.context.imagerenderer.ImageRenderer;
import nebula.graphics.context.rectanglerenderer.RectangleRenderer;
import nebula.graphics.context.circlerenderer.CircleRenderer;
import nebula.graphics.context.materialrenderer.MaterialRenderer;
import nebula.graphics.context.particlerenderer.ParticleRenderer;
import nebula.graphics.context.imagerendererv2.ImageRendererV2;

import nebula.util.Pool;

import nebula.graphics.context.DrawCall;

import nebula.math.AffineMatrix;

import nebula.graphics.context.Material;
import nebula.graphics.context.Shader;

import nebula.Flags;
import nebula.GarbageCollector;

final pixelSnapEpsilon: Float = 0.0001;

class ExcaliburGraphicsContextWebGLDebug implements DebugDraw {
  private var _debugText = new DebugText();
  public function new(_webglCtx: ExcaliburGraphicsContextWebGL) {}

  /**
   * Draw a debugging rectangle to the context
   * @param x
   * @param y
   * @param width
   * @param height
   */
  function drawRect(x: Int, y: Int, width: Int, height: Int, rectOptions: RectGraphicsOptions = { color: Color.Black }): Void {
    this.drawLine(vec(x, y), vec(x + width, y), rectOptions);
    this.drawLine(vec(x + width, y), vec(x + width, y + height), rectOptions);
    this.drawLine(vec(x + width, y + height), vec(x, y + height), rectOptions);
    this.drawLine(vec(x, y + height), vec(x, y), rectOptions);
  }

  /**
   * Draw a debugging line to the context
   * @param start
   * @param end
   * @param lineOptions
   */
  function drawLine(start: Vector, end: Vector, ?lineOptions: LineGraphicsOptions): Void {
    this._webglCtx.draw('ex.line', start, end, lineOptions.color ?? Color.Black);
  }

  /**
   * Draw a debugging point to the context
   * @param point
   * @param pointOptions
   */
  function drawPoint(point: Vector, pointOptions: PointGraphicsOptions = { color: Color.Black, size: 5 }): Void {
    this._webglCtx.draw('ex.point', point, pointOptions.color, pointOptions.size);
  }

  function drawText(text: String, pos: Vector) {
    this._debugText.write(this._webglCtx, text, pos);
  }
}

interface WebGLGraphicsContextInfo {
  var transform: TransformStack;
  var state: StateStack;
  var ortho: Matrix;
  var context: ExcaliburGraphicsContextWebGL;
}

interface ExcaliburGraphicsContextWebGLOptions extends ExcaliburGraphicsContextOptions {
  var context: Null<WebGL2RenderingContext>;
  var garbageCollector: Null<{ garbageCollector: GarbageCollector, collectionInterval: Int }>;
  var handleContextLost: (e: Event) -> Void;
  var handleContextRestored: (e: Event) -> Void;
}

class ExcaliburGraphicsContextWebGL implements ExcaliburGraphicsContext {
  private var _logger = Logger.getInstance();
  private var _renderers: Map<String, RendererPlugin> = new Map<String, RendererPlugin>();
  private var _lazyRenderersFactory: Map<String, () -> RendererPlugin> = new Map<String, () -> RendererPlugin>();
  public var imageRenderer: String = Flags.isEnabled('use-legacy-image-renderer') ? 'ex.image' : 'ex.image-v2';
  private var _isDrawLifecycle = false;
  public var useDrawSorting = true;

  private var _drawCallPool = new Pool<DrawCall>(() -> new DrawCall(), null, 4000);

  private var _drawCallIndex = 0;
  private var _drawCalls: Array<DrawCall> = new Array(4000).fill(null);

  // Main render target
  private var _renderTarget: RenderTarget;

  // Quad boundary MSAA
  private var _msaaTarget: RenderTarget;

  // Postprocessing is a tuple with 2 render targets, these are flip-flopped during the postprocessing process
  private var _postProcessTargets: Array<RenderTarget> = [];

  private var _screenRenderer: ScreenPassPainter;

  private var _postprocessors: Array<PostProcessor> = [];

  /**
   * Meant for internal use only. Access the internal context at your own risk and no guarantees this will exist in the future.
   * @internal
   */
  public var __gl: WebGL2RenderingContext;

  private var _transform = new TransformStack();
  private var _state = new StateStack();
  private var _ortho: Matrix;

  /**
   * Snaps the drawing x/y coordinate to the nearest whole pixel
   */
  public var snapToPixel: Bool = false;

  /**
   * Native context smoothing
   */
  public var smoothing: Bool = false;

  /**
   * Whether the pixel art sampler is enabled for smooth sub pixel anti-aliasing
   */
  public var pixelArtSampler: Bool = false;

  /**
   * UV padding in pixels to use in internal image rendering to prevent texture bleed
   *
   */
  public var uvPadding = 0.01;

  public var backgroundColor: Color = Color.ExcaliburBlue;

  public var textureLoader: TextureLoader;

  public var materialScreenTexture: Null<WebGLTexture>;

  public var z(get, set): Int;
  function get_z(): Int {
    return this._state.current.z;
  }
  function set_z(value: Int) {
    this._state.current.z = value;
  }

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

  public var width(get, never): Int;
  function get_width() {
    return this.__gl.canvas.width;
  }

  public var height(get, never): Int;
  function get_height() {
    return this.__gl.canvas.height;
  }

  public var ortho(get, never): Matrix;
  function get_ortho(): Matrix {
    return this._ortho;
  }

  /**
   * Checks the underlying webgl implementation if the requested internal resolution is supported
   * @param dim
   */
  public function checkIfResolutionSupported(dim: Resolution): Bool {
    // Slight hack based on this thread https://groups.google.com/g/webgl-dev-list/c/AHONvz3oQTo
    var supported = true;
    if (dim.width > 4096 || dim.height > 4096) {
      supported = false;
    }
    return supported;
  }

  public var multiSampleAntialiasing: Bool = true;
  public var samples: Null<Int>;
  public var transparency: Bool = true;
  private var _isContextLost = false;

  public function new(options: ExcaliburGraphicsContextWebGLOptions) {
    final canvasElement = options.canvasElement,
          context = options.context,
          enableTransparency = options.enableTransparency,
          antialiasing = options.antialiasing,
          uvPadding = options.uvPadding,
          multiSampleAntialiasing = options.multiSampleAntialiasing,
          pixelArtSampler = options.pixelArtSampler,
          powerPreference = options.powerPreference,
          snapToPixel = options.snapToPixel,
          backgroundColor = options.backgroundColor,
          useDrawSorting = options.useDrawSorting,
          garbageCollector = options.garbageCollector,
          handleContextLost = options.handleContextLost,
          handleContextRestored = options.handleContextRestored;

    this.__gl =
      context ??
      (canvasElement.getContext('webgl2', {
        antialias: antialiasing ?? this.smoothing,
        premultipliedAlpha: false,
        alpha: enableTransparency ?? this.transparency,
        depth: false,
        powerPreference: powerPreference ?? 'high-performance'
      }));
    if (!this.__gl) {
      throw Error('Failed to retrieve webgl context from browser');
    }

    if (handleContextLost) {
      this.__gl.canvas.addEventListener('webglcontextlost', handleContextLost, false);
    }

    if (handleContextRestored) {
      this.__gl.canvas.addEventListener('webglcontextrestored', handleContextRestored, false);
    }

    this.__gl.canvas.addEventListener('webglcontextlost', () -> {
      this._isContextLost = true;
    });

    this.__gl.canvas.addEventListener('webglcontextrestored', () -> {
      this._isContextLost = false;
    });

    this.textureLoader = new TextureLoader(this.__gl, garbageCollector);
    this.snapToPixel = snapToPixel ?? this.snapToPixel;
    this.smoothing = antialiasing ?? this.smoothing;
    this.transparency = enableTransparency ?? this.transparency;
    this.pixelArtSampler = pixelArtSampler ?? this.pixelArtSampler;
    this.uvPadding = uvPadding ?? this.uvPadding;
    this.multiSampleAntialiasing = Std.isOfType(multiSampleAntialiasing, Bool) ? multiSampleAntialiasing : this.multiSampleAntialiasing;
    this.samples = Std.isOfType(multiSampleAntialiasing, Object) ? multiSampleAntialiasing.samples : null;
    this.backgroundColor = backgroundColor ?? this.backgroundColor;
    this.useDrawSorting = useDrawSorting ?? this.useDrawSorting;
    this._drawCallPool.disableWarnings = true;
    this._drawCallPool.preallocate();
    this._init();
  }

  private var _disposed = false;
  public function dispose() {
    if (!this._disposed) {
      this._disposed = true;
      this.textureLoader.dispose();
      for (renderer in this._renderers.values()) {
        renderer.dispose();
      }
      this._renderers.clear();
      this._drawCallPool.dispose();
      this._drawCalls.length = 0;
      this.__gl = null;
    }
  }

  private function _init() {
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
    this.lazyRegister('ex.particle', () -> new ParticleRenderer());
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
      gl: gl,
      transparency: this.transparency,
      width: gl.canvas.width,
      height: gl.canvas.height
    });

    this._postProcessTargets = [
      new RenderTarget({
        gl: gl,
        transparency: this.transparency,
        width: gl.canvas.width,
        height: gl.canvas.height
      }),
      new RenderTarget({
        gl: gl,
        transparency: this.transparency,
        width: gl.canvas.width,
        height: gl.canvas.height
      })
    ];

    this._msaaTarget = new RenderTarget({
      gl: gl,
      transparency: this.transparency,
      width: gl.canvas.width,
      height: gl.canvas.height,
      antialias: this.multiSampleAntialiasing,
      samples: this.samples
    });
  }

  public function register<T:RendererPlugin>(renderer: T) {
    this._renderers.set(renderer.type, renderer);
    renderer.initialize(this.__gl, this);
  }

  public function lazyRegister<TRenderer:RendererPlugin>(type: String, renderer: () -> TRenderer) {
    this._lazyRenderersFactory.set(type, renderer);
  }

  public function get(rendererName: String): Null<RendererPlugin> {
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

  private var _currentRenderer: Null<RendererPlugin>;

  private function _isCurrentRenderer(renderer: RendererPlugin): Bool {
    if (!this._currentRenderer || this._currentRenderer == renderer) {
      return true;
    }
    return false;
  }

  public function beginDrawLifecycle() {
    this._isDrawLifecycle = true;
  }

  public function endDrawLifecycle() {
    this._isDrawLifecycle = false;
  }

  public function draw<TRenderer:RendererPlugin>(rendererName: String, ...args: Array<Any>) {
    // if (process.env.NODE_ENV == 'development') {
    //   if (args.length > 9) {
    //     throw new Error('Only 10 or less renderer arguments are supported!;');
    //   }
    // }
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

  public function resetTransform(): Void {
    this._transform.reset();
  }

  public function updateViewport(resolution: Resolution): Void {
    final gl = this.__gl;
    this._ortho = this._ortho = Matrix.ortho(0, resolution.width, resolution.height, 0, 400, -400);

    this._renderTarget.setResolution(gl.canvas.width, gl.canvas.height);
    this._msaaTarget.setResolution(gl.canvas.width, gl.canvas.height);
    this._postProcessTargets[0].setResolution(gl.canvas.width, gl.canvas.height);
    this._postProcessTargets[1].setResolution(gl.canvas.width, gl.canvas.height);
  }

  private var _imageToWidth = new Map<HTMLImageSource, Int>();
  private function _getImageWidth(image: HTMLImageSource) {
    var maybeWidth = this._imageToWidth.get(image);
    if (maybeWidth == null) {
      maybeWidth = image.width;
      this._imageToWidth.set(image, maybeWidth);
    }
    return maybeWidth;
  }

  private var _imageToHeight = new Map<HTMLImageSource, Int>();
  private function _getImageHeight(image: HTMLImageSource) {
    var maybeHeight = this._imageToHeight.get(image);
    if (maybeHeight == null) {
      maybeHeight = image.height;
      this._imageToHeight.set(image, maybeHeight);
    }
    return maybeHeight;
  }

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
    } else if (this._getImageWidth(image) == 0 || this._getImageHeight(image) == 0) {
      return; // zero dimension source exit early
    }

    if (!image) {
      Logger.getInstance().warn('Cannot draw a null or undefined image');
      // if (console.trace) {
      //   console.trace();
      // }
      return;
    }

    if (this._state.current.material) {
      this.draw('ex.material', image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
    } else {
      if (this.imageRenderer == 'ex.image') {
        this.draw(this.imageRenderer, image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
      } else {
        this.draw(this.imageRenderer, image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
      }
    }
  }

  public function drawLine(start: Vector, end: Vector, color: Color, thickness = 1) {
    this.draw('ex.rectangle', start, end, color, thickness);
  }

  public function drawRectangle(pos: Vector, width: Int, height: Int, color: Color, ?stroke: Color, ?strokeThickness: Int) {
    this.draw('ex.rectangle', pos, width, height, color, stroke, strokeThickness);
  }

  public function drawCircle(pos: Vector, radius: Float, color: Color, ?stroke: Color, ?thickness: Int) {
    this.draw('ex.circle', pos, radius, color, stroke, thickness);
  }

  var debug = new ExcaliburGraphicsContextWebGLDebug(this);

  public function save(): Void {
    this._transform.save();
    this._state.save();
  }

  public function restore(): Void {
    this._transform.restore();
    this._state.restore();
  }

  public function translate(x: Int, y: Int): Void {
    this._transform.translate(this.snapToPixel ? ~~(x + pixelSnapEpsilon) : x, this.snapToPixel ? ~~(y + pixelSnapEpsilon) : y);
  }

  public function rotate(angle: Int): Void {
    this._transform.rotate(angle);
  }

  public function scale(x: Int, y: Int): Void {
    this._transform.scale(x, y);
  }

  public function transform(matrix: AffineMatrix) {
    this._transform.current = matrix;
  }

  public function getTransform(): AffineMatrix {
    return this._transform.current;
  }

  public function multiply(m: AffineMatrix) {
    this._transform.current.multiply(m, this._transform.current);
  }

  public function addPostProcessor(postprocessor: PostProcessor) {
    this._postprocessors.push(postprocessor);
    postprocessor.initialize(this);
  }

  public function removePostProcessor(postprocessor: PostProcessor) {
    final index = this._postprocessors.indexOf(postprocessor);
    if (index != -1) {
      this._postprocessors.splice(index, 1);
    }
  }

  public function clearPostProcessors() {
    this._postprocessors.length = 0;
  }

  private var _totalPostProcessorTime = 0;
  public function updatePostProcessors(elapsed: Int) {
    for (postprocessor in this._postprocessors) {
      final shader = postprocessor.getShader();
      shader.use();
      final uniforms = shader.getUniformDefinitions();
      this._totalPostProcessorTime += elapsed;

      if (uniforms.find((u) -> u.name == 'u_time_ms')) {
        shader.setUniformFloat('u_time_ms', this._totalPostProcessorTime);
      }
      if (uniforms.find((u) -> u.name == 'u_elapsed_ms')) {
        shader.setUniformFloat('u_elapsed_ms', elapsed);
      }
      if (uniforms.find((u) -> u.name == 'u_resolution')) {
        shader.setUniformFloatVector('u_resolution', vec(this.width, this.height));
      }

      if (postprocessor.onUpdate) {
        postprocessor.onUpdate(elapsed);
      }
    }
  }

  public var material(get, set): Null<Material>;
  function get_material(): Null<Material> {
    return this._state.current.material;
  }
  function set_material(material: Null<Material>) {
    this._state.current.material = material;
  }

  /**
   * Creates and initializes the material which compiles the internal shader
   * @param options
   * @returns Material
   */
  public function createMaterial(options: Omit<MaterialOptions, 'graphicsContext'>): Material {
    final mergedOptions = Object.spreadwith(options, { graphicsContext: this });
    final material = new Material(mergedOptions);
    return material;
  }

  public function createShader(options: Omit<ShaderOptions, 'graphicsContext'>): Shader {
    final name = options.name,
          vertexSource = options.vertexSource,
          fragmentSource = options.fragmentSource,
          uniforms = options.uniforms,
          images = options.images,
          startingTextureSlot = options.startingTextureSlot;

    final shader = new Shader({
      name: name,
      graphicsContext: this,
      vertexSource: vertexSource,
      fragmentSource: fragmentSource,
      uniforms: uniforms,
      images: images,
      startingTextureSlot: startingTextureSlot
    });
    shader.compile();
    return shader;
  }

  function clear() {
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
  function flush() {
    if (this._isContextLost) {
      this._logger.errorOnce('Unable to flush the webgl context is lost');
      return;
    }

    // render target captures all draws and redirects to the render target
    var currentTarget = this.multiSampleAntialiasing ? this._msaaTarget : this._renderTarget;
    currentTarget.use();

    if (this.useDrawSorting) {
      // null out unused draw calls
      for (i in this._drawCallIndex...this._drawCalls.length) {
        this._drawCalls[i] = null;
      }
      // sort draw calls
      // Find the original order of the first instance of the draw call
      final originalSort = new Map<String, Int>();
      for (name => val in this._renderers) {
        var firstIndex = 0;
        while (firstIndex < this._drawCallIndex) {
          if (this._drawCalls[firstIndex].renderer == name) {
            break;
          }
          firstIndex++;
        }
        originalSort.set(name, firstIndex);
      }

      this._drawCalls.sort((a, b) -> {
        if (a == null || b == null) {
          return 0;
        }
        final zIndex = a.z - b.z;
        final originalSortOrder = originalSort.get(a.renderer)! - originalSort.get(b.renderer)!;
        final priority = a.priority - b.priority;
        if (zIndex == 0) {
          // sort by z first
          if (priority == 0) {
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
        for (i in 0...this._drawCallIndex) {
          // hydrate the state for renderers
          this._transform.current = this._drawCalls[i].transform;
          this._state.current = this._drawCalls[i].state;

          if (this._drawCalls[i].renderer != currentRendererName) {
            // switching graphics renderer means we must flush the previous
            currentRenderer!.flush();
            currentRendererName = this._drawCalls[i].renderer;
            currentRenderer = this.get(currentRendererName);
          }

          // ! hack to grab screen texture before materials run because they might want it
          if (Std.isTypeOf(currentRenderer, MaterialRenderer) && this.material?.isUsingScreenTexture) {
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
      for (key => renderer in this._renderers) {
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
    for (i in 0...this._postprocessors.length) {
      currentTarget = this._postProcessTargets[i % 2];
      this._postProcessTargets[i % 2].use();
      this._screenRenderer.renderWithPostProcessor(this._postprocessors[i]);
      this._postProcessTargets[i % 2].toRenderSource().use();
    }

    // Final blit to the screen
    currentTarget.blitToScreen();
  }
}
