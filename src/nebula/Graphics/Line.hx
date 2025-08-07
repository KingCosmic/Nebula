package nebula.graphics;

import nebula.collision.BoundingBox;

import nebula.Color;

import nebula.math.Vector;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.graphics.Graphic;

interface LineOptions {
  var start: Vector;
  var end: Vector;
  var color: Null<Color>;
  var thickness: Null<Int>;
}

class Line extends Graphic {
  var start: Vector;
  var end: Vector;
  var color: Color = Color.Black;
  var thickness: Int = 1;
  private var _localBounds: BoundingBox;
  public function new(options: LineOptions) {
    super();
    final start = options.start,
          end = options.end,
          color = options.color,
          thickness = options.thickness;

    this.start = start;
    this.end = end;
    this.color = color ?? this.color;
    this.thickness = thickness ?? this.thickness;
    this._localBounds = this._calculateBounds();
    final width = this._localBounds.width,
          height = this._localBounds.height;

    this.width = width;
    this.height = height;
  }

  public var localBounds(get, never): BoundingBox;
  function get_localBounds() {
    return this._localBounds;
  }

  private function _calculateBounds(): BoundingBox {
    final lineNormal = this.end.sub(this.start).normal();

    final halfThickness = this.thickness / 2;

    final points = [
      this.start.add(lineNormal.scale(halfThickness)),
      this.end.add(lineNormal.scale(halfThickness)),
      this.end.add(lineNormal.scale(-halfThickness)),
      this.start.add(lineNormal.scale(-halfThickness))
    ];

    return BoundingBox.fromPoints(points);
  }

  private function _drawImage(ctx: ExcaliburGraphicsContext, _x: Int, _y: Int): Void {
    ctx.drawLine(this.start, this.end, this.color, this.thickness);
  }

  function clone(): Line {
    return new Line({
      start: this.start,
      end: this.end,
      color: this.color,
      thickness: this.thickness
    });
  }
}
