package nebula.debug;

import nebula.debug.DebugFlags;
import nebula.Engine;
import nebula.Color;

import nebula.collision.detection.CollisionContact;

import nebula.util.Clock;

/**
 * Debug stats containing current and previous frame statistics
 */
interface DebugStats {
  var currFrame: FrameStats;
  var prevFrame: FrameStats;
}

/**
 * Represents a frame's individual statistics
 */
interface FrameStatistics {
  /**
   * The number of the frame
   */
  var id: Int;

  /**
   * Gets the frame's delta (time since last frame scaled by {@apilink Engine.timescale}) (in ms)
   *
   * Excalibur extension depends on this
   */
  var elapsedMs: Float;

  /**
   * Gets the frame's frames-per-second (FPS)
   */
  var fps: Float;

  /**
   * Duration statistics (in ms)
   */
  var duration: FrameDurationStats;

  /**
   * Actor statistics
   */
  var actors: FrameActorStats;

  /**
   * Physics statistics
   */
  var physics: PhysicsStatistics;

  /**
   * Graphics statistics
   */
  var graphics: GraphicsStatistics;
}

/**
 * Represents actor stats for a frame
 */
interface FrameActorStats {
  /**
   * Gets the frame's number of actors (alive)
   */
  var alive: Int;

  /**
   * Gets the frame's number of actors (killed)
   */
  var killed: Int;

  /**
   * Gets the frame's number of remaining actors (alive - killed)
   */
  var remaining: Int;

  /**
   * Gets the frame's number of UI actors
   */
  var ui: Int;

  /**
   * Gets the frame's number of total actors (remaining + UI)
   */
  var total: Int;
}

/**
 * Represents duration stats for a frame
 */
interface FrameDurationStats {
  /**
   * Gets the frame's total time to run the update function (in ms)
   */
  var update: Int;

  /**
   * Gets the frame's total time to run the draw function (in ms)
   */
  var draw: Int;

  /**
   * Gets the frame's total render duration (update + draw duration) (in ms)
   */
  var total: Int;
}

/**
 * Represents physics stats for the current frame
 */
interface PhysicsStatistics {
  /**
   * Gets the number of broadphase collision pairs which
   */
  var pairs: Int;

  /**
   * Gets the number of actual collisions
   */
  var collisions: Int;

  /**
   * Copy of the current frame contacts (only updated if debug is toggled on)
   */
  var contacts: Map<String, CollisionContact>;

  /**
   * Gets the number of fast moving bodies using raycast continuous collisions in the scene
   */
  var fastBodies: Int;

  /**
   * Gets the number of bodies that had a fast body collision resolution
   */
  var fastBodyCollisions: Int;

  /**
   * Gets the time it took to calculate the broadphase pairs
   */
  var broadphase: Int;

  /**
   * Gets the time it took to calculate the narrowphase
   */
  var narrowphase: Int;
}

interface GraphicsStatistics {
  var drawCalls: Int;
  var drawnImages: Int;
}

/**
 * Debug statistics and flags for Excalibur. If polling these values, it would be
 * best to do so on the `postupdate` event for {@apilink Engine}, after all values have been
 * updated during a frame.
 */
class DebugConfig {
  private var _engine: Engine;

  public function new(engine: Engine) {
    this._engine = engine;

    this.colorBlindMode = new ColorBlindFlags(this._engine);
  }

  /**
   * Switch the current excalibur clock with the {@apilink TestClock} and return
   * it in the same running state.
   *
   * This is useful when you need to debug frame by frame.
   */
  public function useTestClock(): TestClock {
    var clock = this._engine.clock;
    var wasRunning = clock.isRunning();
    clock.stop();

    var testClock = clock.toTestClock();
    if (wasRunning) {
      testClock.start();
    }
    this._engine.clock = testClock;
    return testClock;
  }

  /**
   * Switch the current excalibur clock with the {@apilink StandardClock} and
   * return it in the same running state.
   *
   * This is useful when you need to switch back to normal mode after
   * debugging.
   */
  public function useStandardClock(): StandardClock {
    var currentClock = this._engine.clock;
    var wasRunning = currentClock.isRunning();
    currentClock.stop();

    var standardClock = currentClock.toStandardClock();
    if (wasRunning) {
      standardClock.start();
    }
    this._engine.clock = standardClock;
    return standardClock;
  }

  /**
   * Performance statistics
   */
  public var stats: DebugStats = {
    /**
     * Current frame statistics. Engine reuses this instance, use {@apilink FrameStats.clone} to copy frame stats.
     * Best accessed on {@apilink postframe} event. See {@apilink FrameStats}
     */
    currFrame: new FrameStats(),

    /**
     * Previous frame statistics. Engine reuses this instance, use {@apilink FrameStats.clone} to copy frame stats.
     * Best accessed on {@apilink preframe} event. Best inspected on engine event `preframe`. See {@apilink FrameStats}
     */
    prevFrame: new FrameStats()
  };

