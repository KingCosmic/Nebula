package nebula.debug;

import nebula.graphics.postprocessor.ColorBlindnessMode;
import nebula.graphics.postprocessor.ColorBlindnessPostProcessor;

import nebula.Engine;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

class ColorBlindFlags {
  private var _engine: Engine;
  private var _colorBlindPostProcessor: ColorBlindnessPostProcessor;

  public function new(engine: Engine) {
    this._engine = engine;
    this._colorBlindPostProcessor = new ColorBlindnessPostProcessor(ColorBlindnessMode.Protanope);
  }

  /**
   * Correct colors for a specified color blindness
   * @param colorBlindness
   */
  public function correct(colorBlindness: ColorBlindnessMode) {
    if (Std.isOfType(this._engine.graphicsContext, ExcaliburGraphicsContextWebGL)) {
      this.clear();
      this._colorBlindPostProcessor.colorBlindnessMode = colorBlindness;
      this._colorBlindPostProcessor.simulate = false;
      this._engine.graphicsContext.addPostProcessor(this._colorBlindPostProcessor);
    }
  }

  /**
   * Simulate colors for a specified color blindness
   * @param colorBlindness
   */
  public function simulate(colorBlindness: ColorBlindnessMode) {
    if (Std.isOfType(this._engine.graphicsContext, ExcaliburGraphicsContextWebGL)) {
      this.clear();
      this._colorBlindPostProcessor.colorBlindnessMode = colorBlindness;
      this._colorBlindPostProcessor.simulate = true;
      this._engine.graphicsContext.addPostProcessor(this._colorBlindPostProcessor);
    }
  }

  /**
   * Remove color blindness post processor
   */
  public function clear() {
    this._engine.graphicsContext.removePostProcessor(this._colorBlindPostProcessor);
  }
}
