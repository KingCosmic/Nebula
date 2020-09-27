package core.gameobjects;

import core.input.InteractiveObject;
import core.math.MATH_CONST;
import core.textures.Frame;
import core.textures.Texture;
import core.cameras.Camera;
import core.scene.Scene;

import core.math.Angle;

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
	public var input:Null<InteractiveObject>;

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

  // Private internal value. Holds the horizontal scale value.
  private var _scaleX:Float = 1;

  // Private internal value. Holds the vertical scale value.
  private var _scaleY:Float = 1;

  // Private internal value. Holds the rotation value in radians.
  private var _rotation:Float = 0;

  // private + read only
  private var _displayOriginX:Float = 0;
	private var _displayOriginY:Float = 0;

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
		* Pass this Game Object to the Input Manager to enable it for Input.
		*
		* Input works by using hit areas, these are nearly always geometric shapes, such as rectangles or circles, that act as the hit area
		* for the Game Object. However, you can provide your own hit area shape and callback, should you wish to handle some more advanced
		* input detection.
		*
		* If no arguments are provided it will try and create a rectangle hit area based on the texture frame the Game Object is using. If
		* this isn't a texture-bound object, such as a Graphics or BitmapText object, this will fail, and you'll need to provide a specific
	 * shape for it to use.
	 *
	 * You can also provide an Input Configuration Object as the only argument to this method.
   */
  public function setInteractive(?hitArea:Any, ?hitAreaCallback = null, ?dropZone:Bool = false) {
    scene.sys.input.enable(this, hitArea, hitAreaCallback, dropZone);

    return this;
  }

	/**
	 * If this Game Object has previously been enabled for input, this will disable it.
	 *
	 * An object that is disabled for input stops processing or being considered for
	 * input events, but can be turned back on again at any time by simply calling
	 * `setInteractive()` with no arguments provided.
	 *
	 * If want to completely remove interaction from this Game Object then use `removeInteractive` instead.
   */
  public function disableInteractive() {
    if (input != null)
      input.enabled = false;

    return this;
  }

	/**
	 * If this Game Object has previously been enabled for input, this will queue it
	 * for removal, causing it to no longer be interactive. The removal happens on
	 * the next game step, it is not immediate.
	 *
	 * The Interactive Object that was assigned to this Game Object will be destroyed,
	 * removed from the Input Manager and cleared from this Game Object.
	 *
	 * If you wish to re-enable this Game Object at a later date you will need to
	 * re-create its InteractiveObject by calling `setInteractive` again.
	 *
	 * If you wish to only temporarily stop an object from receiving input then use
	 * `disableInteractive` instead, as that toggles the interactive state, where-as
	 * this erases it completely.
	 *
	 * If you wish to resize a hit area, don't remove and then set it as being
	 * interactive. Instead, access the hitarea object directly and resize the shape
	 * being used. I.e.: `sprite.input.hitArea.setSize(width, height)` (assuming the
	 * shape is a Rectangle, which it is by default.)
   */
  public function removeInteractive() {
    scene.input.clear(this);

    input = null;

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

    input = null;

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
  
  /**
   * This is a special setter that allows you to set both the horizontal and vertical scale of this Game Object
   * to the same value, at the same time. When reading this value the result returned is `(scaleX + scaleY) / 2`.
   *
   * Use of this property implies you wish the horizontal and vertical scales to be equal to each other. If this
   * isn't the case, use the `scaleX` or `scaleY` properties instead.
   */
  public var scale(get, set):Float;

  function get_scale() {
    return (_scaleX + _scaleY) / 2;
  }

  function set_scale(value:Float) {
    _scaleX = value;
    _scaleY = value;

    return value;
  }

  /**
   * The horizontal scale of this Game Object.
   */
  public var scaleX(get, set):Float;

  function get_scaleX() {
    return _scaleX;
  }

  function set_scaleX(value:Float) {
    _scaleX = value;

    return _scaleX;
  }

  /**
   * The vertical scale of this Game Object.
   */
  public var scaleY(get, set):Float;

  function get_scaleY() {
    return _scaleY;
  }

  function set_scaleY(value:Float) {
    _scaleY = value;

    return _scaleY;
  }

  /**
   * The angle of this Game Object as expressed in degrees.
   *
   * Phaser uses a right-hand clockwise rotation system, where 0 is right, 90 is down, 180/-180 is left
   * and -90 is up.
   *
   * If you prefer to work in radians, see the `rotation` property instead.
   */
  public var angle(get, set):Float;

  function get_angle() {
    return Angle.wrapDegrees(_rotation * MATH_CONST.RAD_TO_DEG);
  }

  function set_angle(value:Float) {
    // value is in degrees
    rotation = Angle.wrapDegrees(value) * MATH_CONST.DEG_TO_RAD;
    return rotation;
  }

  /**
   * The angle of this Game Object in radians.
   *
   * Phaser uses a right-hand clockwise rotation system, where 0 is right, PI/2 is down, +-PI is left
   * and -PI/2 is up.
   *
   * If you prefer to work in degrees, see the `angle` property instead.
   */
  public var rotation(get, set):Float;

  function get_rotation() {
    return _rotation;
  }

  function set_rotation(value:Float) {
    // value is in radians
    _rotation = Angle.wrap(value);

    return _rotation;
  }

	/**
	 * Sets the rotation of this Game Object.
	 */
	public function setRotation(?radians:Float = 0) {
    rotation = radians;

		return this;
  }

  /**
   * Sets the angle of this Game Object.
   */
  public function setAngle(?degrees:Float = 0) {
    angle = degrees;

    return this;
  }
  
  /**
   * Sets the scale of this Game Object.
   */
  public function setScale(?x:Float = 1, ?y:Float) {
    if (y == null) y = x;

    scaleX = x;
    scaleY = y;

    return this;
  }

  /**
   * The horizontal display origin of this Game Object.
   * The origin is a normalized value between 0 and 1.
   * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
   */
  public var displayOriginX(get, set):Float;

  function get_displayOriginX() {
    return _displayOriginX;
  }

  function set_displayOriginX(value:Float) {
    _displayOriginX = value;
    originX = value / width;

    return _displayOriginX;
  }

  /**
   * The vertical display origin of this Game Object.
   * The origin is a normalized value between 0 and 1.
   * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
   */
  public var displayOriginY(get, set):Float;

  function get_displayOriginY() {
    return _displayOriginY;
  }

  function set_displayOriginY(value:Float) {
    _displayOriginY = value;
    originY = value / height;

    return _displayOriginY;
  }

  /**
   * Sets the origin of this Game Object.
   *
   * The values are given in the range 0 to 1.
   */
  public function setOrigin(?x:Float = 0.5, ?y:Float) {
    if (y == null) y = x;

    originX = x;
    originY = y;

    // TODO: return updateDisplayOrigin();
  }
}