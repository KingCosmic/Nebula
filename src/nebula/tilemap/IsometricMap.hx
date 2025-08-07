package nebula.tilemap;

import nebula.collision.BodyComponent;
import nebula.collision.BoundingBox;
import nebula.collision.ColliderComponent;
import nebula.collision.colliders.Collider;
import nebula.collision.CollisionType;
import nebula.collision.colliders.CompositeCollider;
import nebula.math.Vector;

import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;
import nebula.graphics.Graphic;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.graphics.GraphicsComponent;
import nebula.graphics.DebugGraphicsComponent;
import nebula.tilemap.IsometricEntityComponent;
import nebula.debug.DebugConfig;
import nebula.input.PointerComponent;
import nebula.input.PointerEvent;
import nebula.EventEmitter;
import nebula.input.PointerEventsToObjectDispatcher;
import nebula.input.PointerEventReceiver;

typedef TIsometricTilePointerEvents = {
  var pointerup: PointerEvent;
  var pointerdown: PointerEvent;
  var pointermove: PointerEvent;
  var pointercancel: PointerEvent;
  var pointerenter: PointerEvent;
  var pointerleave: PointerEvent;
};

class IsometricTile extends Entity {
  /**
   * Indicates whether this tile is solid
   */
  public var solid: Bool = false;

  public var events = new EventEmitter<EntityEvents & TIsometricTilePointerEvents>();

  private var _gfx: GraphicsComponent;
  private var _tileBounds = new BoundingBox();
  private var _graphics: Array<Graphic> = [];
  public function getGraphics(): Array<Graphic> {
    return this._graphics;
  }
  /**
   * Tile graphics
   */
  public function addGraphic(graphic: Graphic, ?options: { offset: Null<Vector> }) {
    this._graphics.push(graphic);
    this._gfx.isVisible = this.map.isVisible;
    this._gfx.opacity = this.map.opacity;
    if (options?.offset) {
      this._gfx.offset = options.offset;
    }
    // TODO detect when this changes on the map and apply to all tiles
    this._gfx.localBounds = this._recalculateBounds();
  }

  private function _recalculateBounds(): BoundingBox {
    var bounds = this._tileBounds.clone();
    for (graphic in this._graphics) {
      final offset = vec(
        this.map.graphicsOffset.x - this.map.tileWidth / 2,
        this.map.graphicsOffset.y - (this.map.renderFromTopOfGraphic ? 0 : graphic.height - this.map.tileHeight)
      );
      bounds = bounds.combine(graphic.localBounds.translate(offset));
    }
    return bounds;
  }

  public function removeGraphic(graphic: Graphic) {
    final index = this._graphics.indexOf(graphic);
    if (index > -1) {
      this._graphics.splice(index, 1);
    }
    this._gfx.localBounds = this._recalculateBounds();
  }

  public function clearGraphics() {
    this._graphics.length = 0;
    this._gfx.isVisible = false;
    this._gfx.localBounds = this._recalculateBounds();
  }

  /**
   * Tile colliders
   */
  private var _colliders: Array<Collider> = [];
  public function getColliders(): Array<Collider> {
    return this._colliders;
  }

  /**
   * Adds a collider to the IsometricTile
   *
   * **Note!** the {@apilink Tile.solid} must be set to true for it to act as a "fixed" collider
   * @param collider
   */
  public function addCollider(collider: Collider) {
    this._colliders.push(collider);
    this.map.flagCollidersDirty();
  }

  /**
   * Removes a collider from the IsometricTile
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
   * Clears all colliders from the IsometricTile
   */
  public function clearColliders(): Void {
    this._colliders.length = 0;
    this.map.flagCollidersDirty();
  }

  /**
   * Integer tile x coordinate
   */
  public var x: Int;
  /**
   * Integer tile y coordinate
   */
  public var y: Int;
  /**
   * Reference to the {@apilink IsometricMap} this tile is part of
   */
  public var map: IsometricMap;

  private var _transform: TransformComponent;
  private var _isometricEntityComponent: IsometricEntityComponent;

  /**
   * Returns the top left corner of the {@apilink IsometricTile} in world space
   */
  public var pos(get, never): Vector;
  public function get_pos(): Vector {
    return this.map.tileToWorld(vec(this.x, this.y));
  }

