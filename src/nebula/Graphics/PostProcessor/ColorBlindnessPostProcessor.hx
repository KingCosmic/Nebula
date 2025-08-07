package nebula.graphics.postprocessor;

import nebula.graphics.postprocessor.ColorBlindnessMode;
import nebula.graphics.postprocessor.PostProcessor;

import nebula.graphics.context.Shader;
import nebula.graphics.context.VertexLayout;

import nebula.graphics.postprocessor.ScreenShader;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

class ColorBlindnessPostProcessor implements PostProcessor {
  private var _shader: ScreenShader;
  private var _simulate = false;
  public function new(
    _colorBlindnessMode: ColorBlindnessMode,
    simulate = false
  ) {
    this._simulate = simulate;
  }

  function initialize(graphicsContext: ExcaliburGraphicsContextWebGL): Void {
    this._shader = new ScreenShader(graphicsContext, colorBlindCorrectSource);
    this.simulate = this._simulate;
    this.colorBlindnessMode = this._colorBlindnessMode;
  }

  function getShader(): Shader {
    return this._shader.getShader();
  }

  function getLayout(): VertexLayout {
    return this._shader.getLayout();
  }

  public var colorBlindnessMode(get, set): ColorBlindnessMode;
  function get_colorBlindnessMode(): ColorBlindnessMode {
    return this._colorBlindnessMode;
  }
  function set_colorBlindnessMode(colorBlindMode: ColorBlindnessMode) {
    this._colorBlindnessMode = colorBlindMode;
    if (this._shader) {
      final shader = this._shader.getShader();
      shader.use();
      if (this._colorBlindnessMode == ColorBlindnessMode.Protanope) {
        shader.setUniformInt('u_type', 0);
      } else if (this._colorBlindnessMode == ColorBlindnessMode.Deuteranope) {
        shader.setUniformInt('u_type', 1);
      } else if (this._colorBlindnessMode == ColorBlindnessMode.Tritanope) {
        shader.setUniformInt('u_type', 2);
      }
    }
  }

  public var simulate(get, set): Bool;
  function get_simulate(): Bool {
    return this._simulate;
  }
  function set_simulate(value: Bool) {
    this._simulate = value;
    if (this._shader) {
      final shader = this._shader.getShader();
      shader.use();
      shader.setUniformBoolean('u_simulate', value);
    }
  }
}
