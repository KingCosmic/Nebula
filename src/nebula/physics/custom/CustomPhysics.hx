package nebula.physics.custom;

import nebula.scenes.Scene;

class CustomPhysics {
	/**
	 * The reference to scene this physics instance belongs to.
	 */
	public var scene:Scene;

	public function new(_scene:Scene) {
		scene = _scene;

		// we assign this event here so we don't
		// manually have to call it and it gets auto cleaned up. (real nice)
		scene.events.on('POST_UPDATE', postUpdate);
	}

	/**
	 * The entire engine already updates on a fixed timestep
   * so no need to account for that ourselves.
	 */
	public function postUpdate(time:Float, delta:Float) {
		// TODO: physic updates
	}
}