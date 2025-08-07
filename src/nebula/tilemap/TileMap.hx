package nebula.tilemap;

import nebula.collision.BoundingBox;
import nebula.Engine;
import nebula.math.Vector;
import nebula.util.Log;
import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.collision.BodyComponent;
import nebula.collision.CollisionType;
import nebula.collision.colliders.Shape;
import nebula.graphics.Graphic;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.collision.ColliderComponent;
import nebula.collision.colliders.CompositeCollider;
import nebula.graphics.DebugGraphicsComponent;
import nebula.collision.colliders.Collider;
import nebula.Events;
import nebula.EventEmitter;
import nebula.math.CoordPlane;
import nebula.debug.DebugConfig;
import nebula.math.Util;
import nebula.input.PointerComponent;
import nebula.input.PointerEvent;
import nebula.input.PointerEventReceiver;
import nebula.input.PointerEventsToObjectDispatcher;
import nebula.math.GlobalCoordinates;

interface TileMapOptions {
  /**
   * Optionally name the tile map
   */
  var name: Null<String>;
  /**
   * Optionally specify the position of the tile map
   */
  var pos: Null<Vector>;
  /**
   * Width of an individual tile in pixels
   */
  var tileWidth: Int;
  /**
   * Height of an individual tile in pixels
   */
  var tileHeight: Int;
  /**
   * The number of tile columns, or the number of tiles wide
   */
  var columns: Int;
  /**
   * The number of tile  rows, or the number of tiles high
   */
  var rows: Int;

  /**
   * Optionally render from the top of the graphic, by default tiles are rendered from the bottom
   */
  var renderFromTopOfGraphic: Null<Bool>;

  /**
   * Optionally configure the meshing lookbehind for Tilemap, Tilemaps combine solid tiles into optimal
   * geometry and the lookbehind configures how far back the Tilemap to look for geometry when combining. Meshing
   * is an expensive operation, so when the Tilemap geometry is invalidated it must be recalculated.
   *
   * Default is 10 slots, but if your Tilemap does not change positions or solid tiles often you can increase this to
   * Infinity.
   */
  var meshingLookBehind: Null<Int>;
}

typedef TTilePointerEvents = {
  var pointerup: PointerEvent;
  var pointerdown: PointerEvent;
  var pointermove: PointerEvent;
  var pointercancel: PointerEvent;
  var pointerenter: PointerEvent;
  var pointerleave: PointerEvent;
};

typedef TTileMapEvents = TEntityEvents &
  TTilePointerEvents & {
    var preupdate: PreUpdateEvent<TileMap>;
    var postupdate: PostUpdateEvent<TileMap>;
    var predraw: PreDrawEvent;
    var postdraw: PostDrawEvent;
  };

final TileMapEvents = {
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate',
  PreDraw: 'predraw',
  PostDraw: 'postdraw',
  PointerUp: 'pointerup',
  PointerDown: 'pointerdown',
  PointerMove: 'pointermove',
  PointerCancel: 'pointercancel'
};

/**
 * The TileMap provides a mechanism for doing flat 2D tiles rendered in a grid.
 *
 * TileMaps are useful for top down or side scrolling grid oriented games.
 */
class TileMap extends Entity implements HasNestedPointerEvents {
  public var events = new EventEmitter();
  private var _token: Int = 0;
  private var _engine: Engine;

  public var logger: Logger = Logger.getInstance();
  public var tiles: Array<Tile> = [];
  private var _rows: Array<Array<Tile>> = [];
  private var _cols: Array<Array<Tile>> = [];

  public var tileWidth: Int;
  public var tileHeight: Int;
  public var rows: Int;
  public var columns: Int;

  public var renderFromTopOfGraphic = false;
  public var meshingLookBehind = 10;

  private var _collidersDirty = true;
  private var _pointerEventDispatcher: PointerEventsToObjectDispatcher<Tile>;
  public function flagCollidersDirty() {
    this._collidersDirty = true;
  }

  public function flagTilesDirty(): Void {
    for (i in 0...this.tiles.length) {
      if (this.tiles[i]) {
        this.tiles[i].flagDirty();
      }
    }
  }

