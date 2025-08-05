package nebula.Collision;

import nebula.Math.Vector;
import nebula.Math.Ray;
import nebula.Color;
import nebula.Collision.Side;
import nebula.Graphics.Context.ExcaliburGraphicsContext;
import nebula.Math.AffineMatrix;
import nebula.Util.Util;

interface BoundingBoxOptions {
  left: Int;
  right: Int;
  top: Int;
  bottom: Int;
}

/**
 * Axis Aligned collision primitive for Excalibur.
 */
class BoundingBox {
  public top: Int;
  public right: Int;
  public bottom: Int;
  public left: Int;

  /**
   * Constructor allows passing of either an object with all coordinate components,
   * or the coordinate components passed separately.
   * @param leftOrOptions    Either x coordinate of the left edge or an options object
   * containing the four coordinate components.
   * @param top     y coordinate of the top edge
   * @param right   x coordinate of the right edge
   * @param bottom  y coordinate of the bottom edge
   */
  public function new(leftOrOptions: Int | BoundingBoxOptions = 0, top: Int = 0, right: Int = 0, bottom: Int = 0) {
    if (typeof leftOrOptions === 'object') {
      this.left = leftOrOptions.left;
      this.top = leftOrOptions.top;
      this.right = leftOrOptions.right;
      this.bottom = leftOrOptions.bottom;
    } else if (typeof leftOrOptions === 'number') {
      this.left = leftOrOptions;
      this.top = top;
      this.right = right;
      this.bottom = bottom;
    }
  }

  /**
   * Returns a new instance of {@apilink BoundingBox} that is a copy of the current instance
   */
  public clone(dest?: BoundingBox): BoundingBox {
    const result = dest || new BoundingBox(0, 0, 0, 0);
    result.left = this.left;
    result.right = this.right;
    result.top = this.top;
    result.bottom = this.bottom;
    return result;
  }

  /**
   * Resets the bounds to a zero width/height box
   */
  public reset() {
    this.left = 0;
    this.top = 0;
    this.bottom = 0;
    this.right = 0;
  }

  /**
   * Given bounding box A & B, returns the side relative to A when intersection is performed.
   * @param intersection Intersection vector between 2 bounding boxes
   */
  public static getSideFromIntersection(intersection: Vector): Side {
    if (!intersection) {
      return Side.None;
    }
    if (intersection) {
      if (Math.abs(intersection.x) > Math.abs(intersection.y)) {
        if (intersection.x < 0) {
          return Side.Right;
        }
        return Side.Left;
      } else {
        if (intersection.y < 0) {
          return Side.Bottom;
        }
        return Side.Top;
      }
    }
    return Side.None;
  }

  public static fromPoints(points: Vector[]): BoundingBox {
    var minX = Infinity;
    var minY = Infinity;
    var maxX = -Infinity;
    var maxY = -Infinity;
    for (var i = 0; i < points.length; i++) {
      if (points[i].x < minX) {
        minX = points[i].x;
      }
      if (points[i].x > maxX) {
        maxX = points[i].x;
      }
      if (points[i].y < minY) {
        minY = points[i].y;
      }
      if (points[i].y > maxY) {
        maxY = points[i].y;
      }
    }
    return new BoundingBox(minX, minY, maxX, maxY);
  }

  /**
   * Creates a bounding box from a width and height
   * @param width
   * @param height
   * @param anchor Default Vector.Half
   * @param pos Default Vector.Zero
   */
  public static fromDimension(width: Int, height: Int, anchor: Vector = Vector.Half, pos: Vector = Vector.Zero) {
    return new BoundingBox(
      -width * anchor.x + pos.x,
      -height * anchor.y + pos.y,
      width - width * anchor.x + pos.x,
      height - height * anchor.y + pos.y
    );
  }

  /**
   * Returns the calculated width of the bounding box
   */
  public get width() {
    return this.right - this.left;
  }

  /**
   * Returns the calculated height of the bounding box
   */
  public get height() {
    return this.bottom - this.top;
  }

  /**
   * Return whether the bounding box has zero dimensions in height,width or both
   */
  public hasZeroDimensions() {
    return this.width === 0 || this.height === 0;
  }

  /**
   * Returns the center of the bounding box
   */
  public get center(): Vector {
    return new Vector((this.left + this.right) / 2, (this.top + this.bottom) / 2);
  }

  public get topLeft(): Vector {
    return new Vector(this.left, this.top);
  }

  public get bottomRight(): Vector {
    return new Vector(this.right, this.bottom);
  }

  public get topRight(): Vector {
    return new Vector(this.right, this.top);
  }

  public get bottomLeft(): Vector {
    return new Vector(this.left, this.bottom);
  }

  public translate(pos: Vector): BoundingBox {
    return new BoundingBox(this.left + pos.x, this.top + pos.y, this.right + pos.x, this.bottom + pos.y);
  }

  /**
   * Rotates a bounding box by and angle and around a point, if no point is specified (0, 0) is used by default. The resulting bounding
   * box is also axis-align. This is useful when a new axis-aligned bounding box is needed for rotated geometry.
   */
  public rotate(angle: Float, point: Vector = Vector.Zero): BoundingBox {
    final points = this.getPoints().map((p) => p.rotate(angle, point));
    return BoundingBox.fromPoints(points);
  }

