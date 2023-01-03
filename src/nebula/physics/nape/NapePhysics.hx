package nebula.physics.nape;

import kha.graphics4.Graphics2.SimplePipelineCache;
import nebula.gameobjects.GameObject;
import nebula.scenes.Scene;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Shape;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;

typedef PhysicsConfig = {
  type:String,
  shape:Shape
}

typedef PhysicsGo = {
  body:Body,
  go:GameObject
}

/**
 * Scene plugin for nape physics https://joecreates.github.io/napephys/.
 */
class NapePhysics {
	/**
	 * The reference to scene this physics instance belongs to.
	 */
	public var scene:Scene;

  /**
   * 
   */
  public var gravity = Vec2.weak(0, 600);

  /**
   * Our physics space used by nape for simulation purposes.
   */
  public var space:Space;

  /**
   * Our target fps for our physics engine.
   */
  public var targetFps:Float = 1 / 60;

  /**
   * the current simulation time we have built up for our fixed timestep.
   */
  public var simulationTime:Float = 0.0;

	/**
	 * Holds the physics config for each object managed by this plugin
	 */
	public var gos:Map<String, PhysicsGo> = new Map();

	public function new(_scene:Scene) {
		scene = _scene;

    space = new Space(gravity);

		// we assign this event here so we don't
		// manually have to call it and it gets auto cleaned up. (real nice)
		scene.events.on('POST_UPDATE', postUpdate);
    scene.events.once('DESTROY', destroy);
	}

  public function addGameobject(go:GameObject, config:PhysicsConfig) {
    var body = new Body((config.type == 'dynamic') ? BodyType.DYNAMIC : BodyType.STATIC);

    // box.shapes.add(new Polygon(Polygon.box(16, 32)));
    body.shapes.add(config.shape);

    body.position.setxy(go.x, go.y);
    body.space = space;

    // store our stuff for later use.
    gos.set('id', {
      body: body,
      go: go
    });
  }

	/**
	 * The entire engine already updates on a fixed timestep
   * so no need to account for that ourselves.
	 */
	public function postUpdate(time:Float, delta:Float) {
    // add our delta time to our simulation time.
    simulationTime += delta;

    // Keep on stepping forward by fixed time step until amount of time
    // needed has been simulated.
    while (simulationTime > targetFps) {
      // step our physics loop forward by our simulation step.
      space.step(targetFps);

      // reduce our simulation time by our simulation step.
      simulationTime -= targetFps;
    }

    // loop through our gameobjects
    for (value in gos.keyValueIterator()) {
      var go = value.value.go;
      var body = value.value.body;

      // update their position and rotation to matchup with the physics body.
      go.setPosition(body.position.x, body.position.y);
      go.setRotation(body.rotation);
    }
	}

  /**
   * clear our references when the scene is destroyed.
   */
  public function destroy() {
    scene = null;
    gos.clear();
    space.clear();
  }
}