package nebula.gameobjects;

import nebula.math.MATH_CONST;
import nebula.math.Angle;
import nebula.math.RotateAround;
import nebula.math.Clamp;
import nebula.renderer.BlendModes;
import nebula.input.InteractiveObject;
import nebula.gameobjects.components.TransformMatrix;
import nebula.textures.Texture;
import nebula.textures.Frame;
import nebula.geom.rectangle.Rectangle;
import kha.math.Vector2;
import nebula.cameras.Camera;
import nebula.scene.Scene;

/**
 * The base class that all Game Objects extend.
 * You don't create GameObjects directly and they cannot be added to the display list.
 * Instead, use them as the base for your own custom classes.
 */
class GameObject extends EventEmitter {
	/**
	 * The bitmask that `GameObject.renderFlags` is compared against to determine if the Game Object will render or not.
	 */
	public static var RENDER_MASK:Int = 15;

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

	/**
	 * The parent Container of this Game Object, if it has one.
	 */
	public var parentContainer:Dynamic; // To-Do Container You get a Dirty Dynamic for now.

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
	public var data = null; // To-Do DataManager ???

	/**
	 * The flags that are compared against `RENDER_MASK` to determine if this Game Object will render or not.
	 * The bits are 0001 | 0010 | 0100 | 1000 set by the components Visible, Alpha, Transform and Texture respectively.
	 * If those components are not used by your custom class then you can use this bitmask as you wish.
	 */
	public var renderFlags:Int = 15;

	/**
	 * A bitmask that controls if this Game Object is drawn by a Camera or not.
	 * Not usually set directly, instead call `Camera.ignore`, however you can
	 * set this property directly using the Camera.id property:
	 */
	public var cameraFilter:Int = 0;

	/**
	 * This Game Object will ignore all calls made to its destroy method if this flag is set to `true`.
	 * This includes calls that may come from a Group, Container or the Scene itself.
	 * While it allows you to persist a Game Object across Scenes, please understand you are entirely
	 * responsible for managing references to and from this Game Object.
	 */
  public var ignoreDestroy:Bool = false;

	/**
	 * Private internal value. Holds the global alpha value.
	 */
	public var _alpha:Float = 1;

	/**
	 * Private internal value. Holds the top-left alpha value.
	 */
	public var _alphaTL:Float = 1;

	/**
	 * Private internal value. Holds the top-right alpha value.
	 */
	public var _alphaTR:Float = 1;

	/**
	 * Private internal value. Holds the bottom-left alpha value.
	 */
	public var _alphaBL:Float = 1;

	/**
	 * Private internal value. Holds the bottom-right alpha value.
	 */
	public var _alphaBR:Float = 1;

	/**
	 * Clears all alpha values associated with this Game Object.
	 *
	 * Immediately sets the alpha levels back to 1 (fully opaque).
	 */
	public function clearAlpha():Dynamic {
		return this.setAlpha(1);
	}

	/**
	 * Set the Alpha level of this Game Object. The alpha controls the opacity of the Game Object as it renders.
	 * Alpha values are provided as a float between 0, fully transparent, and 1, fully opaque.
	 *
	 * If your game is running under WebGL you can optionally specify four different alpha values, each of which
	 * correspond to the four corners of the Game Object. Under Canvas only the `topLeft` value given is used.
	 */
	public function setAlpha(topLeft:Float, ?topRight:Float, ?bottomLeft:Float, ?bottomRight:Float):Dynamic {
		//  Treat as if there is only one alpha value for the whole Game Object
		if (topRight == null) {
			this.alpha = topLeft;
		} else {
			this._alphaTL = Clamp.clamp(topLeft, 0, 1);
			this._alphaTR = Clamp.clamp(topRight, 0, 1);
			this._alphaBL = Clamp.clamp(bottomLeft, 0, 1);
			this._alphaBR = Clamp.clamp(bottomRight, 0, 1);
		}
		return this;
	}

	/**
	 * The alpha value of the Game Object.
	 *
	 * This is a global value, impacting the entire Game Object, not just a region of it.
	 */
	public var alpha(get, set):Float;

	function get_alpha():Float {
		return _alpha;
	}

