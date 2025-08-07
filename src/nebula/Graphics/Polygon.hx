package nebula.graphics;

import nebula.graphics.Filtering;
import nebula.graphics.Raster;

import nebula.math.Vector;

interface PolygonOptions {
  var points: Array<Vector>;
}

/**
 * A polygon {@apilink Graphic} for drawing arbitrary polygons to the {@apilink ExcaliburGraphicsContext}
 *
 * Polygons default to {@apilink ImageFiltering.Blended}
 */
class Polygon extends Raster {
  private var _points: Array<Vector> = [];

  public var points(get, set): Array<Vector>;
  function get_points(): Array<Vector> {
    return this._points;
  }
  function set_points(points: Array<Vector>) {
    this._points = points;
    final min = this.minPoint;
    this.width = this._points.reduce((max, p) => Math.max(p.x, max), 0) - min.x;
    this.height = this._points.reduce((max, p) => Math.max(p.y, max), 0) - min.y;
    this.flagDirty();
  }

  public var minPoint(get, never): Vector;
  function get_minPoint() {
    final minX = this._points.reduce((min, p) -> Math.min(p.x, min), Infinity);
    final minY = this._points.reduce((min, p) -> Math.min(p.y, min), Infinity);
    return vec(minX, minY);
  }

  public function new(options: RasterOptions & PolygonOptions) {
    super(options);
    this.points = options.points;
    this.filtering = ImageFiltering.Blended;
    this.rasterize();
  }

  public function clone(): Polygon {
    var config = Object.spreadWith(
      { points: this.points.map((p) -> p.clone()) },
      Object.spreadWith(
        this.cloneGraphicOptions(),
        this.cloneRasterOptions()
      )
    );
    return new Polygon(config);
  }

  function execute(ctx: CanvasRenderingContext2D): Void {
    if (this.points && this.points.length) {
      ctx.beginPath();
      // Iterate through the supplied points and construct a 'polygon'
      final min = this.minPoint.negate();
      final firstPoint = this.points[0].add(min);
      ctx.moveTo(firstPoint.x, firstPoint.y);
      this.points.forEach((point) -> {
        ctx.lineTo(point.x + min.x, point.y + min.y);
      });
      ctx.lineTo(firstPoint.x, firstPoint.y);
      ctx.closePath();
      if (this.color) {
        ctx.fill();
      }
      if (this.strokeColor) {
        ctx.stroke();
      }
    }
  }
}
