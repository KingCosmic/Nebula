package nebula.Graphics;

import nebula.Graphics.Context.ExcaliburGraphicsContext;

import nebula.Debug.DebugConfig;

import nebula.EntityComponentSystem.Component;

/**
 * Provide arbitrary drawing for the purposes of debugging your game
 *
 * Will only show when the Engine is set to debug mode {@apilink Engine.showDebug} or {@apilink Engine.toggleDebug}
 *
 */
class DebugGraphicsComponent extends Component {
  public function new(
    public draw: (ctx: ExcaliburGraphicsContext, debugFlags: DebugConfig) => void,
    public useTransform = true
  ) {
    super();
  }
}
