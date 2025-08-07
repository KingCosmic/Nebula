package nebula.entitycomponentsystem.components;

import nebula.math.Vector;

import nebula.entitycomponentsystem.Component;

interface Motion {
  /**
   * The velocity of an entity in pixels per second
   */
  var vel: Vector;

  /**
   * The maximum component-wise velocity of an entity in pixels per second
   */
  var maxVel: Vector;

  /**
   * The acceleration of entity in pixels per second^2
   */
  var acc: Vector;

  /**
   * The scale rate of change in scale units per second
   */
  var scaleFactor: Vector;

  /**
   * The angular velocity which is how quickly the entity is rotating in radians per second
   */
  var angularVelocity: Float;

  /**
   * The amount of torque applied to the entity, angular acceleration is torque * inertia
   */
  var torque: Float;

  /**
   * Inertia can be thought of as the resistance to motion
   */
  var inertia: Float;
}

class MotionComponent extends Component {
  /**
   * The velocity of an entity in pixels per second
   */
  public var vel: Vector = Vector.Zero;

  /**
   * The maximum component-wise velocity of an entity in pixels per second
   */
  public var maxVel: Vector = Vector.One.scaleEqual(Infinity);

  /**
   * The acceleration of entity in pixels per second^2
   */
  public var acc: Vector = Vector.Zero;

  /**
   * The scale rate of change in scale units per second
   */
  public var scaleFactor: Vector = Vector.Zero;

  /**
   * The angular velocity which is how quickly the entity is rotating in radians per second
   */
  public var angularVelocity = 0;

  /**
   * The amount of torque applied to the entity, angular acceleration is torque * inertia
   */
  public var torque: Int = 0;

  /**
   * Inertia can be thought of as the resistance to motion
   */
  public var inertia: Int = 1;
}
