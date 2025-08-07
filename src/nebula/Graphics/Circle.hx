package nebula.graphics;

import nebula.graphics.Filtering;
import nebula.graphics.Raster;

interface CircleOptions {
  var radius: Int;
}

/**
 * A circle {@apilink Graphic} for drawing circles to the {@apilink ExcaliburGraphicsContext}
 *
 * Circles default to {@apilink ImageFiltering.Blended}
 */
class Circle extends Raster {
  private var _radius: Int = 0;
  public var radius(get, set): Int;
  function get_radius() {
    return this._radius;
  }
  function set_radius(value: Int) {
    this._radius = value;
    this.width = this._radius * 2;
    this.height = this._radius * 2;
    this.flagDirty();
  }
  public function new(options: RasterOptions & CircleOptions) {
    super(options);
    final lineWidth = options.lineWidth ?? (options.strokeColor ? 1 : 0); // default lineWidth in canvas is 1px
    this.padding = options.padding ?? 2 + lineWidth / 2; // default 2 padding for circles looks nice
    this.radius = options.radius;
    this.filtering = options.filtering ?? ImageFiltering.Blended;
    this.rasterize();
  }

  public function clone(): Circle {
    final config = Object.spreadWith(
      { radius: this.radius },
      Object.spreadWith(
        this.cloneGraphicOptions(),
        this.cloneRasterOptions()
      )
    );

    return new Circle(config);
  }

  function execute(ctx: CanvasRenderingContext2D): Void {
    if (this.radius > 0) {
      ctx.beginPath();
      ctx.arc(this.radius, this.radius, this.radius, 0, Math.PI * 2);

      if (this.color) {
        ctx.fill();
      }

      if (this.strokeColor) {
        ctx.stroke();
      }
    }
  }
}
