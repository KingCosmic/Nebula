package nebula.entitycomponentsystem.components;

import nebula.math.Vector;
import nebula.math.CoordPlane;
import nebula.math.Transform;

import nebula.entitycomponentsystem.Component;
import nebula.entitycomponentsystem.Entity;

import nebula.util.Observable;
import nebula.util.Log;

class TransformComponent extends Component {
  private var _logger = Logger.getInstance();
  private var _parentComponent: Null<TransformComponent> = null;
  private var _transform = new Transform();
  public function get() {
    return this._transform;
  }

  private var _addChildTransform = (child: Entity) -> {
    final childTxComponent = child.get(TransformComponent);
    if (childTxComponent) {
      childTxComponent._transform.parent = this._transform;
      childTxComponent._parentComponent = this;
    }
  };
  function onAdd(owner: Entity) {
    for (child in owner.children) {
      this._addChildTransform(child);
    }
    owner.childrenAdded.subscribe((child) => this._addChildTransform(child));
    owner.childrenRemoved.subscribe((child) => {
      final childTxComponent = child.get(TransformComponent);
      if (childTxComponent) {
        childTxComponent._transform.parent = null;
        childTxComponent._parentComponent = null;
      }
    });
  }
  function onRemove(_previousOwner: Entity) {
    this._transform.parent = null;
    this._parentComponent = null;
  }

  /**
   * Observable that emits when the z index changes on this component
   */
  public var zIndexChanged = new Observable<Int>();

  /**
   * The z-index ordering of the entity, a higher values are drawn on top of lower values.
   * For example z=99 would be drawn on top of z=0.
   */
  public var z(get, set): Int;
  function get_z(): Int {
    return this._transform.z;
  }
  function set_z(val: Int) {
    final oldz = this._transform.z;
    this._transform.z = val;
    if (oldz != val) {
      this.zIndexChanged.notifyAll(val);
    }
  }

  public var globalZ(get, set): Int;
  function get_globalZ() {
    return this._transform.globalZ;
  }

  function set_globalZ(z: Int) {
    this._transform.globalZ = z;
  }

  private var _coordPlane = CoordPlane.World;
  /**
   * The {@apilink CoordPlane | `coordinate plane`} for this transform for the entity.
   */
  public var coordPlane(get, set): CoordPlane;
  function get_coordPlane() {
    if (this._parentComponent) {
      return this._parentComponent.coordPlane;
    }
    return this._coordPlane;
  }

  function set_coordPlane(value: CoordPlane) {
    if (!this._parentComponent) {
      this._coordPlane = value;
    } else {
      this._logger.warn(
        'Cannot set coordinate plane on child entity ${this.owner?.name}, children inherit their coordinate plane from their parents.'
      );
    }
  }

  public var pos(get, set): Vector;
  function get_pos() {
    return this._transform.pos;
  }
  function set_pos(v: Vector) {
    this._transform.pos = v;
  }

  public var globalPos(get, set): Vector;
  function get_globalPos() {
    return this._transform.globalPos;
  }
  function set_globalPos(v: Vector) {
    this._transform.globalPos = v;
  }

  public var rotation(get, set): Int;
  function get_rotation() {
    return this._transform.rotation;
  }
  function set_rotation(rotation: Int) {
    this._transform.rotation = rotation;
  }

  public var globalRotation(get, set): Int;
  function get_globalRotation() {
    return this._transform.globalRotation;
  }
  function set_globalRotation(rotation: Int) {
    this._transform.globalRotation = rotation;
  }

  public var scale(get, set): Vector;
  function get_scale() {
    return this._transform.scale;
  }
  function set_scale(v: Vector) {
    this._transform.scale = v;
  }

  public var globalScale(get, set): Vector;
  function get_globalScale() {
    return this._transform.globalScale;
  }
  function set_globalScale(v: Vector) {
    this._transform.globalScale = v;
  }

  function applyInverse(v: Vector) {
    return this._transform.applyInverse(v);
  }

  function apply(v: Vector) {
    return this._transform.apply(v);
  }

  function clone(): TransformComponent {
    final component = new TransformComponent();
    component._transform = this._transform.clone();
    return component;
  }
}
