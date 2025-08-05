package nebula.Debug;

import nebula.Graphics.PostProcessor.ColorBlindnessMode;
import nebula.Graphics.PostProcessor.ColorBlindnessPostProcessor;

import nebula.Engine;

import nebula.Graphics.Context.ExcaliburGraphicsContextWebGL;

class ColorBlindFlags {
  private _engine: Engine;
  private _colorBlindPostProcessor: ColorBlindnessPostProcessor;

  public function new(engine: Engine) {
    this._engine = engine;
    this._colorBlindPostProcessor = new ColorBlindnessPostProcessor(ColorBlindnessMode.Protanope);
  }

  /**
   * Correct colors for a specified color blindness
   * @param colorBlindness
   */
  public correct(colorBlindness: ColorBlindnessMode) {
    if (this._engine.graphicsContext instanceof ExcaliburGraphicsContextWebGL) {
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
  public simulate(colorBlindness: ColorBlindnessMode) {
    if (this._engine.graphicsContext instanceof ExcaliburGraphicsContextWebGL) {
      this.clear();
      this._colorBlindPostProcessor.colorBlindnessMode = colorBlindness;
      this._colorBlindPostProcessor.simulate = true;
      this._engine.graphicsContext.addPostProcessor(this._colorBlindPostProcessor);
    }
  }

  /**
   * Remove color blindness post processor
   */
  public clear() {
    this._engine.graphicsContext.removePostProcessor(this._colorBlindPostProcessor);
  }
}
