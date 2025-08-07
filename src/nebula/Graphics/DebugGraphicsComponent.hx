package nebula.graphics;

import nebula.graphics.context.ExcaliburGraphicsContext;

import nebula.debug.DebugConfig;

import nebula.entitycomponentsystem.Component;

/**
 * Provide arbitrary drawing for the purposes of debugging your game
 *
 * Will only show when the Engine is set to debug mode {@apilink Engine.showDebug} or {@apilink Engine.toggleDebug}
 *
 */
class DebugGraphicsComponent extends Component {
  public function new(
    draw: (ctx: ExcaliburGraphicsContext, debugFlags: DebugConfig) -> Void,
    useTransform = true
  ) {
    super();
  }
}
