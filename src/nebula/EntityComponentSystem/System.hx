package nebula.entitycomponentsystem;

import nebula.Scene;

import nebula.entitycomponentsystem.Priority;
import nebula.entitycomponentsystem.World;

/**
 * Enum that determines whether to run the system in the update or draw phase
 */
enum SystemType {
  Update;
  Draw;
}

/**
 * An Excalibur {@apilink System} that updates entities of certain types.
 * Systems are scene specific
 *
 *
 *
 * Excalibur Systems currently require at least 1 Component type to operated
 *
 * Multiple types are declared as a type union
 * For example:
 *
 * ```typescript
 * class MySystem extends System {
 *   static priority = SystemPriority.Lowest;
 *   public readonly systemType = SystemType.Update;
 *   public query: Query<typeof TransformComponent>;
 *   constructor(public world: World) {
 *   super();
 *      this.query = this.world.query([TransformComponent]);
 *   }
 *   public update(elapsed: number) {
 *      ...
 *   }
 * }
 * ```
 */
abstract class System {
  /**
   * Determine whether the system is called in the {@apilink SystemType.Update} or the {@apilink SystemType.Draw} phase. Update is first, then Draw.
   */
  abstract var systemType: SystemType;

  /**
   * System can execute in priority order, by default all systems are priority 0. Lower values indicated higher priority.
   * For a system to execute before all other a lower priority value (-1 for example) must be set.
   * For a system to execute after all other a higher priority value (10 for example) must be set.
   */
  public static var priority: Int = SystemPriority.Average;

  /**
   * Optionally specify an initialize handler
   * @param scene
   */
  function initialize(world: World, scene: Scene);

  /**
   * Update all entities that match this system's types
   * @param elapsed Time in milliseconds
   */
  abstract function update(elapsed: Int);

  /**
   * Optionally run a preupdate before the system processes matching entities
   * @param scene
   * @param elapsed Time in milliseconds since the last frame
   */
  function preupdate(scene: Scene, elapsed: Int);

  /**
   * Optionally run a postupdate after the system processes matching entities
   * @param scene
   * @param elapsed Time in milliseconds since the last frame
   */
  function postupdate(scene: Scene, elapsed: Int): Void;
}