  public var pointer: PointerComponent;
  public var transform: TransformComponent;
  private var _motion: MotionComponent;
  private var _graphics: GraphicsComponent;
  public var collider: ColliderComponent;
  private var _composite: CompositeCollider;

  public var x(get, set): Int;
  function get_x(): Int {
    return this.transform.pos.x ?? 0;
  }
  function set_x(val: Int) {
    if (this.transform?.pos) {
      this.get(TransformComponent).pos = vec(val, this.y);
    }
  }

  public var y(get, set): Int;
  function get_y(): Int {
    return this.transform?.pos.y ?? 0;
  }
  function set_y(val: Int) {
    if (this.transform?.pos) {
      this.transform.pos = vec(this.x, val);
    }
  }

  public var z(get, set): Int;
  function get_z(): Int {
    return this.transform.z ?? 0;
  }
  function set_z(val: Int) {
    if (this.transform) {
      this.transform.z = val;
    }
  }

  private var _oldRotation: Int = 0;
  public var rotation(get, set): Int;
  function get_rotation(): Int {
    return this.transform?.rotation ?? 0;
  }
  function set_rotation(val: Int) {
    if (this.transform) {
      if (val != this.transform.rotation) {
        this.flagCollidersDirty();
        this.flagTilesDirty();
      }
      this.transform.rotation = val;
    }
  }

  private var _oldScale: Vector;
  public var scale(get, set): Vector;
  function get_scale(): Vector {
    return this.transform?.scale ?? Vector.One;
  }
  function set_scale(val: Vector) {
    if (this.transform) {
      if (!val?.equals(this.transform.scale)) {
        this.flagCollidersDirty();
        this.flagTilesDirty();
      }
      this.transform.scale = val;
    }
  }

  private var _oldPos: Vector;
  public var pos(get, set): Vector;
  function get_pos(): Vector {
    return this.transform.pos;
  }
  function set_pos(val: Vector) {
    if (this.transform) {
      if (!val?.equals(this.transform.pos)) {
        this.flagCollidersDirty();
        this.flagTilesDirty();
      }
      this.transform.pos = val;
    }
  }

  public var vel(get, set): Vector;
  function get_vel(): Vector {
    return this._motion.vel;
  }
  function set_vel(val: Vector) {
    this._motion.vel = val;
  }

  /**
   * Width of the whole tile map in pixels
   */
  public var width(get, never): Int;
  function get_width(): Int {
    return this.tileWidth * this.columns * this.scale.x;
  }

  /**
   * Height of the whole tilemap in pixels
   */
  public var height(get, never): Int;
  function get_height(): Int {
    return this.tileHeight * this.rows * this.scale.y;
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    this.events.off(eventName, handler);
  }

  /**
   * @param options
   */
  public function new(options: TileMapOptions) {
    super([], options.name);
    this.meshingLookBehind = options.meshingLookBehind ?? this.meshingLookBehind;
    this.addComponent(new TransformComponent());
    this.addComponent(new MotionComponent());
    this.addComponent(
      new BodyComponent({
        type: CollisionType.Fixed
      })
    );
    this.addComponent(
      new GraphicsComponent({
        onPostDraw: (ctx, elapsed) -> this.draw(ctx, elapsed)
      })
    );
    this.addComponent(new DebugGraphicsComponent((ctx, debugFlags) -> this.debug(ctx, debugFlags), false));
    this.addComponent(new ColliderComponent());
    this.addComponent(new PointerComponent());
    this.pointer = this.get(PointerComponent);
    this._graphics = this.get(GraphicsComponent);
    this.transform = this.get(TransformComponent);
    this._motion = this.get(MotionComponent);
    this.collider = this.get(ColliderComponent);
    this._composite = this.collider.useCompositeCollider([]);

    this.transform.pos = options.pos ?? Vector.Zero;
    this._oldPos = this.transform.pos.clone();
    this._oldScale = this.transform.scale.clone();
    this.renderFromTopOfGraphic = options.renderFromTopOfGraphic ?? this.renderFromTopOfGraphic;
    this.tileWidth = options.tileWidth;
    this.tileHeight = options.tileHeight;
    this.rows = options.rows;
    this.columns = options.columns;

    this._pointerEventDispatcher = new PointerEventsToObjectDispatcher();

    this.tiles = new Array<Tile>(this.rows * this.columns);
    this._rows = new Array(this.rows);
    this._cols = new Array(this.columns);
    var currentCol: Array<Tile> = [];
    for (i in 0...this.columns) {
      for (j in 0...this.rows) {
        final tile = new Tile({
          x: i,
          y: j,
          map: this
        });
        tile.map = this;
        this.tiles[i + j * this.columns] = tile;
        this._pointerEventDispatcher.addObject(
          tile,
          (vec: GlobalCoordinates) -> {
            // TODO handle geometry/graphics
            return tile.bounds.contains(vec.worldPos);
          },
          () -> true
        );
        currentCol.push(tile);
        if (!this._rows[j]) {
          this._rows[j] = [];
        }
        this._rows[j].push(tile);
      }
      this._cols[i] = currentCol;
      currentCol = [];
    }

    this._graphics.localBounds = new BoundingBox({
      left: 0,
      top: 0,
      right: this.columns * this.tileWidth * this.scale.x,
      bottom: this.rows * this.tileHeight * this.scale.y
    });
  }

