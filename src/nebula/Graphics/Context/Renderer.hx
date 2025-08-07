package nebula.graphics.context;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

/**
 * Interface that defines an Excalibur Renderer that can be called with .draw() in the {@apilink ExcaliburGraphicsContext}
 */
interface RendererPlugin {
  /**
   * Unique type name for this renderer plugin
   */
  var type: String;

  /**
   * Render priority tie breaker when drawings are at the same z index
   *
   * Lower number means higher priority and is drawn first. Higher number means lower priority and is drawn last.
   */
  var priority: Int;

  /**
   * Initialize your renderer
   * @param gl
   * @param context
   */
  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL): Void;

  /**
   * Issue a draw command to draw something to the screen
   * @param args
   */
  function draw(...args: Array<Any>): Void;

  /**
   * @returns if there are any pending draws in the renderer
   */
  function hasPendingDraws(): Bool;

  /**
   * Flush any pending graphics draws to the screen
   */
  function flush(): Void;

  /**
   * Clear out any allocated memory
   */
  function dispose(): Void;
}
