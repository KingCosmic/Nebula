package core.gameobjects.components;

import core.geom.rectangle.Rectangle;
import core.math.RotateAround;
import kha.math.Vector2;

/**
 * Provides methods used for obtaining the bounds of a Game Object.
 * Should be applied as a mixin and not used directly.
 */
@mixin interface GetBounds {
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
    if (output == null) output = new Vector2();

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
}