  public function _initialize(engine: Engine) {
    super._initialize(engine);
    this._engine = engine;
  }

  private var _originalOffsets = new WeakMap<Collider, Vector>();
  private function _getOrSetColliderOriginalOffset(collider: Collider): Vector {
    if (!this._originalOffsets.has(collider)) {
      final originalOffset = collider.offset;
      this._originalOffsets.set(collider, originalOffset);
      return originalOffset;
    } else {
      return this._originalOffsets.get(collider) ?? Vector.Zero;
    }
  }

  /**
   * Tiles colliders based on the solid tiles in the tilemap.
   */
  private function _updateColliders(): Void {
    this.collider.$colliderRemoved.notifyAll(this._composite);
    this._composite.clearColliders();
    final colliders: Array<BoundingBox> = [];
    this._composite = this.collider.useCompositeCollider([]);
    var current: Null<BoundingBox> = null;

    /**
     * Returns wether or not the 2 boxes share an edge and are the same height
     * @param prev
     * @param next
     * @returns true if they share and edge, false if not
     */
    final shareEdges = (prev: BoundingBox, next: BoundingBox) -> {
      if (prev && next) {
        // same top/bottom
        return (
          prev.top == next.top &&
          prev.bottom == next.bottom &&
          // Shared right/left edge
          prev.right == next.left
        );
      }
      return false;
    };

    /**
     * Potentially merges the current collider into a list of previous ones, mutating the list
     * If checkAndCombine returns true, the collider was successfully merged and should be thrown away
     * @param current current collider to test
     * @param colliders List of colliders to consider merging with
     * @param maxLookBack The amount of colliders to look back for combination
     * @returns false when no combination found, true when successfully combined
     */
    final checkAndCombine = (current: BoundingBox, colliders: Array<BoundingBox>, maxLookBack = this.meshingLookBehind) -> {
      if (!current) {
        return false;
      }

      // walk backwards through the list of colliders and combine with the first that shares an edge
      var i = colliders.length - 1;
      while (i >= 0) {
        if (maxLookBack-- < 0) {
          // blunt the O(n^2) algorithm a bit
          return false;
        }
        final prev = colliders[i];
        if (shareEdges(prev, current)) {
          colliders[i] = prev.combine(current);
          return true;
        }
        i--;
      }
      return false;
    };

    // ? configurable bias perhaps, horizontal strips vs. vertical ones
    // Bad tile collider packing algorithm
    for (i in 0...this.columns) {
      // Scan column for colliders
      for (j in 0...this.rows) {
        final tile = this.tiles[i + j * this.columns];
        // Current tile in column is solid build up current collider
        if (tile.solid) {
          // Use custom collider otherwise bounding box
          if (tile.getColliders().length > 0) {
            // tile with custom collider interrupting the current run
            for (collider in tile.getColliders()) {
              final originalOffset = this._getOrSetColliderOriginalOffset(collider);
              collider.offset = vec(tile.x * this.tileWidth * this.scale.x, tile.y * this.tileHeight * this.scale.y).add(originalOffset);
              collider.owner = this;
              this._composite.addCollider(collider);
            }
            //we push any current collider before nulling the current run
            if (current && !checkAndCombine(current, colliders)) {
              colliders.push(current);
            }
            current = null;
            // Use the bounding box
          } else {
            if (!current) {
              // no current run, start one
              current = tile.defaultGeometry;
            } else {
              // combine with current run
              current = current.combine(tile.defaultGeometry);
            }
          }
        } else {
          // Not solid skip and cut off the current collider
          // End of run check and combine
          if (current && !checkAndCombine(current, colliders)) {
            colliders.push(current);
          }
          current = null;
        }
      }
      // After a column is complete check to see if it can be merged into the last one
      // Eno of run check and combine
      if (current && !checkAndCombine(current, colliders)) {
        // else new collider if no combination
        colliders.push(current);
      }
      current = null;
    }

    for (c in colliders) {
      final collider = Shape.Box(c.width, c.height, Vector.Zero, vec(c.left - this.pos.x, c.top - this.pos.y));
      collider.owner = this;
      this._composite.addCollider(collider);
    }
    this.collider.update();
    // Notify that colliders have been updated
    this.collider.$colliderAdded.notifyAll(this._composite);
  }

