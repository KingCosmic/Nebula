package nebula.Collision;

import nebula.Math.Vector;
import nebula.Util.Required;
import nebula.Collision.SolverStrategy;
import nebula.Collision.Solver.ContactBias;
import nebula.Collision.Detection.SpatialPartitionStrategy;

interface DynamicTreeConfig {
  /**
   * Pad collider BoundingBox by a constant amount for purposes of potential pairs
   *
   * Default 5 pixels
   */
  boundsPadding?: Int;

  /**
   * Factor to add to the collider BoundingBox, bounding box (dimensions += vel * dynamicTreeVelocityMultiplier);
   *
   * Default 2
   */
  velocityMultiplier?: Int;
}

interface SparseHashGridConfig {
  /**
   * Size of the grid cells, default is 100x100 pixels.
   *
   * A good size means that your average collider in your game would fit inside the cell size by size dimension.
   */
  size: Float;
}

interface PhysicsConfig {
  /**
   * Excalibur physics simulation is enabled
   */
  enabled?: Bool;
  /**
   * Configure gravity that applies to all {@apilink CollisionType.Active} bodies.
   *
   * This is acceleration in pixels/sec^2
   *
   * Default vec(0, 0)
   *
   * {@apilink BodyComponent.useGravity} to opt out
   */
  gravity?: Vector;
  /**
   * Configure the type of physics simulation you would like
   *
   * * {@apilink SolverStrategy.Arcade} is suitable for games where you might be doing platforming or top down movement.
   * * {@apilink SolverStrategy.Realistic} is where you need objects to bounce off each other and respond like real world objects.
   *
   * Default is Arcade
   */
  solver?: SolverStrategy;

  /**
   * Configure physics sub-stepping, this can increase simulation fidelity by doing smaller physics steps
   *
   * Default is 1 step
   */
  substep?: Int;

  /**
   * Configure colliders
   */
  colliders?: {
    /**
     * Treat composite collider's member colliders as either separate colliders for the purposes of onCollisionStart/onCollision
     * or as a single collider together.
     *
     * This property can be overridden on individual {@apilink CompositeColliders}.
     *
     * For composites without gaps or small groups of colliders, you probably want 'together'
     *
     * For composites with deliberate gaps, like a platforming level layout, you probably want 'separate'
     *
     * Default is 'together' if unset
     */
    compositeStrategy?: 'separate' | 'together';
  };

  /**
   * Configure excalibur continuous collision (WIP)
   */
  continuous?: {
    /**
     * Enable fast moving body checking, this enables checking for collision pairs via raycast for fast moving objects to prevent
     * bodies from tunneling through one another.
     *
     * Default true
     */
    checkForFastBodies?: Bool;

    /**
     * Disable minimum fast moving body raycast, by default if checkForFastBodies = true Excalibur will only check if the
     * body is moving at least half of its minimum dimension in an update. If disableMinimumSpeedForFastBody is set to true,
     * Excalibur will always perform the fast body raycast regardless of speed.
     *
     * Default false
     */
    disableMinimumSpeedForFastBody?: Bool;

    /**
     * Surface epsilon is used to help deal with predicting collisions by applying a slop
     *
     * Default 0.1
     */
    surfaceEpsilon?: Float;
  };

  /**
   * Configure body defaults
   */
  bodies?: {
    /**
     * Configure default mass that bodies have
     *
     * Default 10 mass units
     */
    defaultMass?: Int;

    /**
     * Sleep epsilon
     *
     * Default 0.07
     */
    sleepEpsilon?: Float;

    /**
     * Wake Threshold, the amount of "motion" need to wake a body from sleep
     *
     * Default 0.07 * 3;
     */
    wakeThreshold?: Float;

    /**
     * Sleep bias
     *
     * Default 0.9
     */
    sleepBias?: Float;

    /**
     * By default bodies do not sleep, this can be turned on to improve perf if you have a lot of bodies.
     *
     * Default false
     */
    canSleepByDefault?: Bool;
  };

  /**
   * Configure the spatial data structure for locating pairs and raycasts
   */
  spatialPartition?: SpatialPartitionStrategy;
  sparseHashGrid?: SparseHashGridConfig;
  dynamicTree?: DynamicTreeConfig;

  /**
   * Configure the {@apilink ArcadeSolver}
   */
  arcade?: {
    /**
     * Hints the {@apilink ArcadeSolver} to preferentially solve certain contact directions first.
     *
     * Options:
     * * Solve {@apilink ContactSolveBias.VerticalFirst} which will do vertical contact resolution first (useful for platformers
     * with up/down gravity)
     * * Solve {@apilink ContactSolveBias.HorizontalFirst} which will do horizontal contact resolution first (useful for games with
     * left/right forces)
     * * By default {@apilink ContactSolveBias.None} which sorts by distance
     */
    contactSolveBias?: ContactSolveBias;
  };

  /**
   * Configure the {@apilink RealisticSolver}
   */
  realistic?: {
    contactSolveBias?: ContactSolveBias;
    /**
     * Number of position iterations (overlap) to run in the solver
     *
     * Default 3 iterations
     */
    positionIterations?: Int;

    /**
     * Number of velocity iteration (response) to run in the solver
     *
     * Default 8 iterations
     */
    velocityIterations?: Int;

    /**
     * Amount of overlap to tolerate in pixels
     *
     * Default 1 pixel
     */
    slop?: Int;

    /**
     * Amount of positional overlap correction to apply each position iteration of the solver
     * 0 - meaning no correction, 1 - meaning correct all overlap. Generally values 0 < .5 look nice.
     *
     * Default 0.2
     */
    steeringFactor?: Float;

    /**
     * Warm start set to true re-uses impulses from previous frames back in the solver. Re-using impulses helps
     * the solver converge quicker
     *
     * Default true
     */
    warmStart?: Bool;
  };
}

final getDefaultPhysicsConfig: () => DeepRequired<PhysicsConfig> = () => ({
  enabled: true,
  gravity: vec(0, 0).clone(),
  solver: SolverStrategy.Arcade,
  substep: 1,
  colliders: {
    compositeStrategy: 'together'
  },
  continuous: {
    checkForFastBodies: true,
    disableMinimumSpeedForFastBody: false,
    surfaceEpsilon: 0.1
  },
  bodies: {
    canSleepByDefault: false,
    sleepEpsilon: 0.07,
    wakeThreshold: 0.07 * 3,
    sleepBias: 0.9,
    defaultMass: 10
  },
  spatialPartition: SpatialPartitionStrategy.SparseHashGrid,
  sparseHashGrid: {
    size: 100
  },
  dynamicTree: {
    boundsPadding: 5,
    velocityMultiplier: 2
  },
  arcade: {
    contactSolveBias: ContactSolveBias.None
  },
  realistic: {
    contactSolveBias: ContactSolveBias.None,
    positionIterations: 3,
    velocityIterations: 8,
    slop: 1,
    steeringFactor: 0.2,
    warmStart: true
  }
});