	function set_alpha(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alpha = v;
		this._alphaTL = v;
		this._alphaTR = v;
		this._alphaBL = v;
		this._alphaBR = v;

		if (v == 0) {
			//   this.renderFlags &= ~_FLAG;
		} else {
			//  this.renderFlags |= _FLAG;
		}

		return _alpha;
	}

	/**
	 * The alpha value starting from the top-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaTopLeft(get, set):Float;

	function get_alphaTopLeft():Float {
		return this._alphaTL;
	}

	function set_alphaTopLeft(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaTL = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}

		return v;
	}

	/**
	 * The alpha value starting from the top-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaTopRight(get, set):Float;

	function get_alphaTopRight():Float {
		return this._alphaTR;
	}

	function set_alphaTopRight(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaTR = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}

		return v;
	}

	/**
	 * The alpha value starting from the bottom-left of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaBottomLeft(get, set):Float;

	function get_alphaBottomLeft():Float {
		return this._alphaBL;
	}

	function set_alphaBottomLeft(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaBL = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}
		return get_alphaBottomLeft();
	}

	/**
	 * The alpha value starting from the bottom-right of the Game Object.
	 * This value is interpolated from the corner to the center of the Game Object.
	 */
	public var alphaBottomRight(get, set):Float;

	function get_alphaBottomRight():Float {
		return this._alphaBR;
	}

	function set_alphaBottomRight(value:Float):Float {
		var v = Clamp.clamp(value, 0, 1);

		this._alphaBR = v;

		if (v != 0) {
			// this.renderFlags |= _FLAG;
		}
		return get_alphaBottomRight();
  }
  
	/**
	 * Private internal value. Holds the current blend mode.
	 */
	public var _blendMode:Int = BlendModes.NORMAL;

	/**
	 * Sets the Blend Mode being used by this Game Object.
	 *
	 * This can be a const, such as `Phaser.BlendModes.SCREEN`, or an integer, such as 4 (for Overlay)
	 *
	 * Under WebGL only the following Blend Modes are available:
	 *
	 * * ADD
	 * * MULTIPLY
	 * * SCREEN
	 * * ERASE
	 *
	 * Canvas has more available depending on browser support.
	 *
	 * You can also create your own custom Blend Modes in WebGL.
	 *
	 * Blend modes have different effects under Canvas and WebGL, and from browser to browser, depending
	 * on support. Blend Modes also cause a WebGL batch flush should it encounter a new blend mode. For these
	 * reasons try to be careful about the construction of your Scene and the frequency of which blend modes
	 * are used.
	 */
	public var blendMode(get, set):Int;

	function get_blendMode():Int {
		return this._blendMode;
	}

	function set_blendMode(value:Int):Int {
		if (value >= -1) {
			this._blendMode = value;
		}
		return get_blendMode();
	}

	/**
	 * Sets the Blend Mode being used by this Game Object.
	 *
	 * This can be a const, such as `Phaser.BlendModes.SCREEN`, or an integer, such as 4 (for Overlay)
	 *
	 * Under WebGL only the following Blend Modes are available:
	 *
	 * * ADD
	 * * MULTIPLY
	 * * SCREEN
	 * * ERASE (only works when rendering to a framebuffer, like a Render Texture)
	 *
	 * Canvas has more available depending on browser support.
	 *
	 * You can also create your own custom Blend Modes in WebGL.
	 *
	 * Blend modes have different effects under Canvas and WebGL, and from browser to browser, depending
	 * on support. Blend Modes also cause a WebGL batch flush should it encounter a new blend mode. For these
	 * reasons try to be careful about the construction of your Scene and the frequency in which blend modes
	 * are used.
	 */
	public function setBlendMode(value:Int):GameObject {
		this.blendMode = value;
		return this;
  }
  
	/**
	 * Private internal value. Holds the depth of the Game Object.
	 */
	public var _depth:Int = 0;

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
	public var depth(get, set):Int;

	function get_depth():Int {
		return this._depth;
	}

