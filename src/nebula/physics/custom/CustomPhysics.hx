package nebula.physics.custom;

import nebula.gameobjects.GameObject;
import nebula.scenes.Scene;

typedef GoPhysicsConfig = {

}

/**
 * Scene plugin for custom physics.
 */
class CustomPhysics {
	/**
	 * The reference to scene this physics instance belongs to.
	 */
	public var scene:Scene;

	/**
	 * Holds the physics config for each object managed by this plugin
	 */
	public var configs:Map<String, GoPhysicsConfig> = new Map();

	public function new(_scene:Scene) {
		scene = _scene;

		// we assign this event here so we don't
		// manually have to call it and it gets auto cleaned up. (real nice)
		scene.events.on('POST_UPDATE', postUpdate);
    scene.events.once('DESTROY', destroy);
	}

	/**
	 * The entire engine already updates on a fixed timestep
   * so no need to account for that ourselves.
	 */
	public function postUpdate(time:Float, delta:Float) {
		// TODO: finish physic updates

    // loop through our configs.
    for (value in configs.keyValueIterator()) {
      // the id of our gameobject, used to grab it from the scene's
      // internal list.
      var key = value.key;

      // the config object for how physics should work on this object.
      var config = value.value;

      // grab our go from the display list (doubt physics will run on
      // hidden go's)
      var go:GameObject = scene.displayList.getById(key);

      // we have a id for a object that doest exist?
      if (go == null) continue;

      // do calcs.
    }
	}

  /**
   * clear our references when the scene is destroyed.
   */
  public function destroy() {
    scene = null;
    configs.clear();
  }
}