  /**
   * Returns the {@apilink Tile} by index (row major order)
   *
   * Returns null if out of bounds
   */
  public function getTileByIndex(index: Int): Null<Tile> {
    return this.tiles[index] ?? null;
  }
  /**
   * Returns the {@apilink Tile} by its x and y integer coordinates
   *
   * Returns null if out of bounds
   *
   * For example, if I want the tile in fifth column (x), and second row (y):
   * `getTile(4, 1)` 0 based, so 0 is the first in row/column
   */
  public function getTile(x: Int, y: Int): Null<Tile> {
    if (x < 0 || y < 0 || x >= this.columns || y >= this.rows) {
      return null;
    }
    return this.tiles[x + y * this.columns];
  }
  /**
   * Returns the {@apilink Tile} by testing a point in world coordinates,
   * returns `null` if no Tile was found.
   */
  public function getTileByPoint(point: Vector): Null<Tile> {
    final coords = this._getTileCoordinates(point);
    final x = coords.x,
          y = coords.y;

    final tile = this.getTile(x, y);
    if (x >= 0 && y >= 0 && x < this.columns && y < this.rows && tile) {
      return tile;
    }
    return null;
  }

  private function _getTileCoordinates(point: Vector): { x: Int, y: Int } {
    // Convert to Tile Space point
    point = this.transform.applyInverse(point);

    final x = Math.floor(point.x / this.tileWidth);
    final y = Math.floor(point.y / this.tileHeight);
    return { x: x, y: y };
  }

  public function getRows(): Array<Array<Tile>> {
    return this._rows;
  }

  public function getColumns(): Array<Array<Tile>> {
    return this._cols;
  }

  /**
   * Returns the on screen tiles for a tilemap, this will overshoot by a small amount because of the internal quad tree data structure.
   *
   * Useful if you need to perform specific logic on onscreen tiles
   */
  public function getOnScreenTiles(): Array<Tile> {
    final worldBounds = this._engine.screen.getWorldBounds();
    var parallaxOffset = vec(0, 0);
    var bounds = this.transform.coordPlane == CoordPlane.Screen ? this._engine.screen.getScreenBounds() : worldBounds;
    final maybeParallax = this.get(ParallaxComponent);
    if (maybeParallax && this.isInitialized) {
      final oneMinusFactor = Vector.One.sub(maybeParallax.parallaxFactor);
      parallaxOffset = this._engine.currentScene.camera.pos.scale(oneMinusFactor);
      bounds = bounds.translate(parallaxOffset.negate());
    }

    final topLeft = this._getTileCoordinates(bounds.topLeft);
    final topRight = this._getTileCoordinates(bounds.topRight);
    final bottomRight = this._getTileCoordinates(bounds.bottomRight);
    final bottomLeft = this._getTileCoordinates(bounds.bottomLeft);

    final tileStartX = Math.min(clamp(topLeft.x, 0, this.columns - 1), clamp(topRight.x, 0, this.columns - 1));
    final tileStartY = Math.min(clamp(topLeft.y, 0, this.rows - 1), clamp(topRight.y, 0, this.rows - 1));
    final tileEndX = Math.max(clamp(bottomRight.x, 0, this.columns - 1), clamp(bottomLeft.x, 0, this.columns - 1));
    final tileEndY = Math.max(clamp(bottomRight.y, 0, this.rows - 1), clamp(bottomLeft.y, 0, this.rows - 1));

    final tiles: Array<Tile> = [];
    for (x in tileStartX...tileEndX + 1) {
      for (y in tileStartY...tileEndY + 1) {
        tiles.push(this.getTile(x, y)!);
      }
    }
    return tiles;
  }

