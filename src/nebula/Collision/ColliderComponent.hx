package nebula.collision;

import nebula.math.Vector;
import nebula.entitycomponentsystem.Component;
import nebula.entitycomponentsystem.Entity;

import nebula.Events;

import nebula.util.Observable;
import nebula.collision.BoundingBox;

import nebula.collision.detection.CollisionContact;
import nebula.collision.colliders.CircleCollider;
import nebula.collision.colliders.Collider;
import nebula.collision.colliders.CompositeCollider;
import nebula.collision.colliders.PolygonCollider;
import nebula.collision.colliders.EdgeCollider;
import nebula.collision.colliders.Shape;

import nebula.EventEmitter;
import nebula.Actor;

class ColliderComponent extends Component {
  public var events = new EventEmitter();
  /**
   * Observable that notifies when a collider is added to the body
   */
  public var colliderAdded = new Observable<Collider>();

  /**
   * Observable that notifies when a collider is removed from the body
   */
  public var colliderRemoved = new Observable<Collider>();

  public function new(?collider: Collider) {
    super();
    this.set(collider);
  }

  private var _collider: Null<Collider>;
  /**
   * Get the current collider geometry
   */
  public function get(): Null<Collider> {
    return this._collider;
  }

  /**
   * Set the collider geometry
   * @param collider
   * @returns the collider you set
   */
  public function set<T:Collider>(collider: T): T {
    this.clear();
    if (collider) {
      this._collider = collider;
      this._collider.owner = this.owner;
      collider.events.pipe(this.events);
      this.colliderAdded.notifyAll(collider);
      this.update();
    }
    return collider;
  }

  private var _collidersToRemove: Array<Collider> = [];
  /**
   * Remove collider geometry from collider component
   */
  public function clear() {
    if (this._collider) {
      this._collidersToRemove.push(this._collider);
      this._collider = null;
    }
  }

  public function processColliderRemoval() {
    for (collider in this._collidersToRemove) {
      collider.events.unpipe(this.events);
      this.$colliderRemoved.notifyAll(collider);
      collider.owner = null;
    }
  }

  public function clone(): ColliderComponent {
    final clone = new ColliderComponent(this._collider.clone());

    return clone;
  }

  /**
   * Return world space bounds
   */
  public var bounds(get, never): BoundingBox;
  function get_bounds() {
    return this._collider?.bounds ?? new BoundingBox();
  }

  /**
   * Return local space bounds
   */
  public var localBounds(get, never): BoundingBox;
  function get_localBounds() {
    return this._collider.localBounds ?? new BoundingBox();
  }

  /**
   * Update the collider's transformed geometry
   */
  public function update() {
    final tx = this.owner.get(TransformComponent);
    if (this._collider) {
      this._collider.owner = this.owner;
      if (tx) {
        this._collider.update(tx.get());
      }
    }
  }

  /**
   * Collide component with another
   * @param other
   */
  function collide(other: ColliderComponent): Array<CollisionContact> {
    var colliderA = this._collider;
    var colliderB = other._collider;
    if (!colliderA || !colliderB) {
      return [];
    }

    // If we have a composite left hand side :(
    // Might bite us, but to avoid updating all the handlers make composite always left side
    var flipped = false;
    if (Std.isOfType(colliderB, CompositeCollider)) {
      colliderA = colliderB;
      colliderB = this._collider;
      flipped = true;
    }

    if (this._collider) {
      final contacts = colliderA.collide(colliderB);
      if (contacts) {
        if (flipped) {
          contacts.forEach((contact) => {
            contact.mtv = contact.mtv.negate();
            contact.normal = contact.normal.negate();
            contact.tangent = contact.normal.perpendicular();
            contact.colliderA = this._collider;
            contact.colliderB = other._collider;
          });
        }
        return contacts;
      }
      return [];
    }
    return [];
  }

