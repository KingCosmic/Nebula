package nebula.math;

/**
 * Enum representing the coordinate plane for the position 2D vector in the {@apilink TransformComponent}
 */
enum CoordPlane {
  /**
   * The world coordinate plane (default) represents world space, any entities drawn with world
   * space move when the camera moves.
   */
  World;
  /**
   * The screen coordinate plane represents screen space, entities drawn in screen space are pinned
   * to screen coordinates ignoring the camera.
   */
  Screen;
}
