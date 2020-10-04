package core.gameobjects;

import core.gameobjects.components.Depth;
import core.scene.Systems;
import core.scene.Scene;
import core.structs.List;

class DisplayList extends List<GameObject> {
  // The flag the determines whether Game Objects should be sorted when `depthSort()` is called.
  public var sortChildrenFlag:Bool = false;

  // The Scene that this Display List belongs to.
  public var scene:Scene;

  // The Scene's Systems.
  public var systems:Systems;

  // The Scene's Event Emitter
  public var events:EventEmitter;

	public function new(_scene:Scene, _systems:Systems) {
    super(this);
    scene = _scene;

    systems = _systems;

    events = scene.events;

    addCallback = addChildCallback;
    removeCallback = removeChildCallback;

    events.once('BOOT', boot);
    events.on('START', start);
  }

  /**
   * This method is called automatically, only once, when the Scene is first created.
   * Do not invoke it directly.
   */
  public function boot() {
    events.once('DESTROY', destroy);
  }

  /**
   * Internal method called from `List.addCallback`.
   */
  public function addChildCallback(child:GameObject) {
    child.emit('ADDED_TO_SCENE', child, scene);
    
		events.emit('ADDED_TO_SCENE', child, scene);
  }

  // Internal method called from `List.removeCallback`
	public function removeChildCallback(child:GameObject) {
		child.emit('REMOVED_TO_SCENE', child, scene);

		events.emit('REMOVED_TO_SCENE', child, scene);
  }
  
  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    events.once('SHUTDOWN', shutdown);
  }

  /**
   * Force a sort of the display list on the next call to depthSort.
   */
  public function queueDepthSort() {
    sortChildrenFlag = true;
  }

  // Immediately sorts the display list if the flag is set.
  public function depthSort() {
    if (!sortChildrenFlag) return;

    // StableSort(children, sortByDepth);

    sortChildrenFlag = false;
  }

  // Compare the depth of two Game Objects.
	public function sortByDepth(childA:Depth, childB:Depth) {
    return childA.depth - childB.depth;
  }

  /**
   * Returns an array which contains all objects currently on the Display List.
   * This is a reference to the main list array, not a copy of it, so be careful not to modify it.
   */
  public function getChildren() {
    return children;
  }

  /**
   * The Scene that owns this plugin is shutting down.
   * We need to kill and reset all internal properties as well as stop listening to Scene events.
   */
  public function shutdown() {
    var i = children.length;

    while (i > 0) {
      children[i].destroy(true);
      i--;
    }

    events.removeListener('SHUTDOWN', shutdown);
  }

  /**
   * The Scene that owns this plugin is being destroyed.
   * We need to shutdown and then kill off all external references.
   */
  public function destroy() {
    shutdown();

    events.removeListener('START', start);

    scene = null;
    systems = null;
    events = null;
  }
}