  /**
   * Scale a bounding box by a scale factor, optionally provide a point
   * @param scale
   * @param point
   */
  public scale(scale: Vector, point: Vector = Vector.Zero): BoundingBox {
    final shifted = this.translate(point);
    return new BoundingBox(shifted.left * scale.x, shifted.top * scale.y, shifted.right * scale.x, shifted.bottom * scale.y);
  }

  /**
   * Transform the axis aligned bounding box by a {@apilink Matrix}, producing a new axis aligned bounding box
   * @param matrix
   */
  public transform(matrix: AffineMatrix) {
    // inlined these calculations to not use vectors would speed it up slightly
    // const matFirstColumn = vec(matrix.data[0], matrix.data[1]);
    // const xa = matFirstColumn.scale(this.left);
    final xa1 = matrix.data[0] * this.left;
    final xa2 = matrix.data[1] * this.left;

    // const xb = matFirstColumn.scale(this.right);
    final xb1 = matrix.data[0] * this.right;
    final xb2 = matrix.data[1] * this.right;

    // const matSecondColumn = vec(matrix.data[2], matrix.data[3]);
    // const ya = matSecondColumn.scale(this.top);
    final ya1 = matrix.data[2] * this.top;
    final ya2 = matrix.data[3] * this.top;

    // const yb = matSecondColumn.scale(this.bottom);
    final yb1 = matrix.data[2] * this.bottom;
    final yb2 = matrix.data[3] * this.bottom;

    final matrixPos = matrix.getPosition();
    // const topLeft = Vector.min(xa, xb).add(Vector.min(ya, yb)).add(matrixPos);
    // const bottomRight = Vector.max(xa, xb).add(Vector.max(ya, yb)).add(matrixPos);
    final left = Math.min(xa1, xb1) + Math.min(ya1, yb1) + matrixPos.x;
    final top = Math.min(xa2, xb2) + Math.min(ya2, yb2) + matrixPos.y;
    final right = Math.max(xa1, xb1) + Math.max(ya1, yb1) + matrixPos.x;
    final bottom = Math.max(xa2, xb2) + Math.max(ya2, yb2) + matrixPos.y;

    return new BoundingBox({
      left, //: topLeft.x,
      top, //: topLeft.y,
      right, //: bottomRight.x,
      bottom //: bottomRight.y
    });
  }

  /**
   * Returns the perimeter of the bounding box
   */
  public getPerimeter(): Int {
    final wx = this.width;
    final wy = this.height;
    return 2 * (wx + wy);
  }

  // Cache bounding box point returns
  private _points: Vector[] = [];
  private _left?: Int;
  private _right?: Int;
  private _top?: Int;
  private _bottom?: Int;

  /**
   * Returns the world space points that make up the corners of the bounding box as a polygon
   */
  public getPoints(): readonly Vector[] {
    if (this._left !== this.left || this._right !== this.right || this._top !== this.top || this._bottom !== this.bottom) {
      this._points.length = 0;
      this._points.push(new Vector(this.left, this.top));
      this._points.push(new Vector(this.right, this.top));
      this._points.push(new Vector(this.right, this.bottom));
      this._points.push(new Vector(this.left, this.bottom));
      this._left = this.left;
      this._right = this.right;
      this._top = this.top;
      this._bottom = this.bottom;
    }
    return this._points;
  }

  /**
   * Determines whether a ray intersects with a bounding box
   */
  public rayCast(ray: Ray, farClipDistance = Infinity): Bool {
    // algorithm from https://tavianator.com/fast-branchless-raybounding-box-intersections/
    // principle visualisation: https://youtu.be/GqwUHXvQ7oA
    var tMinMax: Int, tMaxMin: Int;

    final xInv = ray.dir.x === 0 ? Number.MAX_VALUE : 1 / ray.dir.x;
    final yInv = ray.dir.y === 0 ? Number.MAX_VALUE : 1 / ray.dir.y;

    final tx1 = (this.left - ray.pos.x) * xInv;
    final tx2 = (this.right - ray.pos.x) * xInv;
    tMaxMin = Math.min(tx1, tx2);
    tMinMax = Math.max(tx1, tx2);

    final ty1 = (this.top - ray.pos.y) * yInv;
    final ty2 = (this.bottom - ray.pos.y) * yInv;
    tMaxMin = Math.max(tMaxMin, Math.min(ty1, ty2));
    tMinMax = Math.min(tMinMax, Math.max(ty1, ty2));

    return tMinMax >= 0 && tMinMax >= tMaxMin && tMaxMin < farClipDistance;
  }