  /**
   * @internal
   */
  public function _processPointerToObject(receiver: PointerEventReceiver) {
    this._pointerEventDispatcher.processPointerToObject(receiver, this.tiles);
  }

  /**
   * @internal
   */
  public function _dispatchPointerEvents(receiver: PointerEventReceiver) {
    this._pointerEventDispatcher.dispatchEvents(receiver, this.tiles);
  }

  public function update(engine: Engine, elapsed: Int) {
    this._initialize(engine);
    this.onPreUpdate(engine, elapsed);
    this.emit('preupdate', new PreUpdateEvent(engine, elapsed, this));

    // Update colliders
    if (!this._oldPos.equals(this.pos) || this._oldRotation != this.rotation || !this._oldScale.equals(this.scale)) {
      this.flagCollidersDirty();
      this.flagTilesDirty();
    }
    if (this._collidersDirty) {
      this._collidersDirty = false;
      this._updateColliders();
    }

    // Clear last frame's events
    this._pointerEventDispatcher.clear();

    this._token++;

    this.pos.clone(this._oldPos);
    this._oldRotation = this.rotation;
    this.scale.clone(this._oldScale);
    this.transform.pos = this.pos;
    this.onPostUpdate(engine, elapsed);
    this.emit('postupdate', new PostUpdateEvent(engine, elapsed, this));
  }

  /**
   * Draws the tile map to the screen. Called by the {@apilink Scene}.
   * @param ctx ExcaliburGraphicsContext
   * @param elapsed  The number of milliseconds since the last draw
   */
  public function draw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void {
    if (!this.isInitialized) {
      return;
    }
    this.emit('predraw', new PreDrawEvent(ctx, elapsed, this)); // TODO fix event

    var graphics: Array<Graphic>, graphicsIndex: Int, graphicsLen: Int;

    final tiles = this.getOnScreenTiles();
    for (tile in tiles) {
      // get non-negative tile sprites
      final offsets = tile.getGraphicsOffsets();
      graphics = tile.getGraphics();

      for (graphicsIndex in 0...graphics.length) {
        // draw sprite, warning if sprite doesn't exist
        final graphic = graphics[graphicsIndex];
        final offset = offsets[graphicsIndex];
        if (graphic) {
          if (hasGraphicsTick(graphic)) {
            graphic?.tick(elapsed, this._token);
          }
          final offsetY = this.renderFromTopOfGraphic ? 0 : graphic.height - this.tileHeight;
          graphic.draw(ctx, tile.x * this.tileWidth + offset.x, tile.y * this.tileHeight - offsetY + offset.y);
        }
      }
    }
    this.emit('postdraw', new PostDrawEvent(ctx, elapsed, this));
  }

