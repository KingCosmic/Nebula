package core.gameobjects.components;

import core.gameobjects.components.TransformMatrix;
import core.math.MATH_CONST;
import core.math.Angle;

/**
 * Provides methods used for getting and setting the position, scale and rotation of a Game Object.
 */
@mixin interface TransformMixin {
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

		var parent = this.parentContainer;

		if (parent == null) {
			return this.getLocalTransformMatrix(tempMatrix);
		}

		tempMatrix.applyITRS(this.x, this.y, this._rotation, this._scaleX, this._scaleY);

		while (parent) { // To-Do Container Code
			/*	parentMatrix.applyITRS(parent.x, parent.y, parent._rotation, parent._scaleX, parent._scaleY);
				parentMatrix.multiply(tempMatrix, tempMatrix);
				parent = parent.parentContainer; */
		}
		return tempMatrix;
	}

	/**
	 * Gets the sum total rotation of all of this Game Objects parent Containers.
	 *
	 * The returned value is in radians and will be zero if this Game Object has no parent container.
	 */
	public function getParentRotation():Float {
		var rotation = 0;
		var parent:Dynamic = this.parentContainer;
		while (parent != null) // todo container code
		{
			rotation += parent.rotation;
			parent = parent.parentContainer;
		}
		return rotation;
	}
}