  /**
   * Correct or simulate color blindness using {@apilink ColorBlindnessPostProcessor}.
   * @warning Will reduce FPS.
   */
  public var colorBlindMode: ColorBlindFlags;

  /**
   * Filter debug context to named entities or entity ids
   */
  public var filter: { useFilter: Bool, nameQuery: String, ids: Array<Int> } = {
    /**
     * Toggle filter on or off (default off) must be on for DebugDraw to use filters
     */
    useFilter: false,
    /**
     * Query for entities by name, if the entity name contains `nameQuery` it will be included
     */
    nameQuery: '',
    /**
     * Query for Entity ids, if the id matches it will be included
     */
    ids: []
  };

  /**
   * Entity debug settings
   */
  public var entity = {
    showAll: false,
    showId: false,
    showName: false
  };

  /**
   * Transform component debug settings
   */
  public var transform = {
    showAll: false,

    debugZIndex: 10_000_000,
    showPosition: false,
    showPositionLabel: false,
    positionColor: Color.Yellow,

    showZIndex: false,

    showScale: false,
    scaleColor: Color.Green,

    showRotation: false,
    rotationColor: Color.Blue
  };

  /**
   * Graphics component debug settings
   */
  public var graphics = {
    showAll: false,

    showBounds: false,
    boundsColor: Color.Yellow
  };

  /**
   * Collider component debug settings
   */
  public var collider = {
    showAll: false,

    showBounds: false,
    boundsColor: Color.Blue,

    showOwner: false,

    showGeometry: true,
    geometryColor: Color.Green,
    geometryLineWidth: 1,
    geometryPointSize: 0.5
  };

  /**
   * Physics simulation debug settings
   */
  public var physics = {
    showAll: false,

    showBroadphaseSpacePartitionDebug: false,

    showCollisionNormals: false,
    collisionNormalColor: Color.Cyan,

    showCollisionContacts: true,
    contactSize: 2,
    collisionContactColor: Color.Red
  };

  /**
   * Motion component debug settings
   */
  public var motion = {
    showAll: false,

    showVelocity: false,
    velocityColor: Color.Yellow,

    showAcceleration: false,
    accelerationColor: Color.Red
  };

  /**
   * Body component debug settings
   */
  public var body = {
    showAll: false,

    showCollisionGroup: false,
    showCollisionType: false,
    showSleeping: false,
    showMotion: false,
    showMass: false
  };

  /**
   * Camera debug settings
   */
  public var camera = {
    showAll: false,

    showFocus: false,
    focusColor: Color.Red,

    showZoom: false
  };

  public var tilemap = {
    showAll: false,

    showGrid: false,
    gridColor: Color.Red,
    gridWidth: 0.5,
    showSolidBounds: false,
    solidBoundsColor: Color.fromHex('#8080807F'), // grayish
    showColliderGeometry: true
  };

  public var isometric = {
    showAll: false,
    showPosition: false,
    positionColor: Color.Yellow,
    positionSize: 1,
    showGrid: false,
    gridColor: Color.Red,
    gridWidth: 1,
    showColliderGeometry: true
  };
}

/**
 * Implementation of a frame's stats. Meant to have values copied via {@apilink FrameStats.reset}, avoid
 * creating instances of this every frame.
 */
class FrameStats implements FrameStatistics {
  private var _id: Int = 0;
  private var _elapsedMs: Int = 0;
  private var _fps: Int = 0;
  private var _actorStats: FrameActorStats = {
    alive: 0,
    killed: 0,
    ui: 0,
    getRemaining: () -> {
      return this.alive - this.killed;
    },
    getTotal: () -> {
      return this.remaining + this.ui;
    }
  };
  private var _durationStats: FrameDurationStats = {
    update: 0,
    draw: 0,
    getTotal: () -> {
      return this.update + this.draw;
    }
  };

  private var _physicsStats: PhysicsStats = new PhysicsStats();

  private var _graphicsStats: GraphicsStatistics = {
    drawCalls: 0,
    drawnImages: 0
  };

  /**
   * Zero out values or clone other IFrameStat stats. Allows instance reuse.
   * @param [otherStats] Optional stats to clone
   */
  public function reset(?otherStats: FrameStatistics) {
    if (otherStats) {
      this.id = otherStats.id;
      this.elapsedMs = otherStats.elapsedMs;
      this.fps = otherStats.fps;
      this.actors.alive = otherStats.actors.alive;
      this.actors.killed = otherStats.actors.killed;
      this.actors.ui = otherStats.actors.ui;
      this.duration.update = otherStats.duration.update;
      this.duration.draw = otherStats.duration.draw;
      this._physicsStats.reset(otherStats.physics);
      this.graphics.drawCalls = otherStats.graphics.drawCalls;
      this.graphics.drawnImages = otherStats.graphics.drawnImages;
    } else {
      this.id = this.elapsedMs = this.fps = 0;
      this.actors.alive = this.actors.killed = this.actors.ui = 0;
      this.duration.update = this.duration.draw = 0;
      this._physicsStats.reset();
      this.graphics.drawnImages = this.graphics.drawCalls = 0;
    }
  }

