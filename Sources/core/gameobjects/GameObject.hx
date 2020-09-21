package core.gameobjects;

import core.textures.Frame;
import core.textures.Texture;
import core.cameras.Camera;
import core.scene.Scene;

/**
 * The base class that all Game Objects extend.
 * You don't create GameObjects directly and they cannot be added to the display list.
 * Instead, use them as the base for your own custom classes.
 */
class GameObject extends EventEmitter {
  /**
   * The Scene to which this Game Object belongs.
   * Game Objects can only belong to one Scene.
   */
  public var scene:Scene;

  /**
   * A textual representation of this Game Object, i.e. `sprite`.
   * Used internally by Phaser but is available for your own custom classes to populate.
   */
  public var type:String;

  /**
   * The current state of this Game Object.
   *
   * Phaser itself will never modify this value, although plugins may do so.
   *
   * Use this property to track the state of a Game Object during its lifetime. For example, it could change from
   * a state of 'moving', to 'attacking', to 'dead'. The state value should be an integer (ideally mapped to a constant
   * in your game code), or a string. These are recommended to keep it light and simple, with fast comparisons.
   * If you need to store complex data about your Game Object, look at using the Data Component instead.
   */
  public var state:String = 'default';

  // The parent Container of this Game Object, if it has one.
  // public var parentContainer:core.gameobjects.Container;

  /**
   * The name of this Game Object.
   * Empty by default and never populated by Phaser, this is left for developers to use.
   */
  public var name:String = '';

  /**
   * The active state of this Game Object.
   * A Game Object with an active state of `true` is processed by the Scenes UpdateList, if added to it.
   * An active object is one which is having its logic and internal systems updated.
   */
  public var active:Bool = true;

  // The visible state of this GameObject
  public var visible:Bool = true;

  // Alpha of this gameobject
  public var alpha:Float = 1;

  // Depth of this gameobject (used in rendering order)
  public var depth:Int = 0;

  /**
   * The Tab Index of the Game Object.
   * Reserved for future use by plugins and the Input Manager.
   */
  public var tabIndex:Int = -1;

  /**
   * A Data Manager.
   * It allows you to store, query and get key/value paired information specific to this Game Object.
   * `null` by default. Automatically created if you use `getData` or `setData` or `setDataEnabled`.
   */
  public var data = null;

  /**
   * The flags that are compared against `RENDER_MASK` to determine if this Game Object will render or not.
   * The bits are 0001 | 0010 | 0100 | 1000 set by the components Visible, Alpha, Transform and Texture respectively.
   * If those components are not used by your custom class then you can use this bitmask as you wish.
   */
  public var renderFlags:Int = 15;

  /**
   * A bitmask that controls if this Game Object is drawn by a Camera or not.
   * Not usually set directly, instead call `Camera.ignore`, however you can
   * set this property directly using the Camera.id property
   */
  public var cameraFilter:Int = 0;

  /**
   * If this Game Object is enabled for input then this property will contain an InteractiveObject instance.
   * Not usually set directly. Instead call `GameObject.setInteractive()`.
   */
  public var input = null;

  // If this Game Object is enabled for Arcade or Matter Physics then this property will contain a reference to a Physics Body.
  public var body = null;

  // just here to fix camera type issues
  public var width:Float = 0; 
  public var height:Float = 0;
  public var x:Float = 0;
  public var y:Float = 0;
  public var scrollFactorX:Float = 1;
  public var scrollFactorY:Float = 1;
  public var originX:Float = 0.5;
  public var originY:Float = 0.5;
  
  // here to fix texture type issues
  public var texture:Texture;
  public var frame:Frame;

  /**
   * This Game Object will ignore all calls made to its destroy method if this flag is set to `true`.
   * This includes calls that may come from a Group, Container or the Scene itself.
   * While it allows you to persist a Game Object across Scenes, please understand you are entirely
   * responsible for managing references to and from this Game Object.
   */
  public var ignoreDestroy:Bool = false;

  public function new(_scene:Scene, _type:String) {
    super();

    scene = _scene;
    type = _type;

    // Tell the Scene to re-sort the children.
    scene.sys.queueDepthSort();
  }

  /**
   * Sets the `active` property of this Game Object and returns this Game Object for further chaining.
   * A Game Object with its `active` property set to `true` will be updated by the Scenes UpdateList.
   */
  public function setActive(value:Bool) {
    active = value;

    return this;
  }

	/**
	 * Sets the `visible` property of this Game Object and returns this Game Object for further chaining.
	 * A Game Object with its `visible` property set to `true` will be rendered by the Scenes DisplayList.
   */
	public function setVisible(value:Bool) {
		visible = value;

		return this;
	}

