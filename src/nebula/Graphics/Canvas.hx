package nebula.graphics;

import nebula.graphics.Graphic;
import nebula.graphics.Raster;

interface CanvasOptions {
  var draw: Null<(ctx: CanvasRenderingContext2D) -> Void>;
  var cache: Null<Bool>;
}

/**
 * A canvas {@apilink Graphic} to provide an adapter between the 2D Canvas API and the {@apilink ExcaliburGraphicsContext}.
 *
 * The {@apilink Canvas} works by re-rastering a draw handler to a HTMLCanvasElement for every draw which is then passed
 * to the {@apilink ExcaliburGraphicsContext} implementation as a rendered image.
 *
 * **Low performance API**
 */
class Canvas extends Raster {
  /**
   * Return the 2D graphics context of this canvas
   */
  public var ctx(get, never): CanvasRenderingContext2D;
  function get_ctx() {
    return this._ctx;
  }

  public function new(_options: GraphicOptions & RasterOptions & CanvasOptions = {}) {
    super(_options);
  }

  public function clone(): Canvas {
    final options = Object.spreadWith(
      this._options,
      Object.spreadWith(
        this.cloneGraphicOptions(),
        this.cloneRasterOptions()
      )
    );
    return new Canvas(options);
  }

  function execute(ctx: CanvasRenderingContext2D): Void {
    if (this._options.draw) {
      this._options.draw(ctx);
    }
    if (!this._options.cache) {
      this.flagDirty();
    }
  }
}
