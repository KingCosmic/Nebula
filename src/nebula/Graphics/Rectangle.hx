package nebula.graphics;

import nebula.graphics.Raster;

interface RectangleOptions {
  var width: Int;
  var height: Int;
}

/**
 * A Rectangle {@apilink Graphic} for drawing rectangles to the {@apilink ExcaliburGraphicsContext}
 */
class Rectangle extends Raster {
  public function new(options: RasterOptions & RectangleOptions) {
    super(options);
    this.width = options.width;
    this.height = options.height;
    this.rasterize();
  }

  public function clone(): Rectangle {
    final config = Object.spreadWith(
      { width: this.width, height: this.height },
      Object.spreadWith(
        this.cloneGraphicOptions(),
        this.cloneRasterOptions()
      )
    );

    return new Rectangle(config);
  }

  public function execute(ctx: CanvasRenderingContext2D): Void {
    if (this.color) {
      ctx.fillRect(0, 0, this.width, this.height);
    }
    if (this.strokeColor) {
      ctx.strokeRect(0, 0, this.width, this.height);
    }
  }
}