	function set_depth(value:Int):Int {
		this.scene.sys.queueDepthSort();
		this._depth = value;
		return get_depth();
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
	public function setDepth(value:Int = 0):GameObject {
		this.depth = value;
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
	public function toggleFlipX():GameObject {
		this.flipX = !this.flipX;

		return this;
	}

	/**
	 * Toggles the vertical flipped state of this Game Object.
	 */
	public function toggleFlipY():GameObject {
		this.flipY = !this.flipY;

		return this;
	}

	/**
	 * Sets the horizontal flipped state of this Game Object.
	 *
	 * A Game Object that is flipped horizontally will render inversed on the horizontal axis.
	 * Flipping always takes place from the middle of the texture and does not impact the scale value.
	 * If this Game Object has a physics body, it will not change the body. This is a rendering toggle only.
	 */
	public function setFlipX(value:Bool):GameObject {
		this.flipX = value;

		return this;
	}

	/**
	 * Sets the vertical flipped state of this Game Object.
	 */
	public function setFlipY(value:Bool):GameObject {
		this.flipY = value;

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
		this.flipX = x;
		this.flipY = y;

		return this;
	}

	/**
	 * Resets the horizontal and vertical flipped state of this Game Object back to their default un-flipped state.
	 */
	public function resetFlip():GameObject {
		this.flipX = false;
		this.flipY = false;

		return this;
  }
  
	/**
	 * Processes the bounds output vector before returning it.
	 */
	// To-Do Vector? / object
	public function prepareBoundsOutput(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (this.rotation != 0) {
			RotateAround.rotateAround(output, this.x, this.y, this.rotation);
		}
		if (includeParent && parentContainer != null) {
			var parentMatrix = this.parentContainer.getBoundsTransformMatrix();

			parentMatrix.transformPoint(output.x, output.y, output);
		}
		return output;
	}

	/**
	 * Gets the center coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getCenter(?output:Vector2, ?includeParent:Bool = false):Vector2 {
		if (output == null)
			output = new Vector2();

		output.x = x - (displayWidth * originX) + (displayWidth / 2);
		output.y = y - (displayHeight * originY) + (displayHeight / 2);

		return output;
	}

	/**
	 * Gets the top-left corner coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getTopLeft(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = this.x - (this.displayWidth * this.originX);
		output.y = this.y - (this.displayHeight * this.originY);
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the top-center coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getTopCenter(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = (this.x - (this.displayWidth * this.originX)) + (this.displayWidth / 2);
		output.y = this.y - (this.displayHeight * this.originY);
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the top-right corner coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getTopRight(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = (this.x - (this.displayWidth * this.originX)) + this.displayWidth;
		output.y = this.y - (this.displayHeight * this.originY);
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the left-center coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getLeftCenter(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = this.x - (this.displayWidth * this.originX);
		output.y = (this.y - (this.displayHeight * this.originY)) + (this.displayHeight / 2);
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the right-center coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getRightCenter(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = (this.x - (this.displayWidth * this.originX)) + this.displayWidth;
		output.y = (this.y - (this.displayHeight * this.originY)) + (this.displayHeight / 2);
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the bottom-left corner coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getBottomLeft(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = this.x - (this.displayWidth * this.originX);
		output.y = (this.y - (this.displayHeight * this.originY)) + this.displayHeight;
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the bottom-center coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getBottomCenter(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = (this.x - (this.displayWidth * this.originX)) + (this.displayWidth / 2);
		output.y = (this.y - (this.displayHeight * this.originY)) + this.displayHeight;
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the bottom-right corner coordinate of this Game Object, regardless of origin.
	 * The returned point is calculated in local space and does not factor in any parent containers
	 */
	public function getBottomRight(output:{x:Float, y:Float}, includeParent:Bool = false):{x:Float, y:Float} {
		if (output == null) {
			output = {
				x: 0.0,
				y: 0.0
			};
		}
		output.x = (this.x - (this.displayWidth * this.originX)) + this.displayWidth;
		output.y = (this.y - (this.displayHeight * this.originY)) + this.displayHeight;
		return this.prepareBoundsOutput(output, includeParent);
	}

	/**
	 * Gets the bounds of this Game Object, regardless of origin.
	 * The values are stored and returned in a Rectangle, or Rectangle-like, object.
	 */
	public function getBounds(output:Rectangle):Rectangle {
		if (output == null) {
			output = new Rectangle();
		}

		//  We can use the output object to temporarily store the x/y coords in:

		var TLx, TLy, TRx, TRy, BLx, BLy, BRx, BRy;

		// Instead of doing a check if parent container is
		// defined per corner we only do it once.
		if (this.parentContainer != null) {
			var parentMatrix = this.parentContainer.getBoundsTransformMatrix();

			this.getTopLeft(output);
			parentMatrix.transformPoint(output.x, output.y, output);

			TLx = output.x;
			TLy = output.y;

			this.getTopRight(output);
			parentMatrix.transformPoint(output.x, output.y, output);

			TRx = output.x;
			TRy = output.y;

			this.getBottomLeft(output);
			parentMatrix.transformPoint(output.x, output.y, output);

			BLx = output.x;
			BLy = output.y;

			this.getBottomRight(output);
			parentMatrix.transformPoint(output.x, output.y, output);

			BRx = output.x;
			BRy = output.y;
		} else {
			this.getTopLeft(output);

			TLx = output.x;
			TLy = output.y;

			this.getTopRight(output);

			TRx = output.x;
			TRy = output.y;

			this.getBottomLeft(output);

			BLx = output.x;
			BLy = output.y;

			this.getBottomRight(output);

			BRx = output.x;
			BRy = output.y;
		}

		// output.x = Math.min(TLx, TRx, BLx, BRx);
		// output.y = Math.min(TLy, TRy, BLy, BRy);
		// output.width = Math.max(TLx, TRx, BLx, BRx) - output.x;
		// output.height = Math.max(TLy, TRy, BLy, BRy) - output.y;
		// To-Do Vector3 Math
		return output;
  }
  
	/**
	 * A property indicating that a Game Object has this component.
	 */
	public var _originComponent:Bool = true;

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

	public var _displayOriginX:Float = 0;
	public var _displayOriginY:Float = 0;

	/**
	 * The horizontal display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginX(get, set):Float;

	function get_displayOriginX():Float {
		return this._displayOriginX;
	}

	function set_displayOriginX(value):Float {
		this._displayOriginX = value;
		this.originX = value / this.width;

		return this._displayOriginX;
	}

	/**
	 * The vertical display origin of this Game Object.
	 * The origin is a normalized value between 0 and 1.
	 * The displayOrigin is a pixel value, based on the size of the Game Object combined with the origin.
	 */
	public var displayOriginY(get, set):Float;

	function get_displayOriginY():Float {
		return this._displayOriginY;
	}

	function set_displayOriginY(value):Float {
		this._displayOriginY = value;
		this.originY = value / this.height;

		return this._displayOriginY;
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

		this.originX = x;
		this.originY = y;

		return this.updateDisplayOrigin();
	}

	/**
	 * Sets the origin of this Game Object based on the Pivot values in its Frame.
	 */
	// TODO: customPivot
	public function setOriginFromFrame():Dynamic {
		if (this.frame == null || !this.frame.customPivot) {
			return this.setOrigin();
		} else {
			this.originX = this.frame.pivotX;
			this.originY = this.frame.pivotY;
		}
		return this.updateDisplayOrigin();
	}

	/**
	 * Sets the display origin of this Game Object.
	 * The difference between this and setting the origin is that you can use pixel values for setting the display origin.
	 */
	public function setDisplayOrigin(?x:Float = 0, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		this.displayOriginX = x;
		this.displayOriginY = y;

		return this;
	}

	/**
	 * Updates the Display Origin cached values internally stored on this Game Object.
	 * You don't usually call this directly, but it is exposed for edge-cases where you may.
	 */
	public function updateDisplayOrigin():Dynamic {
		this._displayOriginX = this.originX * this.width;
		this._displayOriginY = this.originY * this.height;

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
	function setScrollFactor(x:Float, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		this.scrollFactorX = x;
		this.scrollFactorY = y;

		return this;
  }
  
	/**
	 * A property indicating that a Game Object has this component.
	 */
	public var _sizeComponent:Bool = true;

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
	// TODO: Impliment Frame
	public function setSizeToFrame(?_frame:Frame = null):Dynamic {
		if (_frame == null)
			_frame = frame;

		this.width = _frame.realWidth;
		this.height = _frame.realHeight;

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
	public function setSize(width:Float, height:Float):Dynamic {
		this.width = width;
		this.height = height;

		return this;
	}

	/**
	 * Sets the display size of this Game Object.
	 *
	 * Calling this will adjust the scale.
	 */
	public function setDisplaySize(width:Float, height:Float):Dynamic {
		this.displayWidth = width;
		this.displayHeight = height;

		return this;
  }
  
	/**
	 * The Texture this Game Object is using to render with.
	 */
	// is CanvasTexture To-Do
	public var texture:Texture = null;

	/**
	 * The Texture Frame this Game Object is using to render with.
	 */
	public var frame:Frame = null;

	/**
	 * A boolean flag indicating if this Game Object is being cropped or not.
	 * You can toggle this at any time after `setCrop` has been called, to turn cropping on or off.
	 * Equally, calling `setCrop` with no arguments will reset the crop and disable it.
	 */
	public var isCropped:Bool = false;

	/**
	 * The internal crop data object, as used by `setCrop` and passed to the `Frame.setCropUVs` method.
	 */ // To-Do Why Isn't this used by a Component?
	public var _crop:{
		u0:Float,
		v0:Float,
		u1:Float,
		v1:Float,
		x:Float,
		y:Float,
		cx:Float,
		cy:Float,
		cw:Float,
		ch:Float,
		width:Float,
		height:Float,
		flipX:Bool,
		flipY:Bool
	};

	/**
	 * Applies a crop to a texture based Game Object, such as a Sprite or Image.
	 *
	 * The crop is a rectangle that limits the area of the texture frame that is visible during rendering.
	 *
	 * Cropping a Game Object does not change its size, dimensions, physics body or hit area, it just
	 * changes what is shown when rendered.
	 *
	 * The crop coordinates are relative to the texture frame, not the Game Object, meaning 0 x 0 is the top-left.
	 *
	 * Therefore, if you had a Game Object that had an 800x600 sized texture, and you wanted to show only the left
	 * half of it, you could call `setCrop(0, 0, 400, 600)`.
	 *
	 * It is also scaled to match the Game Object scale automatically. Therefore a crop rect of 100x50 would crop
	 * an area of 200x100 when applied to a Game Object that had a scale factor of 2.
	 *
	 * You can either pass in numeric values directly, or you can provide a single Rectangle object as the first argument.
	 *
	 * Call this method with no arguments at all to reset the crop, or toggle the property `isCropped` to `false`.
	 *
	 * You should do this if the crop rectangle becomes the same size as the frame itself, as it will allow
	 * the renderer to skip several internal calculations.
	 */
	// TODO: Rectangle Version
	public function setCrop(?x:Float, ?y:Float, ?width:Float, ?height:Float):GameObject {
		if (x == null) {
			this.isCropped = false;
		} else if (this.frame != null) {
			this.frame.setCropUVs(this._crop, x, y, width, height, this.flipX, this.flipY); // this._crop
			this.isCropped = true;
		}
		return this;
	}

	/**
	 * Sets the texture and frame this Game Object will use to render with.
	 *
	 * Textures are referenced by their string-based keys, as stored in the Texture Manager.
	 */
	public function setTexture(key:String, frame:String):GameObject {
		texture = scene.sys.textures.get(key);
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
	// TODO: set up frame functions/variables
	public function setFrame(key:String, ?updateSize:Bool = true, ?updateOrigin:Bool = true):GameObject {
		frame = texture.get(key);

		if (_sizeComponent && updateSize)
			setSizeToFrame();

		if (_originComponent && updateOrigin) {
			if (frame.customPivot) {
				setOrigin(frame.pivotX, frame.pivotY);
			} else {
				updateDisplayOrigin();
			}
		}

		return this;
	}

	/**
	 * Internal method that returns a blank, well-formed crop object for use by a Game Object.
	 */
	private function resetCropObject():{
		u0:Float,
		v0:Float,
		u1:Float,
		v1:Float,
		x:Float,
		y:Float,
		cx:Float,
		cy:Float,
		cw:Float,
		ch:Float,
		width:Float,
		height:Float,
		flipX:Bool,
		flipY:Bool
	} {
		return {
			u0: 0,
			v0: 0,
			u1: 0,
			v1: 0,
			x: 0,
			y: 0,
			cx: 0,
			cy: 0,
			cw: 0,
			ch: 0,
			width: 0,
			height: 0,
			flipX: false,
			flipY: false
		};
  }
  
	/**
	 * Private internal value. Holds the horizontal scale value.
	 */
	public var _scaleX:Float = 1;

	/**
	 * Private internal value. Holds the vertical scale value.
	 */
	public var _scaleY:Float = 1;

	/**
	 * Private internal value. Holds the rotation value in radians.
	 */
	public var _rotation:Float = 0;

	/**
	 * The x position of this Game Object.
	 */
	public var x:Float = 0;

	/**
	 * The y position of this Game Object.
	 */
	public var y:Float = 0;

	/**
	 * The z position of this Game Object.
	 */
	public var z:Float = 0;

	/**
	 * The w position of this Game Object.
	 */
	public var w:Float = 0;

	/**
	 * This is a special setter that allows you to set both the horizontal and vertical scale of this Game Object
	 * to the same value, at the same time. When reading this value the result returned is `(scaleX + scaleY) / 2`.
	 */
	public var scale(get, set):Float;

	function get_scale():Float {
		return (this._scaleX + this._scaleY) / 2;
	}

	function set_scale(value:Float):Float {
		this._scaleX = value;
		this._scaleY = value;
		return get_scale();
	}

	/**
	 * This is a special setter that allows you to set both the horizontal and vertical scale of this Game Object
	 * to the same value, at the same time. When reading this value the result returned is `(scaleX + scaleY) / 2`.
	 *
	 * Use of this property implies you wish the horizontal and vertical scales to be equal to each other. If this
	 * isn't the case, use the `scaleX` or `scaleY` properties instead.
	 */
	public var scaleX(get, set):Float;

	function get_scaleX():Float {
		return this._scaleX;
	}

	function set_scaleX(value:Float):Float {
		this._scaleX = value;
		return get_scaleX();
	}

	/**
	 * The vertical scale of this Game Object.
	 */
	public var scaleY(get, set):Float;

	function get_scaleY():Float {
		return this._scaleY;
	}

	function set_scaleY(value:Float):Float {
		this._scaleY = value;
		return get_scaleY();
	}

	/**
	 * The angle of this Game Object as expressed in degrees.
	 *
	 * Phaser uses a right-hand clockwise rotation system, where 0 is right, 90 is down, 180/-180 is left
	 * and -90 is up.
	 *
	 * If you prefer to work in radians, see the `rotation` property instead.
	 */
	// TODO: WrapAngleDegrees
	public var angle(get, set):Float;

	function get_angle():Float {
		return Angle.wrapDegrees(this._rotation * MATH_CONST.RAD_TO_DEG);
	}

	function set_angle(value:Float):Float {
		//  value is in degrees
		this.rotation = Angle.wrapDegrees(value) * MATH_CONST.DEG_TO_RAD;
		return get_angle();
	}

	/**
	 * The angle of this Game Object in radians.
	 *
	 * Phaser uses a right-hand clockwise rotation system, where 0 is right, 90 is down, 180/-180 is left
	 * and -90 is up.
	 *
	 * If you prefer to work in degrees, see the `angle` property instead.
	 */
	public var rotation(get, set):Float;

	function get_rotation():Float {
		return this._rotation;
	}

	function set_rotation(value:Float):Float {
		//  value is in degrees
		this._rotation = Angle.wrap(value);
		return get_rotation();
	}

	/**
	 * Sets the position of this Game Object.
	 */
	public function setPosition(?x:Float = 0.0, ?y:Float = null, ?z:Float = 0.0, ?w:Float = 0.0):Dynamic {
		if (y == null) {
			y = x;
		}

		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;

		return this;
	}

	/**
	 * Sets the position of this Game Object to be a random position within the confines of
	 * the given area.
	 */
	// TODO:
	public function setRandomPosition(?x:Float = 0.0, ?y:Float = 0.0, ?width:Float = null, ?height:Float = null):Dynamic {
		if (width == null) {
			width = this.scene.sys.scale.gameSize.width;
		}
		if (height == null) {
			height = this.scene.sys.scale.gameSize.height;
		}

		this.x = x + (Math.random() * width);
		this.y = y + (Math.random() * height);

		return this;
	}

	/**
	 * Sets the rotation of this Game Object.
	 */
	public function setRotation(?radians:Float = 0.0):Dynamic {
		this.rotation = radians;
		return this;
	}

	/**
	 * Sets the angle of this Game Object.
	 */
	public function setAngle(?degrees:Float = 0.0):Dynamic {
		this.angle = degrees;
		return this;
	}

	/**
	 * Sets the scale of this Game Object.
	 */
	public function setScale(?x:Float = 1.0, ?y:Float = null):Dynamic {
		if (y == null) {
			y = x;
		}

		this.scaleX = x;
		this.scaleY = y;

		return this;
	}

	/**
	 * Sets the x position of this Game Object.
	 */
	public function setX(?value:Float = 0.0):Dynamic {
		this.x = value;
		return this;
	}

	/**
	 * Sets the y position of this Game Object.
	 */
	public function setY(?value:Float = 0.0):Dynamic {
		this.y = value;
		return this;
	}

	/**
	 * Sets the z position of this Game Object.
	 */
	public function setZ(?value:Float = 0.0):Dynamic {
		this.z = value;
		return this;
	}

	/**
	 * Sets the w position of this Game Object.
	 */
	public function setW(?value:Float = 0.0):Dynamic {
		this.w = value;
		return this;
	}

	/**
	 * Gets the local transform matrix for this Game Object.
	 */
	public function getLocalTransformMatrix(?tempMatrix:TransformMatrix = null):TransformMatrix {
		if (tempMatrix == null) {
			tempMatrix = new TransformMatrix();
		}
		return tempMatrix.applyITRS(this.x, this.y, this._rotation, this._scaleX, this._scaleY);
	}

	/**
	 * Gets the world transform matrix for this Game Object, factoring in any parent Containers.
	 */
	public function getWorldTransformMatrix(?tempMatrix:TransformMatrix = null, ?parentMatrix:TransformMatrix = null):TransformMatrix {
		if (tempMatrix == null) {
			tempMatrix = new TransformMatrix();
		}
		if (parentMatrix == null) {
			parentMatrix = new TransformMatrix();
		}

		// TODO: add parent code

		return this.getLocalTransformMatrix(tempMatrix);

		tempMatrix.applyITRS(this.x, this.y, this._rotation, this._scaleX, this._scaleY);

		/*while (parent) { // To-Do Container Code
			parentMatrix.applyITRS(parent.x, parent.y, parent._rotation, parent._scaleX, parent._scaleY);
			parentMatrix.multiply(tempMatrix, tempMatrix);
			parent = parent.parentContainer;
		}*/

		return tempMatrix;
  }
  
	/**
	 * Private internal value. Holds the visible value.
	 */
	private var _visible:Bool = true;

	/**
	 * The visible state of the Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public var visible(get, set):Bool;

	function get_visible():Bool {
		return this._visible;
	}

	function set_visible(value:Bool):Bool {
		if (value) {
			this._visible = true;
			// this.renderFlags |= _FLAG;
		} else {
			this._visible = false;
			// this.renderFlags &= ~_FLAG;
		}
		return get_visible();
	}

	/**
	 * Sets the visibility of this Game Object.
	 *
	 * An invisible Game Object will skip rendering, but will still process update logic.
	 */
	public function setVisible(value:Bool):GameObject {
		this.visible = value;
		return this;
	}
  
	/**
	 * If this Game Object is enabled for input then this property will contain an InteractiveObject instance.
	 * Not usually set directly. Instead call `GameObject.setInteractive()`.
	 */
	public var input:Null<InteractiveObject>;

	// INITIALIZE //
	public function new(_scene:Scene, type:String) {
		super();
		this.scene = _scene;
		this.type = type;

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

	/**
	 * Adds a Data Manager component to this Game Object.
	 */
	public function setDataEnabled() {
		if (data == null) {
			// this.data = new DataManager(this); To-Do
		}
		return this;
	}

	/**
	 * Allows you to store a key value pair within this Game Objects Data Manager.
	 *
	 * If the Game Object has not been enabled for data (via `setDataEnabled`) then it will be enabled
	 * before setting the value.
	 *
	 * If the key doesn't already exist in the Data Manager then it is created.
	 *
	 * ```javascript
	 * sprite.setData('name', 'Red Gem Stone');
	 * ```
	 *
	 * You can also pass in an object of key value pairs as the first argument:
	 *
	 * ```javascript
	 * sprite.setData({ name: 'Red Gem Stone', level: 2, owner: 'Link', gold: 50 });
	 * ```
	 *
	 * To get a value back again you can call `getData`:
	 *
	 * ```javascript
	 * sprite.getData('gold');
	 * ```
	 *
	 * Or you can access the value directly via the `values` property, where it works like any other variable:
	 *
	 * ```javascript
	 * sprite.data.values.gold += 50;
	 * ```
	 *
	 * When the value is first set, a `setdata` event is emitted from this Game Object.
	 *
	 * If the key already exists, a `changedata` event is emitted instead, along an event named after the key.
	 * For example, if you updated an existing key called `PlayerLives` then it would emit the event `changedata-PlayerLives`.
	 * These events will be emitted regardless if you use this method to set the value, or the direct `values` setter.
	 *
	 * Please note that the data keys are case-sensitive and must be valid JavaScript Object property strings.
	 * This means the keys `gold` and `Gold` are treated as two unique values within the Data Manager.
	 */
	public function setData(key:String, value) { // Key String / Object
		if (data == null) {
			// this.data = new DataManager(this); To-Do
		}

		// this.data.set(key, value);

		return this;
	}

	/**
	 * Increase a value for the given key within this Game Objects Data Manager. If the key doesn't already exist in the Data Manager then it is increased from 0.
	 *
	 * If the Game Object has not been enabled for data (via `setDataEnabled`) then it will be enabled
	 * before setting the value.
	 *
	 * If the key doesn't already exist in the Data Manager then it is created.
	 *
	 * When the value is first set, a `setdata` event is emitted from this Game Object.
	 */
	public function incData(key:String, value) { // Key String / Object
		if (data == null) {
			// this.data = new DataManager(this); To-Do
		}

		// this.data.inc(key, value);

		return this;
	}

	/**
	 * Toggle a boolean value for the given key within this Game Objects Data Manager. If the key doesn't already exist in the Data Manager then it is toggled from false.
	 *
	 * If the Game Object has not been enabled for data (via `setDataEnabled`) then it will be enabled
	 * before setting the value.
	 *
	 * If the key doesn't already exist in the Data Manager then it is created.
	 *
	 * When the value is first set, a `setdata` event is emitted from this Game Object.
	 */
	public function toggleData(key:String) { // Key String/Object
		if (data == null) {
			// this.data = new DataManager(this);To-Do
		}

		// this.data.toggle(key);

		return this;
	}

	/**
	 * Retrieves the value for the given key in this Game Objects Data Manager, or undefined if it doesn't exist.
	 *
	 * You can also access values via the `values` object. For example, if you had a key called `gold` you can do either:
	 *
	 * ```javascript
	 * sprite.getData('gold');
	 * ```
	 *
	 * Or access the value directly:
	 *
	 * ```javascript
	 * sprite.data.values.gold;
	 * ```
	 *
	 * You can also pass in an array of keys, in which case an array of values will be returned:
	 *
	 * ```javascript
	 * sprite.getData([ 'gold', 'armor', 'health' ]);
	 * ```
	 *
	 * This approach is useful for destructuring arrays in ES6.
	 */
	public function getData(key:String) { // Key String/Object
		if (this.data == null) {
			// this.data = new DataManager(this); To-Do
		}

		return null; // this.data.get(key);
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
	 * Returns a JSON representation of the Game Object.
	 */
	public function toJSON() { // To-Do
		return null;
	}

	/**
	 * Compares the renderMask with the renderFlags to see if this Game Object will render or not.
	 * Also checks the Game Object against the given Cameras exclusion list.
	 */
	public function willRender(camera:Camera) {
		return !(GameObject.RENDER_MASK != renderFlags || (cameraFilter != 0 && (cameraFilter & camera.id) == 1));
	}

	public function render(renderer:Renderer, camera:Camera) {} // !!REMOVE THIS!! To-Do

	/**
	 * Returns an array containing the display list index of either this Game Object, or if it has one,
	 * its parent Container. It then iterates up through all of the parent containers until it hits the
	 * root of the display list (which is index 0 in the returned array).
	 *
	 * Used internally by the InputPlugin but also useful if you wish to find out the display depth of
	 * this Game Object and all of its ancestors.
	 *
	 * @method Phaser.GameObjects.GameObject#getIndexList
	 * @since 3.4.0
	 */
	// TODO: add in parentContainer code
	public function getIndexList() {
		var indexes = [];

		indexes.unshift(scene.sys.displayList.getIndex(this));

		return indexes;
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
	public function preDestroy() {};

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

		// TODO: data clear

		// TODO: physics clear

		// Tell the Scene to re-sort the children
		if (!fromScene) {
			scene.sys.queueDepthSort();
		}

		active = false;

		scene = null;

		removeAllListeners();
	}
}