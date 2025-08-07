package nebula.graphics;

import nebula.math.Vector;

import nebula.graphics.Graphic;
import nebula.graphics.Animation;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.collision.BoundingBox;

import nebula.graphics.context.Material;

import nebula.util.Log;

import nebula.math.WatchVector;

import nebula.graphics.GraphicsGroup;

import nebula.Color;

import nebula.graphics.Raster;
import nebula.graphics.Text;

/**
 * Type guard for checking if a Graphic HasTick (used for graphics that change over time like animations)
 * @param graphic
 */
function hasGraphicsTick(graphic: Graphic): Graphic & HasTick {
  return !!graphic.tick;
}
interface GraphicsShowOptions {
  var offset: Null<Vector>;
  var anchor: Null<Vector>;
}

interface GraphicsComponentOptions {
  var onPostDraw: Null<(ex: ExcaliburGraphicsContext, elapsed: Float) -> Void>;
  var onPreDraw: Null<(ex: ExcaliburGraphicsContext, elapsed: Float) -> Void>;
  var onPreTransformDraw: Null<(ex: ExcaliburGraphicsContext, elapsed: Float) -> Void>;
  var onPostTransformDraw: Null<(ex: ExcaliburGraphicsContext, elapsed: Float) -> Void>;

  /**
   * Name of current graphic to use
   */
  var current: Null<String>;

  /**
   * Optionally set the color of the graphics component
   */
  var color: Null<Color>;

  /**
   * Optionally set a material to use on the graphic
   */
  var material: Null<Material>;

  /**
   * Optionally copy instances of graphics by calling .clone(), you may set this to false to avoid sharing graphics when added to the
   * component for performance reasons. By default graphics are not copied and are shared when added to the component.
   */
  var copyGraphics: Null<Bool>;

  /**
   * Optional visible flag, if the graphics component is not visible it will not be displayed
   */
  var visible: Null<Bool>;

  /**
   * Optional opacity
   */
  var opacity: Null<Float>;

  /**
   * List of graphics and optionally the options per graphic
   */
  var graphics: Null<Map<String, { graphic: Graphic, options: Null<GraphicsShowOptions> }>>;

  /**
   * Optional offset in absolute pixels to shift all graphics in this component from each graphic's anchor (default is top left corner)
   */
  var offset: Null<Vector>;

  /**
   * Optional anchor
   */
  var anchor: Null<Vector>;
}

/**
 * Component to manage drawings, using with the position component
 */
class GraphicsComponent extends Component {
  private var _logger = Logger.getInstance();

  private var _current: String = 'default';
  private var _graphics: Record<String, Graphic> = {};
  private var _options: Record<String, Null<GraphicsShowOptions>> = {};

  public var material: Null<Material> = null;

  /**
   * Draws after the entity transform has been applied, but before graphics component graphics have been drawn
   */
  public var onPreDraw: Null<(ctx: ExcaliburGraphicsContext, elapsed: Float) -> Void>;

  /**
   * Draws after the entity transform has been applied, and after graphics component graphics has been drawn
   */
  public var onPostDraw: Null<(ctx: ExcaliburGraphicsContext, elapsed: Float) -> Void>;

  /**
   * Draws before the entity transform has been applied before any any graphics component drawing
   */
  public var onPreTransformDraw: Null<(ctx: ExcaliburGraphicsContext, elapsed: Float) -> Void>;

  /**
   * Draws after the entity transform has been applied, and after all graphics component drawing
   */
  public var onPostTransformDraw: Null<(ctx: ExcaliburGraphicsContext, elapsed: Float) -> Void>;
  private var _color: Null<Color>;

  /**
   * Sets or gets wether any drawing should be visible in this component
   * @deprecated use isVisible
   */
  public var visible(get, set): Bool;
  function get_visible(): Bool {
    return this.isVisible;
  }

  /**
   * Sets or gets wether any drawing should be visible in this component
   * @deprecated use isVisible
   */
  function set_visible(val: Bool) {
    this.isVisible = val;
  }

  /**
   * Sets or gets wether any drawing should be visible in this component
   */
  public var isVisible: Bool = true;

  /**
   * Optionally force the graphic onscreen, default false. Not recommend to use for perf reasons, only if you known what you're doing.
   */
  public var forceOnScreen: Bool = false;

  /**
   * Sets or gets wither all drawings should have an opacity applied
   */
  public var opacity: Float = 1;

