package nebula.collision;

import nebula.math.Ray;
import nebula.util.Observable;

import nebula.collision.BodyComponent;
import nebula.collision.PhysicsConfig;

import nebula.util.Watch;
import nebula.math.Vector;

import nebula.collision.detection.SpatialPartitionStrategy;

class PhysicsWorld {
  var configUpdate = new Observable<DeepRequired<PhysicsConfig>>();

  private var _configDirty = false;
  private var _config: DeepRequired<PhysicsConfig>;

  public var config(get, set): Any;
  function get_config(): DeepRequired<PhysicsConfig> {
    return watchDeep(this._config, (change) -> {
      this.$configUpdate.notifyAll(change);
    });
  }
  function set_config(newConfig: DeepRequired<PhysicsConfig>) {
    this._config = newConfig;
    this.$configUpdate.notifyAll(newConfig);
  }

  private var _collisionProcessor: CollisionProcessor;
  /**
   * Spatial data structure for locating potential collision pairs and ray casts
   */
  public var collisionProcessor(get, never): CollisionProcessor;
  function get_collisionProcessor(): CollisionProcessor {
    if (this._configDirty) {
      this._configDirty = false;
      // preserve tracked colliders if config updates
      final colliders = this._collisionProcessor.getColliders();
      if (this._config.spatialPartition == SpatialPartitionStrategy.SparseHashGrid) {
        this._collisionProcessor = new SparseHashGridCollisionProcessor(this._config.sparseHashGrid);
      } else {
        this._collisionProcessor = new DynamicTreeCollisionProcessor(this._config);
      }
      for (collider in colliders) {
        this._collisionProcessor.track(collider);
      }
    }
    return this._collisionProcessor;
  }

  public function new(config: PhysicsConfig) {
    this.config = config;
    this.configUpdate.subscribe((config) -> {
      this._configDirty = true;
      BodyComponent.updateDefaultPhysicsConfig(config.bodies);
    });
    if (this._config.spatialPartition == SpatialPartitionStrategy.SparseHashGrid) {
      this._collisionProcessor = new SparseHashGridCollisionProcessor(this._config.sparseHashGrid);
    } else {
      this._collisionProcessor = new DynamicTreeCollisionProcessor(this._config);
    }
  }

  /**
   * Raycast into the scene's physics world
   * @param ray
   * @param options
   */
  public function rayCast(ray: Ray, ?options: RayCastOptions): Array<RayCastHit> {
    return this.collisionProcessor.rayCast(ray, options);
  }

  /**
   * Query for colliders in the scene's physics world
   * @param point
   */
  public function query(pointOrBounds: Any): Array<Collider> {
    return this._collisionProcessor.query(pointOrBounds);
  }
}
