package nebula.gameobjects;

import nebula.assets.AssetManager;
import nebula.assets.Texture;
import nebula.cameras.Camera;
import nebula.assets.Frame;
import nebula.utils.Nanoid;
import nebula.scenes.Scene;
import nebula.math.Angle;

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
	 * Used internally by Nebula but is available for your own custom classes to populate.
	 */
	public var type:String;

	/**
	 * The id of this object, used so plugins can tell objects apart without having
	 * to store them themselves.
	 */
	public var id:String = Nanoid.generate();

	/**
	 * The active state of this Game Object.
	 * A Game Object with an active state of `true` is processed by the Scenes UpdateList, if added to it.
	 * An active object is one which is having its logic and internal systems updated.
	 */
	public var active:Bool = true;

	/**
	 * A bitmask that controls if this Game Object is drawn by a Camera or not.
	 * Not usually set directly, instead call `Camera.ignore`, however you can
	 * set this property directly using the Camera.id property:
	 */
	public var cameraFilter:Int = 0;

	/**
	 * The alpha value of the Game Object.
	 *
	 * This is a global value, impacting the entire Game Object, not just a region of it.
	 */
	public var alpha:Float = 1;

	/**
	 * Set the Alpha level of this Game Object. The alpha controls the opacity of the Game Object as it renders.
	 * Alpha values are provided as a float between 0, fully transparent, and 1, fully opaque.
	 *
	 * If your game is running under WebGL you can optionally specify four different alpha values, each of which
	 * correspond to the four corners of the Game Object. Under Canvas only the `topLeft` value given is used.
	 */
	public function setAlpha(value:Float = 1):Dynamic {
		alpha = value;

		return this;
	}

	/**
	 * The depth of this Game Object within the Scene.
	 *
	 * The depth is also known as the 'z-index' in some environments, and allows you to change the rendering order
	 * of Game Objects, without actually moving their position in the display list.
	 *
	 * The default depth is zero. A Game Object with a higher depth
	 * value will always render in front of one with a lower value.
	 *
	 * Setting the depth will queue a depth sort event within the Scene.
	 */
	public var depth(default, set):Int = 0;

	function set_depth(value:Int):Int {
		scene.queueDepthSort();

		depth = value;

		return value;
	}

	/**
	 * The depth of this Game Object within the Scene.
	 *
	 * The depth is also known as the 'z-index' in some environments, and allows you to change the rendering order
	 * of Game Objects, without actually moving their position in the display list.
	 *
	 * The default depth is zero. A Game Object with a higher depth
	 * value will always render in front of one with a lower value.
	 *
	 * Setting the depth will queue a depth sort event within the Scene.
	 */
	public function setDepth(value:Int = 0):Dynamic {
		depth = value;

		return this;
	}

	/**
	 * The horizontally flipped state of the Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public var flipX:Bool = false;

	/**
	 * The vertically flipped state of the Game Object.
	 *
	 * A Game Object that is flipped vertically will render inversed on the vertical axis (i.e. upside down)
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public var flipY:Bool = false;

	/**
	 * Toggles the horizontal flipped state of this Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function toggleFlipX():Dynamic {
		flipX = !flipX;

		return this;
	}

	/**
	 * Toggles the vertical flipped state of this Game Object.
	 */
	public function toggleFlipY():Dynamic {
		flipY = !flipY;

		return this;
	}

	/**
	 * Sets the horizontal flipped state of this Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function setFlipX(value:Bool):Dynamic {
		flipX = value;

		return this;
	}

	/**
	 * Sets the vertical flipped state of this Game Object.
	 */
	public function setFlipY(value:Bool):Dynamic {
		flipY = value;

		return this;
	}

	/**
	 * Sets the horizontal and vertical flipped state of this Game Object.
	 *
	 * A Game Object that is flipped will render inversed on the flipped axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function setFlip(x:Bool, y:Bool):GameObject {
		flipX = x;
		flipY = y;

		return this;
	}

	/**
	 * Resets the horizontal and vertical flipped state of this Game Object back to their default un-flipped state.
	 */
	public function resetFlip():GameObject {
		flipX = false;
		flipY = false;

		return this;
	}

	/**
	 * The horizontal origin of this Game Object.
	 * The origin maps the relationship between the size and position of the Game Object.
	 * The default value is 0.5, meaning all Game Objects are positioned based on their center.
	 * Setting the value to 0 means the position now relates to the left of the Game Object.
	 */
	public var originX:Float = 0.5;

	/**
	 * The vertical origin of this Game Object.
	 * The origin maps the relationship between the size and position of the Game Object.
	 * The default value is 0.5, meaning all Game Objects are positioned based on their center.
	 * Setting the value to 0 means the position now relates to the top of the Game Object.
	 */
	public var originY:Float = 0.5;

	/**
	 * Private internal values for displayOrigin
	 */
	public var _displayOriginX:Float = 0;
	public var _displayOriginY:Float = 0;

	/**
	 * The horizontal display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginX(get, set):Float;

	function get_displayOriginX():Float {
		return _displayOriginX;
	}

	function set_displayOriginX(value):Float {
		_displayOriginX = value;
		originX = value / width;

		return value;
	}

	/**
	 * The vertical display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginY(get, set):Float;

	function get_displayOriginY():Float {
		return _displayOriginY;
	}

	function set_displayOriginY(value):Float {
		_displayOriginY = value;
		originY = value / height;

		return value;
	}

	/**
	 * Updates the Display Origin cached values internally stored on this Game Object.
	 * You don't usually call this directly, but it is exposed for edge-cases where you may.
	 */
	public function updateDisplayOrigin():Dynamic {
		_displayOriginX = originX * width;
		_displayOriginY = originY * height;

		return this;
	}

	/**
	 * Sets the origin of this Game Object.
	 *
	 * The values are given in the range 0 to 1.
	 */
	public function setOrigin(?x:Float = 0.5, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		originX = x;
		originY = y;

		return updateDisplayOrigin();
	}

	/**
	 * Sets the origin of this Game Object based on the Pivot values in its Frame.
	 */
	// TODO: customPivot
	public function setOriginFromFrame():Dynamic {
		if (frame == null || !frame.customPivot) {
			return setOrigin();
		} else {
			originX = frame.pivotX;
			originY = frame.pivotY;
		}
		return updateDisplayOrigin();
	}

	/**
	 * Sets the display origin of this Game Object.
	 * The difference between this and setting the origin is that you can use pixel values for setting the display origin.
	 */
	public function setDisplayOrigin(?x:Float = 0, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		displayOriginX = x;
		displayOriginY = y;

		return this;
	}

	/**
	 * The horizontal scroll factor of this Game Object.
	 *
	 * The scroll factor controls the influence of the movement of a Camera upon this Game Object.
	 *
	 * When a camera scrolls it will change the location at which this Game Object is rendered on-screen.
	 * It does not change the Game Objects actual position values.
	 *
	 * A value of 1 means it will move exactly in sync with a camera.
	 * A value of 0 means it will not move at all, even if the camera moves.
	 * Other values control the degree to which the camera movement is mapped to this Game Object.
	 *
	 * Please be aware that scroll factor values other than 1 are not taken in to consideration when
	 * calculating physics collisions. Bodies always collide based on their world position, but changing
	 * the scroll factor is a visual adjustment to where the textures are rendered, which can offset
	 * them from physics bodies if not accounted for in your code.
	 */
	public var scrollFactorX:Float = 1;

	/**
	 * The vertical scroll factor of this Game Object.
	 *
	 * The scroll factor controls the influence of the movement of a Camera upon this Game Object.
	 *
	 * When a camera scrolls it will change the location at which this Game Object is rendered on-screen.
	 * It does not change the Game Objects actual position values.
	 *
	 * A value of 1 means it will move exactly in sync with a camera.
	 * A value of 0 means it will not move at all, even if the camera moves.
	 * Other values control the degree to which the camera movement is mapped to this Game Object.
	 *
	 * Please be aware that scroll factor values other than 1 are not taken in to consideration when
	 * calculating physics collisions. Bodies always collide based on their world position, but changing
	 * the scroll factor is a visual adjustment to where the textures are rendered, which can offset
	 * them from physics bodies if not accounted for in your code.
	 */
	public var scrollFactorY:Float = 1;

	/**
	 * Sets the scroll factor of this Game Object.
	 *
	 * The scroll factor controls the influence of the movement of a Camera upon this Game Object.
	 *
	 * When a camera scrolls it will change the location at which this Game Object is rendered on-screen.
	 * It does not change the Game Objects actual position values.
	 *
	 * A value of 1 means it will move exactly in sync with a camera.
	 * A value of 0 means it will not move at all, even if the camera moves.
	 * Other values control the degree to which the camera movement is mapped to this Game Object.
	 *
	 * Please be aware that scroll factor values other than 1 are not taken in to consideration when
	 * calculating physics collisions. Bodies always collide based on their world position, but changing
	 * the scroll factor is a visual adjustment to where the textures are rendered, which can offset
	 * them from physics bodies if not accounted for in your code.
	 */
	public function setScrollFactor(x:Float, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		scrollFactorX = x;
		scrollFactorY = y;

		return this;
	}

	/**
	 * The native (un-scaled) width of this Game Object.
	 */
	public var width:Float = 0;

	/**
	 * The native (un-scaled) height of this Game Object.
	 *
	 * Changing this value will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or use
	 * the `displayHeight` property.
	 */
	public var height:Float = 0;

	/**
	 * The displayed width of this Game Object.
	 *
	 * This value takes into account the scale factor.
	 *
	 * Setting this value will adjust the Game Object's scale property.
	 */
	public var displayWidth(get, set):Float;

	function get_displayWidth():Float {
		return Math.abs(scaleX * frame.realWidth);
	}

	function set_displayWidth(value:Float):Float {
		scaleX = value / frame.realWidth;

		return Math.abs(scaleX * frame.realWidth);
	}

	/**
	 * The displayed height of this Game Object.
	 *
	 * This value takes into account the scale factor.
	 *
	 * Setting this value will adjust the Game Object's scale property.
	 */
	public var displayHeight(get, set):Float;

	function get_displayHeight():Float {
		return Math.abs(scaleY * frame.realHeight);
	}

	function set_displayHeight(value:Float):Float {
		scaleY = value / frame.realHeight;

		return Math.abs(scaleY * frame.realHeight);
	}

	/**
	 * Sets the size of this Game Object to be that of the given Frame.
	 *
	 * This will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or call the
	 * `setDisplaySize` method, which is the same thing as changing the scale but allows you
	 * to do so by giving pixel values.
	 *
	 * If you have enabled this Game Object for input, changing the size will _not_ change the
	 * size of the hit area. To do this you should adjust the `input.hitArea` object directly.
	 */
	public function setSizeToFrame(?_frame:Frame = null):Dynamic {
		if (_frame == null)
			_frame = frame;

		width = _frame.realWidth;
		height = _frame.realHeight;

		return this;
	}

	/**
	 * Sets the internal size of this Game Object, as used for frame or physics body creation.
	 *
	 * This will not change the size that the Game Object is rendered in-game.
	 * For that you need to either set the scale of the Game Object (`setScale`) or call the
	 * `setDisplaySize` method, which is the same thing as changing the scale but allows you
	 * to do so by giving pixel values.
	 *
	 * If you have enabled this Game Object for input, changing the size will _not_ change the
	 * size of the hit area. To do this you should adjust the `input.hitArea` object directly.
	 */
	public function setSize(w:Float, h:Float):Dynamic {
		width = w;
		height = h;

		return this;
	}

	/**
	 * Sets the display size of this Game Object.
	 *
	 * Calling this will adjust the scale.
	 */
	public function setDisplaySize(width:Float, height:Float):Dynamic {
		displayWidth = width;
		displayHeight = height;

		return this;
	}

	/**
	 * The Texture this Game Object is using to render with.
	 */
	// TODO: CanvasTexture
	public var texture:Texture = null;

	/**
	 * The Texture Frame this Game Object is using to render with.
	 */
	public var frame:Frame = null;

	/**
	 * Sets the texture and frame this Game Object will use to render with.
	 *
	 * Textures are referenced by their string-based keys, as stored in the Texture Manager.
	 */
	public function setTexture(key:String, frame:String):GameObject {
		texture = AssetManager.getTexture(key);
		return setFrame(frame);
	}

	/**
	 * Sets the frame this Game Object will use to render with.
	 *
	 * The Frame has to belong to the current Texture being used.
	 *
	 * It can be either a string or an index.
	 * Calling `setFrame` will modify the `width` and `height` properties of your Game Object.
	 * It will also change the `origin` if the Frame has a custom pivot point, as exported from packages like Texture Packer.
	 */
	public function setFrame(key:String, ?updateSize:Bool = true, ?updateOrigin:Bool = true):GameObject {
		frame = texture.get(key);

		if (updateSize)
			setSizeToFrame();

		if (updateOrigin) {
			if (frame.customPivot) {
				setOrigin(frame.pivotX, frame.pivotY);
			} else {
				updateDisplayOrigin();
			}
		}

		return this;
	}

	/**
	 * The x position of this Game Object.
	 */
	public var x:Float = 0;

	/**
	 * The y position of this Game Object.
	 */
	public var y:Float = 0;

	/**
	 * This is a special setter that allows you to set both the horizontal and vertical scale of this Game Object
	 * to the same value, at the same time. When reading this value the result returned is `(scaleX + scaleY) / 2`.
	 */
	public var scale(get, set):Float;

	function get_scale():Float {
		return (scaleX + scaleY) / 2;
	}

	function set_scale(value:Float):Float {
		scaleX = value;
		scaleY = value;

		return get_scale();
	}

	/**
	 * This is a special setter that allows you to set both the horizontal and vertical scale of this Game Object
	 * to the same value, at the same time. When reading this value the result returned is `(scaleX + scaleY) / 2`.
	 *
	 * Use of this property implies you wish the horizontal and vertical scales to be equal to each other. If this
	 * isn't the case, use the `scaleX` or `scaleY` properties instead.
	 */
	public var scaleX:Float = 1;

	/**
	 * The vertical scale of this Game Object.
	 */
	public var scaleY:Float = 1;

	/**
	 * The angle of this Game Object in radians.
	 *
	 * Nebula uses a right-hand clockwise rotation system, where 0 is right, 90 is down, 180/-180 is left
	 * and -90 is up.
	 */
	public var rotation(default, set):Float;

	function set_rotation(value:Float):Float {
		// value is in degrees
		rotation = Angle.wrap(value);

		return rotation;
	}

	/**
	 * Sets the position of this Game Object.
	 */
	public function setPosition(?_x:Float = 0.0, ?_y:Float = null):Dynamic {
		if (_y == null) {
			_y = _x;
		}

		x = _x;
		y = _y;

		return this;
	}

	/**
	 * Sets the rotation of this Game Object.
	 */
	public function setRotation(?radians:Float = 0.0):Dynamic {
		rotation = radians;

		return this;
	}

	/**
	 * Sets the scale of this Game Object.
	 */
	public function setScale(?x:Float = 1.0, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		scaleX = x;
		scaleY = y;

		return this;
	}

	/**
	 * Sets the x position of this Game Object.
	 */
	public function setX(?value:Float = 0.0):Dynamic {
		x = value;

		return this;
	}

	/**
	 * Sets the y position of this Game Object.
	 */
	public function setY(?value:Float = 0.0):Dynamic {
		y = value;

		return this;
	}

	/**
	 * The visible state of the Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public var visible:Bool = true;

	/**
	 * Sets the visibility of this Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public function setVisible(value:Bool):GameObject {
		visible = value;

		return this;
	}

	// INITIALIZE //
	public function new(_scene:Scene, _type:String) {
		super();

		scene = _scene;
		type = _type;

		// Tell the Scene to re-sort the children.
		scene.queueDepthSort();
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
	public function preUpdate(time:Float, dela:Float) {}

	/**
	 * Compares the renderMask with the renderFlags to see if this Game Object will render or not.
	 * Also checks the Game Object against the given Cameras exclusion list.
	 */
	public function willRender(camera:Camera) {
		// TODO: not sure why we do a reverse reverse, will look into it.
		return !(!visible || alpha == 0 || (cameraFilter != 0 && (cameraFilter & camera.id) == 1));
	}

	/**
	 * This is for GameObjects to override
	 */
	public function render(renderer:Renderer, camera:Camera) {}

	/**
	 * Returns an array containing the display list index of either this Game Object, or if it has one,
	 * its parent Container. It then iterates up through all of the parent containers until it hits the
	 * root of the display list (which is index 0 in the returned array).
	 *
	 * Used internally by the InputPlugin but also useful if you wish to find out the display depth of
	 * this Game Object and all of its ancestors.
	 */
	public function getIndexList() {
		var indexes = [];

		indexes.unshift(scene.displayList.getIndex(this));

		return indexes;
	}

	/**
	 * This method is called before the GameObject is destroyed
	 * 
	 * It is for personal use.
	 */
	public function preDestroy() {};

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
		if (scene == null) {
			return;
		}

		preDestroy();

		emit('DESTROY', this);

		if (!fromScene) {
			scene.displayList.remove([this]);
		}

		// Tell the Scene to re-sort the children
		if (!fromScene) {
			scene.queueDepthSort();
		}

		active = false;

		scene = null;

		removeAllListeners();
	}
}