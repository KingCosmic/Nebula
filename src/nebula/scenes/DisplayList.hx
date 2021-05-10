package nebula.scenes;

import nebula.gameobjects.GameObject;
import nebula.utils.ArrayUtils;

class DisplayList {
	// The objects that belong to this list.
	public var children:Array<GameObject> = [];

	// The index of the current element.
	// This is used internally when iterating through the list with the {@link #first}, {@link #last}, {@link #get}, and {@link #previous} properties.
	public var position:Int = 0;

	// A callback that is invoked every time a child is added to this list.
	public var addCallback:GameObject->Void = (item:GameObject) -> {};

	// A callback that is invoked everytime a child is removed from this list.
	public var removeCallback:GameObject->Void = (item:GameObject) -> {};

	// The property key to sort by.
	public var _sortKey:String = '';

	// The flag the determines whether Game Objects should be sorted when `depthSort()` is called.
	public var sortChildrenFlag:Bool = false;

	// The Scene that this Display List belongs to.
	public var scene:Scene;

	// The Scene's Event Emitter
	public var events:EventEmitter;

	public function new(_scene:Scene) {
		scene = _scene;

		events = scene.events;

		addCallback = addChildCallback;
		removeCallback = removeChildCallback;

		events.once('BOOT', boot);
		events.on('START', start);
	}

	/**
	 * Adds the given item to the end of the list. Each item must be unique.
	 */
	public function add(child:Array<GameObject>, ?skipCallback:Bool = false) {
		if (skipCallback) {
			return ArrayUtils.add(children, child);
		} else {
			return ArrayUtils.add(children, child, 0, addCallback);
		}
	}

	/**
	 * Adds an item to list, starting at a specified index. Each item must be unique within the list. 
	 */
	public function addAt(child:Array<GameObject>, index:Int, ?skipCallback:Bool = false) {
		if (skipCallback) {
			return ArrayUtils.addAt(children, child, index);
		} else {
			return ArrayUtils.addAt(children, child, index, addCallback);
		}
	}

	/**
	 * Retrieves the item at a given position inside the List
   */
	public function getAt(index:Int) {
		return children[index];
	}

	/**
	 * Locates an item within the List and returns it's index.
	 */
	public function getIndex(child:GameObject) {
		// Return -1 if given child isn't a child of this display list
		return children.indexOf(child);
	}

	/**
	 * Removes one or many items from the List.
	 */
	public function remove(child:Array<GameObject>, ?skipCallback:Bool = false) {
		if (skipCallback) {
			return ArrayUtils.remove(children, child);
		} else {
			return ArrayUtils.remove(children, child, removeCallback);
		}
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
		if (!sortChildrenFlag)
			return;

		// StableSort(children, sortByDepth);

		sortChildrenFlag = false;
	}

	// Compare the depth of two Game Objects.
	public function sortByDepth(childA:GameObject, childB:GameObject) {
		return childA.depth - childB.depth;
	}

	/**
	 * 
	 */
  public function getById(id:String):Null<GameObject> {
    // grab our list of children with this id.
		var res = children.filter(go -> go.id == id);

    // do we have that go in list?
    if (res.length == 0) return null;

    // return it.
    return res[0];
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
			if (children[i] != null)
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
		events = null;
	}
}