  /**
   * Sets the `name` property of this Game Object and returns this Game Object for further chaining.
   * The `name` property is not populated by Phaser and is presented for your own use.
   */
  public function setName(value:String) {
    name = value;

    return this;
  }

  /**
   * Sets the current state of this Game Object.
   *
   * Phaser itself will never modify the State of a Game Object, although plugins may do so.
   *
   * For example, a Game Object could change from a state of 'moving', to 'attacking', to 'dead'.
   * The state value should typically be an integer (ideally mapped to a constant
   * in your game code), but could also be a string. It is recommended to keep it light and simple.
   * If you need to store complex data about your Game Object, look at using the Data Component instead.
   */
  public function setState(value:String) {
    state = value;

    return this;
  }

  // TODO: Add data manager code.

  // TODO: add input enabled code.

  /**
   * This callback is invoked when this Game Object is added to a Scene.
   *
   * Can be overriden by custom Game Objects, but be aware of some Game Objects that
   * will use this, such as Sprites, to add themselves into the Update List.
   *
   * You can also listen for the `ADDED_TO_SCENE` event from this Game Object.
   */
  public function addedToScene() {}

  /**
   * This callback is invoked when this Game Object is removed from a Scene.
   *
   * Can be overriden by custom Game Objects, but be aware of some Game Objects that
   * will use this, such as Sprites, to removed themselves from the Update List.
   *
   * You can also listen for the `REMOVED_FROM_SCENE` event from this Game Object.
   */
  public function removedFromScene() {}

  /**
   * To be overridden by custom GameObjects. Allows base objects to be used in a Pool.
   */
  public function preUpdate() {}

  /**
   * This callback is invoked before this Game Object is destroyed
   */
  public function preDestroy() {}

  // TODO: toJSON()

  /**
   * Compares the renderMask with the renderFlags to see if this Game Object will render or not.
   * Also checks the Game Object against the given Cameras exclusion list.
   */
  public function willRender(camera:Camera) {
		return !(15 != renderFlags || (cameraFilter != 0 && (cameraFilter & camera.id) == 1));
  }

  /**
   * Returns an array containing the display list index of either this Game Object, or if it has one,
   * its parent Container. It then iterates up through all of the parent containers until it hits the
   * root of the display list (which is index 0 in the returned array).
   *
   * Used internally by the InputPlugin but also useful if you wish to find out the display depth of
   * this Game Object and all of its ancestors.
   */
  // TODO: add in parentContainer code
  public function getIndexList() {
    var indexes = [];

    indexes.unshift(scene.sys.displayList.getIndex(this));
    
    return indexes;
  }

	/**
   * Sets the texture and frame this Game Object will use to render with.
   *
   * Textures are referenced by their string-based keys, as stored in the Texture Manager.
   */
  public function setTexture(key:String, frame:String) {
    texture = scene.sys.textures.get(key);

    return setFrame(frame);
  }

	/**
	 * Sets the frame this Game Object will use to render with.
	 *
	 * The Frame has to belong to the current Texture being used.
	 *
	 * It can be either a string or an index.
	 *
	 * Calling `setFrame` will modify the `width` and `height` properties of your Game Object.
	 * It will also change the `origin` if the Frame has a custom pivot point, as exported from packages like Texture Packer.
   */
  public function setFrame(key:String, ?updateSize:Bool = true, ?updateOrigin:Bool = true) {
    var frame = texture.get(key);

    if (updateSize) {
      width = frame.width;
      height = frame.height;
    }

    return this;
  }

  /**
   * Destroys this Game Object removing it from the Display List and Update List and
   * severing all ties to parent resources.
   *
   * Also removes itself from the Input Manager and Physics Manager if previously enabled.
   *
   * Use this to remove a Game Object from your game if you don't ever plan to use it again.
   * As long as no reference to it exists within your own code it should become free for
   * garbage collection by the browser.
   *
   * If you just want to temporarily disable an object then look at using the
   * Game Object Pool instead of destroying it, as destroyed objects cannot be resurrected.
   */
  public function destroy(?fromScene:Bool = false) {
    
    // This Game Object has already been destroyed
    if (scene == null || ignoreDestroy) {
      return;
    }

    preDestroy();

    emit('DESTROY', this);

    if (!fromScene) {
      scene.sys.displayList.remove([this]);
    }

    // TODO: input clear

    // TODO: data clear

    // TODO: physics clear

    // Tell the Scene to re-sort the children
    if (!fromScene) {
      scene.sys.queueDepthSort();
    }

    active = false;
    visible = false;

    scene = null;
    
    removeAllListeners();
  }

	public function render(renderer:Renderer, camera:Camera) {}
}