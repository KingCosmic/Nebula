package nebula.Graphics.PostProcessor;

import nebula.Graphics.PostProcessor.ColorBlindnessMode;
import nebula.Graphics.PostProcessor.PostProcessor;

import nebula.Graphics.Context.Shader;
import nebula.Graphics.Context.VertexLayout;

import nebula.Graphics.PostProcessor.ScreenShader;

import nebula.Graphics.Context.ExcaliburGraphicsContextWebGL;

class ColorBlindnessPostProcessor implements PostProcessor {
  private _shader!: ScreenShader;
  private _simulate = false;
  public function new(
    private _colorBlindnessMode: ColorBlindnessMode,
    simulate = false
  ) {
    this._simulate = simulate;
  }

  initialize(graphicsContext: ExcaliburGraphicsContextWebGL): Void {
    this._shader = new ScreenShader(graphicsContext, colorBlindCorrectSource);
    this.simulate = this._simulate;
    this.colorBlindnessMode = this._colorBlindnessMode;
  }

  getShader(): Shader {
    return this._shader.getShader();
  }

  getLayout(): VertexLayout {
    return this._shader.getLayout();
  }

  set colorBlindnessMode(colorBlindMode: ColorBlindnessMode) {
    this._colorBlindnessMode = colorBlindMode;
    if (this._shader) {
      final shader = this._shader.getShader();
      shader.use();
      if (this._colorBlindnessMode === ColorBlindnessMode.Protanope) {
        shader.setUniformInt('u_type', 0);
      } else if (this._colorBlindnessMode === ColorBlindnessMode.Deuteranope) {
        shader.setUniformInt('u_type', 1);
      } else if (this._colorBlindnessMode === ColorBlindnessMode.Tritanope) {
        shader.setUniformInt('u_type', 2);
      }
    }
  }

  get colorBlindnessMode(): ColorBlindnessMode {
    return this._colorBlindnessMode;
  }

  set simulate(value: Bool) {
    this._simulate = value;
    if (this._shader) {
      final shader = this._shader.getShader();
      shader.use();
      shader.setUniformBoolean('u_simulate', value);
    }
  }

  get simulate(): Bool {
    return this._simulate;
  }
}
