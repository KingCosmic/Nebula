package nebula.Graphics;

import nebula.Collision.BoundingBox;

import nebula.Color;

import nebula.Math.Vector;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

import nebula.Graphics.Graphic;

interface LineOptions {
  start: Vector;
  end: Vector;
  color?: Color;
  thickness?: Int;
}

class Line extends Graphic {
  readonly start: Vector;
  readonly end: Vector;
  color: Color = Color.Black;
  thickness: Int = 1;
  private _localBounds: BoundingBox;
  public function new(options: LineOptions) {
    super();
    final { start, end, color, thickness } = options;
    this.start = start;
    this.end = end;
    this.color = color ?? this.color;
    this.thickness = thickness ?? this.thickness;
    this._localBounds = this._calculateBounds();
    final { width, height } = this._localBounds;

    this.width = width;
    this.height = height;
  }

  public get localBounds() {
    return this._localBounds;
  }

  private _calculateBounds(): BoundingBox {
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

  private _drawImage(ctx: ExcaliburGraphicsContext, _x: Int, _y: Int): Void {
    ctx.drawLine(this.start, this.end, this.color, this.thickness);
  }

  clone(): Line {
    return new Line({
      start: this.start,
      end: this.end,
      color: this.color,
      thickness: this.thickness
    });
  }
}
