package nebula.actions.action;

import nebula.graphics.GraphicsComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.graphics.context.Material;
import nebula.graphics.context.Shader;

import nebula.actions.Action;
import nebula.Color;
import nebula.Actor;

class Flash implements Action {
  var id = nextActionId();
  private var _graphics: GraphicsComponent;
  private var _duration: Int;
  private var _stopped: Bool = false;
  private var _started: Bool = false;
  private var _entity: Entity;
  private var _material: Null<Material>;
  private var _total: Int = 0;
  private var _currentDuration: Int = 0;

  public function new(entity: Entity, color: Color, duration: Int = 1000) {
    this._graphics = entity.get(GraphicsComponent);
    this._duration = duration;
    this._entity = entity;
    this._material = entity.scene?.engine.graphicsContext.createMaterial({
      name: 'flash-material',
      color: color,
      fragmentSource: '#version 300 es
    
        precision mediump float;
        uniform float u_blend;
        uniform sampler2D u_graphic;
        uniform vec4 u_color;
    
        in vec2 v_uv; 
        out vec4 color;
    
        void main() { 
            vec4 textureColor = texture(u_graphic, v_uv); 
            color = mix(textureColor, u_color, u_blend * textureColor.a);
            color.rgb = color.rgb * color.a;
        }'
    });
    this._total = duration;
  }

  public function update(elapsed: Int) {
    if (!this._started) {
      this._started = true;
      this._total = this._duration;
      this._currentDuration = this._duration;
      this._entity.graphics.material = this._material;
    }
    if (!this._graphics) {
      return;
    }

    this._currentDuration -= elapsed;

    if (this._graphics) {
      this._material?.update((shader: Shader) -> {
        shader.trySetUniformFloat('u_blend', this._currentDuration / this._total);
      });
    }

    if (this.isComplete()) {
      this._entity.graphics.material = null;
    }
  }

  public function isComplete(): Bool {
    return this._stopped || this._currentDuration <= 0;
  }

  public function stop() {
    if (this._graphics) {
      this._graphics.isVisible = true;
    }
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
  }
}