  function onAdd(entity: Entity) {
    if (this._collider) {
      this.update();
    }
    // Wire up the collider events to the owning entity
    this.events.on('precollision', (evt: Dynamic) -> {
      final precollision = evt;
      entity.events.emit(
        'precollision',
        new PreCollisionEvent(precollision.self, precollision.other, precollision.side, precollision.intersection, precollision.contact)
      );
      if (Std.isOfType(entity, Actor)) {
        entity.onPreCollisionResolve(precollision.self, precollision.other, precollision.side, precollision.contact);
      }
    });
    this.events.on('postcollision', (evt: Dynamic) -> {
      final postcollision = evt;
      entity.events.emit(
        'postcollision',
        new PostCollisionEvent(
          postcollision.self,
          postcollision.other,
          postcollision.side,
          postcollision.intersection,
          postcollision.contact
        )
      );
      if (Std.isOfType(entity, Actor)) {
        entity.onPostCollisionResolve(postcollision.self, postcollision.other, postcollision.side, postcollision.contact);
      }
    });
    this.events.on('collisionstart', (evt: Dynamic) -> {
      final start = evt;
      entity.events.emit('collisionstart', new CollisionStartEvent(start.self, start.other, start.side, start.contact));
      if (Std.isOfType(entity, Actor)) {
        entity.onCollisionStart(start.self, start.other, start.side, start.contact);
      }
    });
    this.events.on('collisionend', (evt: Dynamic) -> {
      final end = evt;
      entity.events.emit('collisionend', new CollisionEndEvent(end.self, end.other, end.side, end.lastContact));
      if (Std.isOfType(entity, Actor)) {
        entity.onCollisionEnd(end.self, end.other, end.side, end.lastContact);
      }
    });
  }

  function onRemove() {
    this.events.clear();
    this.colliderRemoved.notifyAll(this._collider);
  }

  /**
   * Sets up a box geometry based on the current bounds of the associated actor of this physics body.
   *
   * If no width/height are specified the body will attempt to use the associated actor's width/height.
   *
   * By default, the box is center is at (0, 0) which means it is centered around the actors anchor.
   */
  function useBoxCollider(width: Int, height: Int, anchor: Vector = Vector.Half, center: Vector = Vector.Zero): PolygonCollider {
    final collider = Shape.Box(width, height, anchor, center);
    return this.set(collider);
  }

  /**
   * Sets up a {@apilink PolygonCollider | `polygon`} collision geometry based on a list of of points relative
   *  to the anchor of the associated actor
   * of this physics body.
   *
   * Only [convex polygon](https://en.wikipedia.org/wiki/Convex_polygon) definitions are supported.
   *
   * By default, the box is center is at (0, 0) which means it is centered around the actors anchor.
   */
  function usePolygonCollider(points: Array<Vector>, center: Vector = Vector.Zero): PolygonCollider {
    final poly = Shape.Polygon(points, center);
    return this.set(poly);
  }

  /**
   * Sets up a {@apilink Circle | `circle collision geometry`} as the only collider with a specified radius in pixels.
   *
   * By default, the box is center is at (0, 0) which means it is centered around the actors anchor.
   */
  function useCircleCollider(radius: Int, center: Vector = Vector.Zero): CircleCollider {
    final collider = Shape.Circle(radius, center);
    return this.set(collider);
  }

  /**
   * Sets up an {@apilink Edge | `edge collision geometry`} with a start point and an end point relative to the anchor of the associated actor
   * of this physics body.
   *
   * By default, the box is center is at (0, 0) which means it is centered around the actors anchor.
   */
  function useEdgeCollider(begin: Vector, end: Vector): EdgeCollider {
    final collider = Shape.Edge(begin, end);
    return this.set(collider);
  }

  /**
   * Setups up a {@apilink CompositeCollider} which can define any arbitrary set of excalibur colliders
   * @param colliders
   */
  function useCompositeCollider(colliders: Array<Collider>): CompositeCollider {
    return this.set(new CompositeCollider(colliders));
  }
}
