package core.structs;

import core.utils.ArrayUtils;

// List is a generic implementation of an ordered list which contains utility methods for retrieving, manipulating, and iterating items.
class List<T> {
  // The parent of this list.
  public var parent:Any;

  // The objects that belong to this list.
  public var children:Array<T> = [];

  // The index of the current element.
	// This is used internally when iterating through the list with the {@link #first}, {@link #last}, {@link #get}, and {@link #previous} properties.
  public var position:Int = 0;

  // A callback that is invoked every time a child is added to this list.
  public var addCallback:T->Void = (item:T) -> {};

  // A callback that is invoked everytime a child is removed from this list.
  public var removeCallback:T->Void = (item:T) -> {};

  // The property key to sort by.
  public var _sortKey:String = '';

  public function new(_parent:Any) {
    parent = _parent;
  }

  // Adds the given item to the end of the list. Each item must be unique.
  public function add(child:Array<T>, ?skipCallback:Bool = false) {
    if (skipCallback) {
      return ArrayUtils.add(children, child);
    } else {
			return ArrayUtils.add(children, child, 0, addCallback);
    }
  }

  // Adds an item to list, starting at a specified index. Each item must be unique within the list.
  public function addAt(child:Array<T>, index:Int, ?skipCallback:Bool = false) {
    if (skipCallback) {
      return ArrayUtils.addAt(children, child, index);
    } else {
			return ArrayUtils.addAt(children, child, index, addCallback);
    }
  }

  // Retrieves the item at a given position inside the List.
  public function getAt(index:Int) {
    return children[index];
  }

  // Locates an item within the List and returns it's index.
  public function getIndex(child:T) {
    // Return -1 if given child isn't a child of this display list
    return children.indexOf(child);
  }

  /**
   * Sort the contents of this List so the items are in order based on the given property.
   * For example, `sort('alpha')` would sort the List contents based on the value of their `alpha` property.
   */


  // Removes one or many items from the List.
  public function remove(child:Array<T>, ?skipCallback:Bool = false) {
    if (skipCallback) {
      return ArrayUtils.remove(children, child);
    } else {
			return ArrayUtils.remove(children, child, removeCallback);
    }
  }
}