  public function debug(gfx: ExcaliburGraphicsContext, debugFlags: DebugConfig) {
    final showAll = debugFlags.tilemap.showAll,
          showGrid = debugFlags.tilemap.showGrid,
          gridColor = debugFlags.tilemap.gridColor,
          gridwidth = debugFlags.tilemap.gridwidth,
          showColliderBounds = debugFlags.tilemap.showSolidBounds,
          colliderBoundsColor = debugFlags.tilemap.colliderBoundsColor,
          showColliderGeometry = debugFlags.tilemap.showColliderGeometry;

    final geometryColor = debugFlags.collider.geometryColor,
          geometryLineWidth = debugFlags.collider.geometryLineWidth,
          geometryPointSize = debugFlags.collider.geometryPointSize;

    final width = this.tileWidth * this.columns * this.scale.x;
    final height = this.tileHeight * this.rows * this.scale.y;
    final pos = this.pos;
    if (showGrid || showAll) {
      for (r in 0...this.rows + 1) {
        final yOffset = vec(0, r * this.tileHeight * this.scale.y);
        gfx.drawLine(pos.add(yOffset), pos.add(vec(width, yOffset.y)), gridColor, gridWidth);
      }

      for (c in 0...this.columns + 1) {
        final xOffset = vec(c * this.tileWidth * this.scale.x, 0);
        gfx.drawLine(pos.add(xOffset), pos.add(vec(xOffset.x, height)), gridColor, gridWidth);
      }
    }

    if (showAll || showColliderBounds || showColliderGeometry) {
      final colliders = this._composite.getColliders();
      gfx.save();
      gfx.translate(this.pos.x, this.pos.y);
      gfx.scale(this.scale.x, this.scale.y);
      for (collider in colliders) {
        final bounds = collider.localBounds;
        final pos = collider.worldPos.sub(this.pos);
        if (showColliderBounds) {
          gfx.drawRectangle(pos, bounds.width, bounds.height, colliderBoundsColor);
        }
      }
      gfx.restore();
      if (showColliderGeometry) {
        for (collider in colliders) {
          collider.debug(gfx, geometryColor, { lineWidth: geometryLineWidth, pointSize: geometryPointSize });
        }
      }
    }

    if (showAll || showColliderBounds) {
      gfx.save();
      gfx.z = 999;
      if (showColliderBounds) {
        for (tile in this.tiles) {
          tile.bounds.draw(gfx);
        }
      }
      gfx.restore();
    }
  }
}

interface TileOptions {
  /**
   * Integer tile x coordinate
   */
  var x: Int;
  /**
   * Integer tile y coordinate
   */
  var y: Int;
  var map: TileMap;
  var solid: Null<Bool>;
  var graphics: Array<Graphic>;
}

/**
 * TileMap Tile
 *
 * A light-weight object that occupies a space in a collision map. Generally
 * created by a {@apilink TileMap}.
 *
 * Tiles can draw multiple sprites. Note that the order of drawing is the order
 * of the sprites in the array so the last one will be drawn on top. You can
 * use transparency to create layers this way.
 */
class Tile {
  private var _bounds: BoundingBox;
  private var _geometry: BoundingBox;
  private var _pos: Vector;
  private var _posDirty = false;

  public var events = new EventEmitter<TilePointerEvents>();

  /**
   * Return the world position of the top left corner of the tile
   */
  public var pos(get, never): Int;
  function get_pos() {
    if (this._posDirty) {
      this._recalculate();
      this._posDirty = false;
    }
    return this._pos;
  }

  /**
   * Integer x coordinate of the tile
   */
  public var x: Int;

  /**
   * Integer y coordinate of the tile
   */
  public var y: Int;

  private var _width: Int;
  /**
   * Width of the tile in pixels
   */
  public var width(get, never): Int;
  function get_width(): Int {
    return this._width;
  }

  private var _height: Int;
  /**
   * Height of the tile in pixels
   */
  public var height(get, never): Int;
  function get_height(): Int {
    return this._height;
  }

  /**
   * Reference to the TileMap this tile is associated with
   */
  public var map: TileMap;

  private var _solid = false;
  /**
   * Wether this tile should be treated as solid by the tilemap
   */
  public var solid(get, set): Bool;
  function get_solid(): Bool {
    return this._solid;
  }
  /**
   * Wether this tile should be treated as solid by the tilemap
   */
  function set_solid(val: Bool) {
    this.map?.flagCollidersDirty();
    this._solid = val;
  }

  private var _graphics: Array<Graphic> = [];
  private var _offsets: Array<Vector> = [];

  /**
   * Current list of graphics for this tile
   */
  public function getGraphics(): Array<Graphic> {
    return this._graphics;
  }

  /**
   * Current list of offsets for this tile's graphics
   */
  public function getGraphicsOffsets(): Array<Vector> {
    return this._offsets;
  }