  /**
   * Returns the center of the {@apilink IsometricTile}
   */
  public var center(get, never): Vector;
  public function get_center(): Vector {
    return this.pos.add(vec(0, this.map.tileHeight / 2));
  }

  /**
   * Arbitrary data storage per tile, useful for any game specific data
   */
  public var data = new Map<String, Any>();

  /**
   * Construct a new IsometricTile
   * @param x tile coordinate in x (not world position)
   * @param y tile coordinate in y (not world position)
   * @param graphicsOffset offset that tile should be shifted by (default (0, 0))
   * @param map reference to owning IsometricMap
   */
  public function new(x: Int, y: Int, graphicsOffset: Null<Vector>, map: IsometricMap) {
    super([
      new TransformComponent(),
      new GraphicsComponent({
        offset: graphicsOffset ?? Vector.Zero,
        onPostDraw: (gfx, elapsed) -> this.draw(gfx, elapsed)
      }),
      new IsometricEntityComponent(map)
    ]);
    this.x = x;
    this.y = y;
    this.map = map;
    this._transform = this.get(TransformComponent);
    this._isometricEntityComponent = this.get(IsometricEntityComponent);

    final halfTileWidth = this.map.tileWidth / 2;
    final halfTileHeight = this.map.tileHeight / 2;
    // See https://clintbellanger.net/articles/isometric_math/ for formula
    // The x position shifts left with every y step
    final xPos = (this.x - this.y) * halfTileWidth;
    // The y position needs to go down with every x step
    final yPos = (this.x + this.y) * halfTileHeight;
    this._transform.pos = vec(xPos, yPos);
    this._isometricEntityComponent.elevation = map.elevation;

    this._gfx = this.get(GraphicsComponent);
    this._gfx.isVisible = false; // start not visible
    final totalWidth = this.map.tileWidth;
    final totalHeight = this.map.tileHeight;

    // initial guess at gfx bounds based on the tile
    final offset = vec(0, this.map.renderFromTopOfGraphic ? totalHeight : 0);
    this._gfx.localBounds = this._tileBounds = new BoundingBox({
      left: -totalWidth / 2,
      top: -totalHeight,
      right: totalWidth / 2,
      bottom: totalHeight
    }).translate(offset);
  }

  function draw(gfx: ExcaliburGraphicsContext, _elapsed: Int) {
    final halfTileWidth = this.map.tileWidth / 2;
    gfx.save();
    // shift left origin to corner of map, not the left corner of the first sprite
    gfx.translate(-halfTileWidth, 0);
    for (graphic in this._graphics) {
      graphic.draw(
        gfx,
        this.map.graphicsOffset.x,
        this.map.graphicsOffset.y - (this.map.renderFromTopOfGraphic ? 0 : graphic.height - this.map.tileHeight)
      );
    }
    gfx.restore();
  }
}

interface IsometricMapOptions {
  /**
   * Optionally name the isometric tile map
   */
  var name: Null<String>;
  /**
   * Optionally specify the position of the isometric tile map
   */
  var pos: Null<Vector>;
  /**
   * Optionally render from the top of the graphic, by default tiles are rendered from the bottom
   */
  var renderFromTopOfGraphic: Null<Bool>;
  /**
   * Optionally present a graphics offset, this can be useful depending on your tile graphics
   */
  var graphicsOffset: Null<Vector>;
  /**
   * Width of an individual tile in pixels, this should be the width of the parallelogram of the base of the tile art asset.
   */
  var tileWidth: Int;
  /**
   * Height of an individual tile in pixels, this should be the height of the parallelogram of the base of the tile art asset.
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

  var elevation: Null<Int>;
}

/**
 * The IsometricMap is a special tile map that provides isometric rendering support to Excalibur
 *
 * The tileWidth and tileHeight should be the height and width in pixels of the parallelogram of the base of the tile art asset.
 * The tileWidth and tileHeight is not necessarily the same as your graphic pixel width and height.
 *
 * Please refer to the docs https://excaliburjs.com for more details calculating what your tile width and height should be given
 * your art assets.
 */
class IsometricMap extends Entity implements HasNestedPointerEvents {
  public var elevation: Int = 0;

  /**
   * Width of individual tile in pixels
   */
  public var tileWidth: Int;
  /**
   * Height of individual tile in pixels
   */
  public var tileHeight: Int;
  /**
   * Number of tiles wide
   */
  public var columns: Int;
  /**
   * Number of tiles high
   */
  public var rows: Int;
  /**
   * List containing all of the tiles in IsometricMap
   */
  public var tiles: Array<IsometricTile>;