  private var _offset: Vector = new WatchVector(Vector.Zero, () -> this.recalculateBounds());

  /**
   * Offset to apply to graphics by default
   */
  public var offset(get, set): Vector;
  function get_offset(): Vector {
    return this._offset;
  }
  function set_offset(value: Vector) {
    this._offset = new WatchVector(value, () -> this.recalculateBounds());
    this.recalculateBounds();
  }

  private var _anchor: Vector = new WatchVector(Vector.Half, () -> this.recalculateBounds());

  /**
   * Anchor to apply to graphics by default
   */
  public var anchor(get, set): Vector;
  function get_anchor(): Vector {
    return this._anchor;
  }
  function set_anchor(value: Vector) {
    this._anchor = new WatchVector(value, () -> this.recalculateBounds());
    this.recalculateBounds();
  }

  /**
   * Sets the color of the actor's current graphic
   */
  public var color(get, set): Null<Color>;
  function get_color(): Null<Color> {
    return this._color;
  }
  function set_color(v: Null<Color>) {
    if (v) {
      this._color = v.clone();
      final currentGraphic = this.current;
      if (Std.isOfType(currentGraphic, Raster) || Std.isOfType(currentGraphic, Text)) {
        currentGraphic.color = this._color;
      }
    }
  }

  /**
   * Flip all graphics horizontally along the y-axis
   */
  public var flipHorizontal: Bool = false;

  /**
   * Flip all graphics vertically along the x-axis
   */
  public var flipVertical: Bool = false;

  /**
   * If set to true graphics added to the component will be copied. This can effect performance, but is useful if you don't want
   * changes to a graphic to effect all the places it is used.
   */
  public var copyGraphics: Bool = false;

  public function new(?options: GraphicsComponentOptions) {
    super();
    // Defaults
    options = Object.spreadWith({ visible: this.isVisible, graphics: {} }, options);

    final current = options.current,
          anchor = options.anchor,
          color = options.color,
          opacity = options.opacity,
          visible = options.visible,
          graphics = options.graphics,
          offset = options.offset,
          copyGraphics = options.copyGraphics,
          onPreDraw = options.onPreDraw,
          onPostDraw = options.onPostDraw,
          onPreTransformDraw = options.onPreTransformDraw,
          onPostTransformDraw = options.onPostTransformDraw;

    for (key => graphicOrOptions in Object.entries(graphics)) {
      if (Std.isOfType(graphicOrOptions, Graphic)) {
        this._graphics[key] = graphicOrOptions;
      } else {
        this._graphics[key] = graphicOrOptions.graphic;
        this._options[key] = graphicOrOptions.options;
      }
    }

    this.offset = offset ?? this.offset;
    this.opacity = opacity ?? this.opacity;
    this.anchor = anchor ?? this.anchor;
    this.color = color ?? this.color;
    this.copyGraphics = copyGraphics ?? this.copyGraphics;
    this.onPreDraw = onPreDraw ?? this.onPreDraw;
    this.onPostDraw = onPostDraw ?? this.onPostDraw;
    this.onPreDraw = onPreTransformDraw ?? this.onPreTransformDraw;
    this.onPostTransformDraw = onPostTransformDraw ?? this.onPostTransformDraw;
    this.isVisible = !!visible;
    this._current = current ?? this._current;
    if (current && this._graphics[current]) {
      this.use(current);
    }
  }

  public function getGraphic(name: String): Null<Graphic> {
    return this._graphics[name];
  }
  public function getOptions(name: String): Null<GraphicsShowOptions> {
    return this._options[name];
  }

  /**
   * Get registered graphics names
   */
  public function getNames(): Array<String> {
    return Object.keys(this._graphics);
  }

  /**
   * Returns the currently displayed graphic
   */
  public var current(get, never): Null<Graphic>;
  function get_current(): Null<Graphic> {
    return this._graphics[this._current];
  }

  /**
   * Returns the currently displayed graphic offsets
   */
  public var currentOptions(get, never): Null<GraphicsShowOptions>;
  function get_currentOptions() {
    return this._options[this._current];
  }

  /**
   * Returns all graphics associated with this component
   */
  public var graphics(get, never): Map<String, Graphic>;
  function get_graphics(): Map<String, Graphic> {
    return this._graphics;
  }