  /**
   * Returns the time along the ray where a raycast hits
   */
  public rayCastTime(ray: Ray, farClipDistance = Infinity): Float {
    // algorithm from https://tavianator.com/fast-branchless-raybounding-box-intersections/
    // principle visualisation: https://youtu.be/GqwUHXvQ7oA

    var tMinMax: number, tMaxMin: Float;
    final xInv = ray.dir.x === 0 ? Number.MAX_VALUE : 1 / ray.dir.x;
    final yInv = ray.dir.y === 0 ? Number.MAX_VALUE : 1 / ray.dir.y;

    final tx1 = (this.left - ray.pos.x) * xInv;
    final tx2 = (this.right - ray.pos.x) * xInv;
    tMaxMin = Math.min(tx1, tx2);
    tMinMax = Math.max(tx1, tx2);

    final ty1 = (this.top - ray.pos.y) * yInv;
    final ty2 = (this.bottom - ray.pos.y) * yInv;
    tMaxMin = Math.max(tMaxMin, Math.min(ty1, ty2));
    tMinMax = Math.min(tMinMax, Math.max(ty1, ty2));

    if (tMinMax >= 0 && tMinMax >= tMaxMin && tMaxMin < farClipDistance) {
      return tMaxMin;
    }

    return -1;
  }

  /**
   * Tests whether a point is contained within the bounding box
   * @param p  The point to test
   */
  public contains(p: Vector): Bool;

  /**
   * Tests whether another bounding box is totally contained in this one
   * @param bb  The bounding box to test
   */
  public contains(bb: BoundingBox): Bool;
  public contains(val: any): Bool {
    if (val instanceof Vector) {
      return this.left <= val.x && this.top <= val.y && val.y <= this.bottom && val.x <= this.right;
    } else if (val instanceof BoundingBox) {
      return this.left <= val.left && this.top <= val.top && val.bottom <= this.bottom && val.right <= this.right;
    }
    return false;
  }

  /**
   * Combines this bounding box and another together returning a new bounding box
   * @param other  The bounding box to combine
   */
  public combine(other: BoundingBox, dest?: BoundingBox): BoundingBox {
    final compositeBB = dest || new BoundingBox(0, 0, 0, 0);
    final left = Math.min(this.left, other.left);
    final top = Math.min(this.top, other.top);
    final right = Math.max(this.right, other.right);
    final bottom = Math.max(this.bottom, other.bottom);
    compositeBB.left = left;
    compositeBB.top = top;
    compositeBB.right = right;
    compositeBB.bottom = bottom;
    return compositeBB;
  }

  public get dimensions(): Vector {
    return new Vector(this.width, this.height);
  }

  /**
   * Returns true if the bounding boxes overlap.
   * @param other
   * @param epsilon Optionally specify a small epsilon (default 0) as amount of overlap to ignore as overlap.
   * This epsilon is useful in stable collision simulations.
   */
  public overlaps(other: BoundingBox, epsilon?: Float): Bool {
    final e = epsilon || 0;
    if (other.hasZeroDimensions()) {
      return this.contains(other);
    }
    if (this.hasZeroDimensions()) {
      return other.contains(this);
    }
    final totalBoundingBox = this.combine(other);
    return totalBoundingBox.width + e < other.width + this.width && totalBoundingBox.height + e < other.height + this.height;
  }

  private static _SCRATCH_INTERSECT = [0, 0, 0, 0];
  /**
   * Test wether this bounding box intersects with another returning
   * the intersection vector that can be used to resolve the collision. If there
   * is no intersection null is returned.
   * @param other  Other {@apilink BoundingBox} to test intersection with
   * @returns A Vector in the direction of the current BoundingBox, this <- other
   */
  public intersect(other: BoundingBox): Vector {
    // early exit
    if (this.bottom <= other.top || other.bottom <= this.top || this.right <= other.left || other.right <= this.left) {
      return null;
    }

    // compute the pathes needed to get ahead of the other box in that direction
    // if path <= 0 it means this box is already ahead in that direction
    final topPath = this.bottom - other.top;
    BoundingBox._SCRATCH_INTERSECT[0] = topPath;

    final bottomPath = other.bottom - this.top;
    BoundingBox._SCRATCH_INTERSECT[1] = bottomPath;

    final leftPath = this.right - other.left;
    BoundingBox._SCRATCH_INTERSECT[2] = leftPath;

    final rightPath = other.right - this.left;
    BoundingBox._SCRATCH_INTERSECT[3] = rightPath;

    final minIndex = getMinIndex(BoundingBox._SCRATCH_INTERSECT) as 0 | 1 | 2 | 3;

    switch (minIndex) {
      case 0:
        return new Vector(0, -topPath);
      case 1:
        return new Vector(0, bottomPath);
      case 2:
        return new Vector(-leftPath, 0);
      case 3:
        return new Vector(rightPath, 0);
      default:
        final index: Never = minIndex;
        throw new Error('Unreachable index: [${index}] on bounding box intersection!');
    }
  }

  /**
   * Test whether the bounding box has intersected with another bounding box, returns the side of the current bb that intersected.
   * @param bb The other actor to test
   */
  public intersectWithSide(bb: BoundingBox): Side {
    final intersect = this.intersect(bb);
    return BoundingBox.getSideFromIntersection(intersect);
  }

  /**
   * Draw a debug bounding box
   * @param ex
   * @param color
   */
  public draw(ex: ExcaliburGraphicsContext, color: Color = Color.Yellow) {
    ex.debug.drawRect(this.left, this.top, this.width, this.height, { color });
  }
}