  /**
   * Add another {@apilink Graphic} to this TileMap tile
   * @param graphic
   */
  public function addGraphic(graphic: Graphic, ?options: { offset: Null<Vector> }) {
    this._graphics.push(graphic);
    if (options.offset != null) {
      this._offsets.push(options.offset);
    } else {
      this._offsets.push(Vector.Zero);
    }
  }

  /**
   * Remove an instance of a {@apilink Graphic} from this tile
   */
  public function removeGraphic(graphic: Graphic) {
    final index = this._graphics.indexOf(graphic);
    if (index > -1) {
      this._graphics.splice(index, 1);
      this._offsets.splice(index, 1);
    }
  }

  /**
   * Clear all graphics from this tile
   */
  public function clearGraphics() {
    this._graphics.length = 0;
    this._offsets.length = 0;
  }

  /**
   * Current list of colliders for this tile
   */
  private var _colliders: Array<Collider> = [];

  /**
   * Returns the list of colliders
   */
  public function getColliders(): Array<Collider> {
    return this._colliders;
  }

  /**
   * Adds a custom collider to the {@apilink Tile} to use instead of it's bounds
   *
   * If no collider is set but {@apilink Tile.solid} is set, the tile bounds are used as a collider.
   *
   * **Note!** the {@apilink Tile.solid} must be set to true for it to act as a "fixed" collider
   * @param collider
   */
  public function addCollider(collider: Collider) {
    this._colliders.push(collider);
    this.map.flagCollidersDirty();
  }

  /**
   * Removes a collider from the {@apilink Tile}
   * @param collider
   */
  public function removeCollider(collider: Collider) {
    final index = this._colliders.indexOf(collider);
    if (index > -1) {
      this._colliders.splice(index, 1);
    }
    this.map.flagCollidersDirty();
  }

  /**
   * Clears all colliders from the {@apilink Tile}
   */
  public function clearColliders() {
    this._colliders.length = 0;
    this.map.flagCollidersDirty();
  }

  /**
   * Arbitrary data storage per tile, useful for any game specific data
   */
  public var data = new Map<String, Any>();

  public function new(options: TileOptions) {
    this.x = options.x;
    this.y = options.y;
    this.map = options.map;
    this._width = options.map.tileWidth * this.map.scale.x;
    this._height = options.map.tileHeight * this.map.scale.y;
    this.solid = options.solid ?? this.solid;
    this._graphics = options.graphics ?? [];
    this._recalculate();
  }

  public function flagDirty(): Void {
    this._posDirty = true;
  }

  private function _recalculate(): Void {
    final geometryPos = this.map.pos.add(vec(this.x * this.map.tileWidth, this.y * this.map.tileHeight));
    this._geometry = new BoundingBox(geometryPos.x, geometryPos.y, geometryPos.x + this.map.tileWidth, geometryPos.y + this.map.tileHeight);

    this._width = this.map.tileWidth * this.map.scale.x;
    this._height = this.map.tileHeight * this.map.scale.y;

    this._pos = this.map.pos.add(vec(this.x * this._width, this.y * this._height));
    this._bounds = new BoundingBox(this._pos.x, this._pos.y, this._pos.x + this._width, this._pos.y + this._height);

    if (this.map.rotation) {
      this._bounds = this._bounds.rotate(this.map.rotation, this.map.pos);
    }
    this._posDirty = false;
  }

  /**
   * Tile bounds in world space
   */
  public var bounds(get, never): BoundingBox;
  function get_bounds(): BoundingBox {
    if (this._posDirty) {
      this._recalculate();
    }
    return this._bounds;
  }

  public var defaultGeometry(get, never): BoundingBox;
  function get_defaultGeometry(): BoundingBox {
    return this._geometry;
  }

  /**
   * Tile position in world space
   */
  public var center(get, never): Vector;
  function get_center(): Vector {
    if (this._posDirty) {
      this._recalculate();
    }
    return new Vector(this._pos.x + this._width / 2, this._pos.y + this._height / 2);
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    if (handler) {
      this.events.off(eventName, handler);
    } else {
      this.events.off(eventName);
    }
  }
}