  /**
   * Returns all graphics options associated with this component
   */
  public var options(get, never): Map<String, Null<GraphicsShowOptions>>;
  function get_options() {
    return this._options;
  }

  /**
   * Adds a named graphic to this component, if the name is "default" or not specified, it will be shown by default without needing to call
   * @param graphic
   */
  public function add(name: String, graphic: Graphic, ?options: GraphicsShowOptions): Graphic {
    if (!graphic) {
      throw new Error('Need to provide a graphic or valid graphic string');
    }

    this._graphics[name] = this.copyGraphics ? graphic.clone() : graphic;
    this._options[name] = this.copyGraphics ? options : options;
    if (name == 'default') {
      this.use('default');
    }
    return graphic;
  }

  /**
   * Removes a registered graphic, if the removed graphic is the current it will switch to the default
   * @param name
   */
  public function remove(name: String) {
    this._graphics.delete(name);
    this._options.delete(name);
    if (this._current == name) {
      this._current = 'default';
      this.recalculateBounds();
    }
  }

  /**
   * Use a graphic only, will set the default graphic. Returns the new {@apilink Graphic}
   *
   * Optionally override the stored options
   * @param nameOrGraphic
   * @param options
   */
  public function use(name: String, ?options: GraphicsShowOptions): Graphic {
    this._current = nameOrGraphic;
    this._options[this._current] = options;
    if (!(this._current in this._graphics)) {
      this._logger.warn(
        'Graphic ${this._current} is not registered with the graphics component owned by ${this.owner?.name}. Nothing will be drawn.'
      );
    }
    this.recalculateBounds();
    return this.current;
  }

  /**
   * Hide currently shown graphic
   */
  public function hide(): Void {
    this._current = 'ex.none';
  }

  private var _localBounds: Null<BoundingBox>;

  /**
   * Get local bounds of graphics component
   */
  public var localBounds(get, set): Null<BoundingBox>;
  function get_localBounds() {
    if (!this._localBounds || this._localBounds.hasZeroDimensions()) {
      this.recalculateBounds();
    }
    return this._localBounds; // recalc guarantees type
  }
  function set_localBounds(bounds: Null<BoundingBox>) {
    this._localBounds = bounds;
  }

  public function recalculateBounds() {
    var bb = new BoundingBox();
    final graphic = this._graphics[this._current];
    final options = this._options[this._current];

    if (!graphic) {
      this._localBounds = bb;
      return;
    }

    var anchor = this.anchor;
    var offset = this.offset;
    if (options?.anchor) {
      anchor = options.anchor;
    }
    if (options?.offset) {
      offset = options.offset;
    }
    final bounds = graphic.localBounds;
    final offsetX = -bounds.width * anchor.x + offset.x;
    final offsetY = -bounds.height * anchor.y + offset.y;
    if (Std.isOfType(graphic, GraphicsGroup) && !graphic.useAnchor) {
      bb = graphic?.localBounds.combine(bb);
    } else {
      bb = graphic?.localBounds.translate(vec(offsetX, offsetY)).combine(bb);
    }
    this._localBounds = bb;
  }

  /**
   * Get world bounds of graphics component
   */
  public var bounds(get, never): BoundingBox;
  function get_bounds(): BoundingBox {
    var bounds = this.localBounds;
    if (this.owner) {
      final tx = this.owner.get(TransformComponent);
      if (tx) {
        bounds = bounds.transform(tx.get().matrix);
      }
    }
    return bounds;
  }

  /**
   * Update underlying graphics if necessary, called internally
   * @param elapsed
   * @internal
   */
  public function update(elapsed: Int, idempotencyToken: Int = 0) {
    final graphic = this.current;
    if (graphic && hasGraphicsTick(graphic)) {
      graphic.tick(elapsed, idempotencyToken);
    }
  }

  public function clone(): GraphicsComponent {
    final graphics = new GraphicsComponent();
    graphics._graphics = this._graphics;
    graphics._options = this._options;
    graphics.offset = this.offset.clone();
    if (this.color) {
      graphics.color = this.color.clone();
    }
    graphics.opacity = this.opacity;
    graphics.anchor = this.anchor.clone();
    graphics.copyGraphics = this.copyGraphics;
    graphics.onPreDraw = this.onPreDraw;
    graphics.onPostDraw = this.onPostDraw;
    graphics.isVisible = this.isVisible;

    return graphics;
  }
}
