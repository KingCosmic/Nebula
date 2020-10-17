package core.input;

import core.gameobjects.RenderableGameObject;
import core.geom.rectangle.Rectangle;

/**
 * Creates a new Interactive Object.
 *
 * This is called automatically by the Input Manager when you enable a Game Object for input.
 *
 * The resulting Interactive Object is mapped to the Game Object's `input` property.
 */
class InteractiveObject {
  // The game object this interactive object belongs to.
	public var gameObject:RenderableGameObject;

  public var enabled:Bool = true;

  public var alwaysEnabled:Bool = false;

  public var isDraggable:Bool = false;

  public var dropZone:Bool = false;

  public var cursor:Bool = false;

  public var target = null;
  
  public var camera = null;

  public var hitArea:Rectangle;

	public var hitAreaCallback:Rectangle->Float->Float->RenderableGameObject->Bool;
  
  public var localX:Float = 0;
  public var localY:Float = 0;

  // 0 = Not being dragged
  // 1 = Being checked for dragging
  // 2 = Being dragged
  public var dragState = 0;

  public var dragStartX:Float = 0;
  public var dragStartY:Float = 0;
  public var dragStartXGlobal:Float = 0;
  public var dragStartYGlobal:Float = 0;

  public var dragX:Float = 0;
  public var dragY:Float = 0;

	public function new(_go:RenderableGameObject, _hitArea:Rectangle, _hitAreaCallback:Rectangle->Float->Float->RenderableGameObject->Bool) {
    gameObject = _go;
    hitArea = _hitArea;
    hitAreaCallback = _hitAreaCallback;
  }
}