  /**
   * Whether tiles should be visible
   * @deprecated use isVisible
   */
  public var visible(get, set): Bool;
  function get_visible(): Bool {
    return this.isVisible;
  }

  /**
   * Whether tiles should be visible
   * @deprecated use isVisible
   */
  function set_visible(val: Bool) {
    this.isVisible = val;
  }

  /**
   * Whether tiles should be visible
   */
  public var isVisible = true;

  /**
   * Opacity of tiles
   */
  public var opacity = 1.0;

  /**
   * Render the tile graphic from the top instead of the bottom
   *
   * default is `false` meaning rendering from the bottom
   */
  public var renderFromTopOfGraphic: Bool = false;
  public var graphicsOffset: Vector = vec(0, 0);

  /**
   * Isometric map {@apilink TransformComponent}
   */
  public var transform: TransformComponent;

  /**
   * Isometric map {@apilink ColliderComponent}
   */
  public var collider: ColliderComponent;

  public var pointer: PointerComponent;

  private var _composite: CompositeCollider;
  private var _pointerEventDispatcher: PointerEventsToObjectDispatcher<IsometricTile>;

  public function new(options: IsometricMapOptions) {
    super(
      [
        new TransformComponent(),
        new BodyComponent({
          type: CollisionType.Fixed
        }),
        new ColliderComponent(),
        new PointerComponent(),
        new DebugGraphicsComponent((ctx, debugFlags) -> this.debug(ctx, debugFlags), false)
      ],
      options.name
    );
    final pos = options.pos,
          tileWidth = options.tileWidth,
          tileHeight = options.tileHeight,
          width = options.columns,
          height = options.rows,
          renderFromTopOfGraphic = options.renderFromTopOfGraphic,
          graphicsOffset = options.graphicsOffset,
          elevation = options.elevation;

    this.transform = this.get(TransformComponent);
    if (pos) {
      this.transform.pos = pos;
    }

    this.collider = this.get(ColliderComponent);
    if (this.collider) {
      this.collider.set((this._composite = new CompositeCollider([])));
    }

    this.pointer = this.get(PointerComponent);

    this.renderFromTopOfGraphic = renderFromTopOfGraphic ?? this.renderFromTopOfGraphic;
    this.graphicsOffset = graphicsOffset ?? this.graphicsOffset;

    this.elevation = elevation ?? this.elevation;
    this.tileWidth = tileWidth;
    this.tileHeight = tileHeight;
    this.columns = width;
    this.rows = height;

    this._pointerEventDispatcher = new PointerEventsToObjectDispatcher();

    this.tiles = new Array(width * height);

    // build up tile representation
    for (y in 0...height) {
      for (x in 0...width) {
        final tile = new IsometricTile(x, y, this.graphicsOffset, this);
        this.tiles[x + y * width] = tile;
        this.addChild(tile);
        this._pointerEventDispatcher.addObject(
          tile,
          (p) -> this.getTileByPoint(p.worldPos) == tile,
          () -> true
        );
      }
    }

    this.pointer.localBounds = BoundingBox.fromDimension(
      tileWidth * width * this.transform.scale.x,
      tileHeight * height * this.transform.scale.y,
      vec(0.5, 0)
    );
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

  public function update(): Void {
    if (this._collidersDirty) {
      this.updateColliders();
      this._collidersDirty = false;
    }

    this._pointerEventDispatcher.clear();
  }

  private var _collidersDirty = false;
  public function flagCollidersDirty() {
    this._collidersDirty = true;
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
  public function updateColliders() {
    this._composite.clearColliders();
    final pos = this.get(TransformComponent).pos;
    for (tile in  this.tiles) {
      if (tile.solid) {
        for (collider in tile.getColliders()) {
          final originalOffset = this._getOrSetColliderOriginalOffset(collider);
          collider.offset = this.tileToWorld(vec(tile.x, tile.y))
            .sub(pos)
            .add(originalOffset)
            .sub(vec(this.tileWidth / 2, this.tileHeight)); // We need to unshift height based on drawing
          collider.owner = this;
          this._composite.addCollider(collider);
        }
      }
    }
    this.collider.update();
  }

  /**
   * Convert world space coordinates to the tile x, y coordinate
   * @param worldCoordinate
   */
  public function worldToTile(worldCoordinate: Vector): Vector {
    // TODO I don't think this handles parent transform see TileMap
    worldCoordinate = worldCoordinate.sub(this.transform.globalPos);

    final halfTileWidth = this.tileWidth / 2;
    final halfTileHeight = this.tileHeight / 2;
    // See https://clintbellanger.net/articles/isometric_math/ for formula
    return vec(
      ~~((worldCoordinate.x / halfTileWidth + worldCoordinate.y / halfTileHeight) / 2),
      ~~((worldCoordinate.y / halfTileHeight - worldCoordinate.x / halfTileWidth) / 2)
    );
  }

  /**
   * Given a tile coordinate, return the top left corner in world space
   * @param tileCoordinate
   */
  public function tileToWorld(tileCoordinate: Vector): Vector {
    final halfTileWidth = this.tileWidth / 2;
    final halfTileHeight = this.tileHeight / 2;
    // The x position shifts left with every y step
    final xPos = (tileCoordinate.x - tileCoordinate.y) * halfTileWidth;
    // The y position needs to go down with every x step
    final yPos = (tileCoordinate.x + tileCoordinate.y) * halfTileHeight;
    return vec(xPos, yPos).add(this.transform.pos);
  }

  /**
   * Returns the {@apilink IsometricTile} by its x and y coordinates
   */
  public function getTile(x: Int, y: Int): Null<IsometricTile> {
    if (x < 0 || y < 0 || x >= this.columns || y >= this.rows) {
      return null;
    }
    return this.tiles[x + y * this.columns];
  }

  /**
   * Returns the {@apilink IsometricTile} by testing a point in world coordinates,
   * returns `null` if no Tile was found.
   */
  public function getTileByPoint(point: Vector): Null<IsometricTile> {
    final tileCoord = this.worldToTile(point);
    final tile = this.getTile(tileCoord.x, tileCoord.y);
    return tile;
  }

  private function _getMaxZIndex(): Int {
    var maxZ = Number.NEGATIVE_INFINITY;
    for (tile in this.tiles) {
      final currentZ = tile.get(TransformComponent).z;
      if (currentZ > maxZ) {
        maxZ = currentZ;
      }
    }
    return maxZ;
  }

  /**
   * Debug draw for IsometricMap, called internally by excalibur when debug mode is toggled on
   * @param gfx
   */
  public function debug(gfx: ExcaliburGraphicsContext, debugFlags: DebugConfig) {
    final showAll = debugFlags.isometric.showAll,
          showPosition = debugFlags.isometric.showPosition,
          positionColor = debugFlags.isometric.positionColor,
          positionSize = debugFlags.isometric.positionSize,
          showGrid = debugFlags.isometric.showGrid,
          gridColor = debugFlags.isometric.gridColor,
          gridWidth = debugFlags.isometric.gridWidth,
          showColliderGeometry = debugFlags.isometric.showColliderGeometry;

    final geometryColor = debugFlags.collider.geometryColor,
          geometryLineWidth = debugFlags.collider.geometryLineWidth,
          geometryPointSize = debugFlags.collider.geometryPointSize;

    gfx.save();
    gfx.z = this._getMaxZIndex() + 0.5;
    if (showAll || showGrid) {
      for (y in 0...this.rows + 1) {
        final left = this.tileToWorld(vec(0, y));
        final right = this.tileToWorld(vec(this.columns, y));
        gfx.drawLine(left, right, gridColor, gridWidth);
      }

      for (x in 0...this.columns + 1) {
        final top = this.tileToWorld(vec(x, 0));
        final bottom = this.tileToWorld(vec(x, this.rows));
        gfx.drawLine(top, bottom, gridColor, gridWidth);
      }
    }

    if (showAll || showPosition) {
      for (tile in this.tiles) {
        gfx.drawCircle(this.tileToWorld(vec(tile.x, tile.y)), positionSize, positionColor);
      }
    }
    if (showAll || showColliderGeometry) {
      for (tile in this.tiles) {
        if (tile.solid) {
          // only draw solid tiles
          for (collider in tile.getColliders()) {
            collider.debug(gfx, geometryColor, { lineWidth: geometryLineWidth, pointSize: geometryPointSize });
          }
        }
      }
    }
    gfx.restore();
  }
}
