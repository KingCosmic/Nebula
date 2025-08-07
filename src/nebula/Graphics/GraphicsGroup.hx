package nebula.graphics;

import nebula.graphics.Graphic;
import nebula.graphics.Animation;
import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.collision.BoundingBox;

import nebula.util.Log;

import nebula.math.Vector;

interface GraphicsGroupingOptions {
  var members: Array<Graphic>;
  /**
   * Default true, GraphicsGroup will use the anchor to position all the graphics based on their combined bounds
   *
   * Setting to false will ignore anchoring from parent components and position the top left of all graphics at the actor's position,
   * positioning graphics in the group is done with the `offset` property.
   */
  var useAnchor: Null<Bool>;
}

interface GraphicsGrouping {
  var offset: Vector;
  var graphic: Graphic;
  /**
   * Optionally disable this graphics bounds as part of group calculation, default true
   * if unspecified
   *
   * You may want disable this if you're using text because their bounds will affect
   * the centering of the whole group.
   *
   * **WARNING** having inaccurate bounds can cause offscreen culling issues.
   */
  var useBounds: Null<Bool>;
}

class GraphicsGroup extends Graphic implements HasTick {
  private var _logger = Logger.getInstance();
  public var useAnchor: Bool = true;
  public var members: Array<Graphic> = [];

  public function new(options: GraphicsGroupingOptions & GraphicOptions) {
    super(options);
    this.members = options.members;
    this.useAnchor = options.useAnchor ?? this.useAnchor;
    this._updateDimensions();
  }

  public function clone(): GraphicsGroup {
    var config = Object.spreadWith(
      { members: this.members },
      this.cloneGraphicOptions()
    );

    return new GraphicsGroup(config);
  }

  private function _updateDimensions(): BoundingBox {
    final bb = this.localBounds;
    this.width = bb.width;
    this.height = bb.height;
    return bb;
  }

  public var localBounds(get, never): BoundingBox;
  function get_localBounds(): BoundingBox {
    final bb = new BoundingBox();
    for (member in this.members) {
      if (Std.isOfType(member, Graphic)) {
        member.localBounds.combine(bb, bb);
      } else {
        final graphic = member.graphic,
              pos = member.offset,
              useBounds = member.useBounds;
        final shouldUseBounds = useBounds == undefined ? true : useBounds;
        if (graphic) {
          if (shouldUseBounds) {
            graphic.localBounds.translate(pos).combine(bb, bb);
          }
        } else {
          this._logger.warnOnce('Graphics group member has an null or undefined graphic, member definition: ${JSON.stringify(member)}.');
        }
      }
    }
    return bb;
  }

  private function _isAnimationOrGroup(graphic: Graphic) {
    return Std.isOfType(graphic, Animation) || Std.isOfType(graphic, GraphicsGroup);
  }

  public function tick(elapsed: Float, ?idempotencyToken: Int) {
    for (member in this.members) {
      var graphic: Graphic;
      if (Std.isOfType(member, Graphic)) {
        graphic = member;
      } else {
        graphic = member.graphic;
      }
      if (this._isAnimationOrGroup(graphic)) {
        graphic.tick(elapsed, idempotencyToken);
      }
    }
  }

  public function reset() {
    for (member in this.members) {
      var graphic: Graphic;
      if (Std.isOfType(member, Graphic)) {
        graphic = member;
      } else {
        graphic = member.graphic;
      }
      if (this._isAnimationOrGroup(graphic)) {
        graphic.reset();
      }
    }
  }

  private function _preDraw(ex: ExcaliburGraphicsContext, x: Int, y: Int) {
    this._updateDimensions();
    super._preDraw(ex, this.useAnchor ? x : 0, this.useAnchor ? y : 0);
  }

  private function _drawImage(ex: ExcaliburGraphicsContext, x: Int, y: Int) {
    final pos = Vector.Zero;
    for (member in this.members) {
      var graphic: Graphic;
      if (Std.isOfType(member, Graphic)) {
        graphic = member;
      } else {
        graphic = member.graphic;
        member.offset.clone(pos);
      }
      if (!graphic) {
        continue;
      }
      ex.save();
      ex.translate(x, y);
      graphic.draw(ex, pos.x, pos.y);
      if (this.showDebug) {
        /* istanbul ignore next */
        ex.debug.drawRect(0, 0, this.width, this.height);
      }
      ex.restore();
    }
  }
}
