package nebula.Graphics;

import nebula.Graphics.Raster;

interface RectangleOptions {
  width: Int;
  height: Int;
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
    return new Rectangle({
      width: this.width,
      height: this.height,
      ...this.cloneGraphicOptions(),
      ...this.cloneRasterOptions()
    });
  }

  public function execute(ctx: CanvasRenderingContext2D): void {
    if (this.color) {
      ctx.fillRect(0, 0, this.width, this.height);
    }
    if (this.strokeColor) {
      ctx.strokeRect(0, 0, this.width, this.height);
    }
  }
}