  /**
   * Provides a clone of this instance.
   */
  public function clone(): FrameStats {
    var fs = new FrameStats();

    fs.reset(this);

    return fs;
  }

  /**
   * Gets the frame's id
   */
  public var id(get, set): Int;
  function get_id() {
    return this._id;
  }

  /**
   * Sets the frame's id
   */
  function set_id(value: Int) {
    this._id = value;
  }

  /**
   * Gets the frame's delta (time since last frame)
   */
  public var elapsedMs(get, set): Int;
  function get_elapsedMs() {
    return this._elapsedMs;
  }

  /**
   * Sets the frame's delta (time since last frame). Internal use only.
   * @internal
   */
  function set_elapsedMs(value: Int) {
    this._elapsedMs = value;
  }

  /**
   * Gets the frame's frames-per-second (FPS)
   */
  public var fps(get, set): Int;
  function get_fps() {
    return this._fps;
  }

  /**
   * Sets the frame's frames-per-second (FPS). Internal use only.
   * @internal
   */
  function set_fps(value: Int) {
    this._fps = value;
  }

  /**
   * Gets the frame's actor statistics
   */
  public var actors(get, never): Any;
  function get_actors() {
    return this._actorStats;
  }

  /**
   * Gets the frame's duration statistics
   */
  public var duration(get, never): Any;
  function get_duration() {
    return this._durationStats;
  }

  /**
   * Gets the frame's physics statistics
   */
  public var physics(get, never): Any;
  function get_physics() {
    return this._physicsStats;
  }

  /**
   * Gets the frame's graphics statistics
   */
  public var graphics(get, never): Any;
  function get_graphics() {
    return this._graphicsStats;
  }
}

class PhysicsStats implements PhysicsStatistics {
  private var _pairs: Int = 0;
  private var _collisions: Int = 0;
  private var _contacts: Map<String, CollisionContact> = new Map();
  private var _fastBodies: Int = 0;
  private var _fastBodyCollisions: Int = 0;
  private var _broadphase: Int = 0;
  private var _narrowphase: Int = 0;

  /**
   * Zero out values or clone other IPhysicsStats stats. Allows instance reuse.
   * @param [otherStats] Optional stats to clone
   */
  public function reset(?otherStats: PhysicsStatistics) {
    if (otherStats) {
      this.pairs = otherStats.pairs;
      this.collisions = otherStats.collisions;
      this.contacts = otherStats.contacts;
      this.fastBodies = otherStats.fastBodies;
      this.fastBodyCollisions = otherStats.fastBodyCollisions;
      this.broadphase = otherStats.broadphase;
      this.narrowphase = otherStats.narrowphase;
    } else {
      this.pairs = this.collisions = this.fastBodies = 0;
      this.fastBodyCollisions = this.broadphase = this.narrowphase = 0;
      this.contacts.clear();
    }
  }

  /**
   * Provides a clone of this instance.
   */
  public function clone(): PhysicsStatistics {
    var ps = new PhysicsStats();

    ps.reset(this);

    return ps;
  }

  public var pairs(get, set): Int;
  function get_pairs(): Int {
    return this._pairs;
  }
  function set_pairs(value: Int) {
    this._pairs = value;
  }

  public var collisions(get, set): Int;
  function get_collisions(): Int {
    return this._collisions;
  }
  function set_collisions(value: Int) {
    this._collisions = value;
  }

  public var contacts(get, set): Map<String, CollisionContact>;
  function get_contacts(): Map<String, CollisionContact> {
    return this._contacts;
  }
  function set_contacts(contacts: Map<String, CollisionContact>) {
    this._contacts = contacts;
  }

  public var fastBodies(get, set): Int;
  function get_fastBodies(): Int {
    return this._fastBodies;
  }
  function set_fastBodies(value: Int) {
    this._fastBodies = value;
  }

  public var fastBodyCollisions(get, set): Int;
  function get_fastBodyCollisions(): Int {
    return this._fastBodyCollisions;
  }
  function set_fastBodyCollisions(value: Int) {
    this._fastBodyCollisions = value;
  }

  public var broadphase(get, set): Int;
  function get_broadphase(): Int {
    return this._broadphase;
  }
  function set_broadphase(value: Int) {
    this._broadphase = value;
  }

  public var narrowphase(get, set): Int;
  function get_narrowphase(): Int {
    return this._narrowphase;
  }
  function set_narrowphase(value: Int) {
    this._narrowphase = value;
  }
}
