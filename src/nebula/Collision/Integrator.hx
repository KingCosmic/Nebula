package nebula.collision;

import nebula.math.Vector;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.components.MotionComponent;

class EulerIntegrator {
  // Scratch vectors to avoid allocation
  private static var _POS = new Vector(0, 0);
  private static var _SCALE = new Vector(1, 1);

  private static var _ACC = new Vector(0, 0);
  private static var _VEL = new Vector(0, 0);
  private static var _VEL_ACC = new Vector(0, 0);
  private static var _SCALE_FACTOR = new Vector(0, 0);

  static function integrate(transform: TransformComponent, motion: MotionComponent, totalAcc: Vector, elapsed: Float) {
    final seconds = elapsed / 1000;
    // This code looks a little wild, but it's to avoid creating any new Vector instances
    // integration is done in a tight loop so this is key to avoid GC'ing
    motion.vel.addEqual(totalAcc.scale(seconds, EulerIntegrator._ACC));
    // clamp the components of the velocity vector
    motion.vel.setTo(clamp(motion.vel.x, -motion.maxVel.x, motion.maxVel.x), clamp(motion.vel.y, -motion.maxVel.y, motion.maxVel.y));

    transform.pos
      .add(motion.vel.scale(seconds, EulerIntegrator._VEL), EulerIntegrator._POS)
      .addEqual(totalAcc.scale(0.5 * seconds * seconds, EulerIntegrator._VEL_ACC));

    motion.angularVelocity += motion.torque * (1.0 / motion.inertia) * seconds;
    final rotation = transform.rotation + motion.angularVelocity * seconds;

    transform.scale.add(motion.scaleFactor.scale(seconds, this._SCALE_FACTOR), EulerIntegrator._SCALE);
    final tx = transform.get();
    tx.setTransform(EulerIntegrator._POS, rotation, EulerIntegrator._SCALE);
  }
}
