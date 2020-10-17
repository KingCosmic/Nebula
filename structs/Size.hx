package core.structs;

import kha.math.Vector2;

/**
 * The Size component allows you to set `width` and `height` properties and define the relationship between them.
 * 
 * The component can automatically maintain the aspect ratios between the two values, and clamp them
 * to a defined min-max range. You can also control the dominant axis. When dimensions are given to the Size component
 * that would cause it to exceed its min-max range, the dimensions are adjusted based on the dominant axis.
 */
class Size {
  // Internal width value.
  public var _width:Float;

  // Internal height value.
  public var _height:Float;

  /**
   * The aspect mode this Size component will use when calculating its dimensions.
   * This property is read-only. To change it use the `setAspectMode` method.
   */
  public var aspectMode:Int;

  /**
   * The proportional relationship between the width and height.
   * 
   * This property is read-only and is updated automatically when either the `width` or `height` properties are changed,
   * depending on the aspect mode.
   */
  public var aspectRatio:Float;

  /**
   * The minimum allowed width.
   * Cannot be less than zero.
   * This value is read-only. To change it see the `setMin` method.
   */
  public var minWidth:Float = 0;

  /**
   * The minimum allowed height.
   * Cannot be less than zero.
   * This value is read-only. To change it see the `setMin` method.
   */
  public var minHeight:Float = 0;

  /**
   * The maximum allowed width.
   * This value is read-only. To change it see the `setMax` method.
   */
	public var maxWidth:Float = 1.79E+308;

  /**
   * The maximum allowed height.
   * This value is read-only. To change it see the `setMax` method.
	 */
	public var maxHeight:Float = 1.79E+308;

  /**
   * A Vector2 containing the horizontal and vertical snap values, which the width and height are snapped to during resizing.
   * 
   * By default this is disabled.
   * 
   * This property is read-only. To change it see the `setSnap` method.
   */
  public var snapTo:Vector2 = new Vector2();

  public function new(?width:Float = 0, ?height:Float, ?_aspectMode:Int = 0, ?parent:Any = null) {
    if (height == null) height = width;

    _width = width;
    _height = height;

    aspectMode = _aspectMode;
    aspectRatio = (height == 0) ? 1 : width / height;
  }

  /**
   * Sets the aspect mode of this Size component.
   * 
   * The aspect mode controls what happens when you modify the `width` or `height` properties, or call `setSize`.
   * 
   * It can be a number from 0 to 4, or a Size constant:
   * 
   * 0. NONE = Do not make the size fit the aspect ratio. Change the ratio when the size changes.
   * 1. WIDTH_CONTROLS_HEIGHT = The height is automatically adjusted based on the width.
   * 2. HEIGHT_CONTROLS_WIDTH = The width is automatically adjusted based on the height.
   * 3. FIT = The width and height are automatically adjusted to fit inside the given target area, while keeping the aspect ratio. Depending on the aspect ratio there may be some space inside the area which is not covered.
   * 4. ENVELOP = The width and height are automatically adjusted to make the size cover the entire target area while keeping the aspect ratio. This may extend further out than the target size.
   * 
   * Calling this method automatically recalculates the `width` and the `height`, if required.
   */
  public function setAspectMode(?value:Int = 0) {
    aspectMode = value;

    return setSize(_width, _height);
  }

  /**
   * By setting a Snap To value when this Size component is modified its dimensions will automatically
   * by snapped to the nearest grid slice, using floor. For example, if you have snap value of 16,
   * and the width changes to 68, then it will snap down to 64 (the closest multiple of 16 when floored)
   * 
   * Note that snapping takes place before adjustments by the parent, or the min / max settings. If these
   * values are not multiples of the given snap values, then this can result in un-snapped dimensions.
   * 
   * Call this method with no arguments to reset the snap values.
   * 
   * Calling this method automatically recalculates the `width` and the `height`, if required.
   */
  public function setSnap(?snapWidth:Float = 0, ?snapHeight:Float) {
    if (snapHeight == null) snapHeight = snapWidth;

    snapTo.x = snapWidth;
    snapTo.y = snapHeight;

    return setSize(_width, _height);
  }

  /**
   * Sets, or clears, the parent of this Size component.
   * 
   * To clear the parent call this method with no arguments.
   * 
   * The parent influences the maximum extents to which this Size component can expand,
   * based on the aspect mode:
   * 
   * NONE - The parent clamps both the width and height.
   * WIDTH_CONTROLS_HEIGHT - The parent clamps just the width.
   * HEIGHT_CONTROLS_WIDTH - The parent clamps just the height.
   * FIT - The parent clamps whichever axis is required to ensure the size fits within it.
   * ENVELOP - The parent is used to ensure the size fully envelops the parent.
   * 
   * Calling this method automatically calls `setSize`.
   */
  public function setParent() {
    return setSize(_width, _height);
  }

  /**
   * Set the minimum width and height values this Size component will allow.
   * 
   * The minimum values can never be below zero, or greater than the maximum values.
   * 
   * Setting this will automatically adjust both the `width` and `height` properties to ensure they are within range.
   * 
   * Note that based on the aspect mode, and if this Size component has a parent set or not, the minimums set here
   * _can_ be exceed in some situations.
   */
  public function setMin(?width:Float = 0, ?height:Float) {
    if (height == null) height = width;

    minWidth = Math.max(0, Math.min(maxWidth, width));
    minHeight = Math.max(0, Math.min(maxHeight, height));

    return setSize(_width, _height);
  }

  /**
   * Set the maximum width and height values this Size component will allow.
   * 
   * Setting this will automatically adjust both the `width` and `height` properties to ensure they are within range.
   * 
   * Note that based on the aspect mode, and if this Size component has a parent set or not, the maximums set here
   * _can_ be exceed in some situations.
   */
  public function setMax(?width:Float, ?height:Float) {
    if (height == null) height = width;

		maxWidth = Math.max(minWidth, Math.min((1.79E+308), width));
		maxHeight = Math.max(minHeight, Math.min((1.79E+308), height));
    
    return setSize(_width, _height);
  }

  /**
   * Sets the width and height of this Size component based on the aspect mode.
   * 
   * If the aspect mode is 'none' then calling this method will change the aspect ratio, otherwise the current
   * aspect ratio is honored across all other modes.
   * 
   * If snapTo values have been set then the given width and height are snapped first, prior to any further
   * adjustment via min/max values, or a parent.
   * 
   * If minimum and/or maximum dimensions have been specified, the values given to this method will be clamped into
   * that range prior to adjustment, but may still exceed them depending on the aspect mode.
   * 
   * If this Size component has a parent set, and the aspect mode is `fit` or `envelop`, then the given sizes will
   * be clamped to the range specified by the parent.
   */
  public function setSize(?width:Float = 0, ?height:Float) {
    if (height == null) height = width;

		switch (aspectMode) {
			case 0:
				_width = getNewWidth(snapFloor(width, snapTo.x));
				_height = getNewHeight(snapFloor(height, snapTo.y));
				aspectRatio = (_height == 0) ? 1 : _width / _height;

			case 1:
				_width = getNewWidth(snapFloor(width, snapTo.x));
				_height = getNewHeight(_width * (1 / aspectRatio), false);

			case 2:
				_height = getNewHeight(snapFloor(height, snapTo.y));
				_width = getNewWidth(_height * aspectRatio, false);

			case 3:
				constrain(width, height, true);

			case 4:
				constrain(width, height, false);
		}

		return this;
  }

  /**
   * Sets a new aspect ratio, overriding what was there previously.
   * 
   * It then calls `setSize` immediately using the current dimensions.
   */
  public function setAspectRatio(ratio:Float) {
    aspectRatio = ratio;

    return setSize(_width, _height);
  }

  /**
   * Sets a new width and height for this Size component and updates the aspect ratio based on them.
   * 
   * It _doesn't_ change the `aspectMode` and still factors in size limits such as the min max and parent bounds.
   */
  public function resize(width:Float, ?height:Float) {
    if (height == null) height = width;

    _width = getNewWidth(snapFloor(width, snapTo.x));
    _height = getNewHeight(snapFloor(height, snapTo.y));
    aspectRatio = (_height == 0) ? 1 : _width / _height;

    return this;
  }

  // Takes a new width and passes it through the min/max clamp and then checks it doesn't exceed the parent width.
  public function getNewWidth(value:Float, ?checkParent:Bool = true) {
    value = Math.max(minWidth, Math.min(maxWidth, value));

    return value;
  }

  // Takes a new height and passes it through the min/max clamp and then checks it doesn't exceed the parent height.
  public function getNewHeight(value:Float, ?checkParent:Bool = true) {
    value = Math.max(minHeight, Math.min(maxHeight, value));

    return value;
  }

  /**
   * The current `width` and `height` are adjusted to fit inside the given dimensions, while keeping the aspect ratio.
   * 
   * If `fit` is true there may be some space inside the target area which is not covered if its aspect ratio differs.
   * If `fit` is false the size may extend further out than the target area if the aspect ratios differ.
   * 
   * If this Size component has a parent set, then the width and height passed to this method will be clamped so
   * it cannot exceed that of the parent.
   */
  public function constrain(?width:Float = 0, ?height:Float, ?fit:Bool = true) {
    if (height == null) height = width;

    width = getNewWidth(width);
    height = getNewHeight(height);

    var newRatio = (height == 0) ? 1 : width / height;

		if ((fit && aspectRatio > newRatio) || (!fit && aspectRatio < newRatio)) {
      // We need to change the height to fit the width

      width = snapFloor(width, snapTo.x);
      height = width / aspectRatio;

      if (snapTo.y > 0) {
        height = snapFloor(height, snapTo.y);

        // Reduce the width accordingly
        width = height * aspectRatio;
      }
		} else if ((fit && aspectRatio < newRatio) || (!fit && aspectRatio > newRatio)) {
      // We need to change the width to fit the height
      height = snapFloor(height, snapTo.y);

      width = height * aspectRatio;

      if (snapTo.x > 0) {
        width = snapFloor(width, snapTo.x);

        // Reduce the height accordingly
        height = width * (1 / aspectRatio);
      }
    }

    _width = width;
    _height = height;

    return this;
  }

  /**
   * The current `width` and `height` are adjusted to fit inside the given dimensions, while keeping the aspect ratio.
   * 
   * There may be some space inside the target area which is not covered if its aspect ratio differs.
   * 
   * If this Size component has a parent set, then the width and height passed to this method will be clamped so
   * it cannot exceed that of the parent.
   */
  public function fitTo(?width:Float = 0, ?height:Float) {
    return constrain(width, height, true);
  }

  /**
   * The current `width` and `height` are adjusted so that they fully envelope the given dimensions, while keeping the aspect ratio.
   * 
   * The size may extend further out than the target area if the aspect ratios differ.
   * 
   * If this Size component has a parent set, then the values are clamped so that it never exceeds the parent
   * on the longest axis.
   */
  public function envelop(?width:Float = 0, ?height:Float) {
    return constrain(width, height, false);
  }

  /**
   * Sets the width of this Size component.
   * 
   * Depending on the aspect mode, changing the width may also update the height and aspect ratio.
   */
  public function setWidth(value:Float) {
    return setSize(value, _height);
  }

  /**
   * Sets the height of this Size component.
   * 
   * Depending on the aspect mode, changing the height may also update the width and aspect ratio.
   */
  public function setHeight(value:Float) {
    return setSize(_width, value);
  }

  // Returns a string representation of this Size component
  public function toString() {
    return '[{ Size (width=' + _width + ' height=' + _height + ' aspectRatio=' + aspectRatio + ' aspectMode=' + aspectMode + ') }]';
  }

  /**
   * Copies the aspect mode, aspect ratio, width and height from this Size component
   * to the given Size component. Note that the parent, if set, is not copied across.
   */
  public function copy(dest:Size) {
    dest.setAspectMode(aspectMode);

    dest.aspectRatio = aspectRatio;

    return dest.setSize(_width, _height);
  }

  public function snapFloor(value:Float, gap:Float, ?start:Float = 0, ?divide:Bool = false) {
    if (gap == 0) return value;

    value -= start;
    value = gap * Math.floor(value / gap);

    return (divide) ? (start + value) / gap : start + value;
  }

  /**
   * Destroys this Size component.
   * 
   * This clears the local properties and any parent object, if set.
   * 
   * A destroyed Size component cannot be re-used.
   */
  public function destroy() {
    snapTo = null;
  }

  /**
   * The width of this Size component.
   * 
   * This value is clamped to the range specified by `minWidth` and `maxWidth`, if enabled.
   * 
   * A width can never be less than zero.
   * 
   * Changing this value will automatically update the `height` if the aspect ratio lock is enabled.
   * You can also use the `setWidth` and `getWidth` methods.
   */
  public var width(get, set):Float;

  function get_width() {
    return _width;
  }

  function set_width(value:Float) {
    setSize(value, _height);
    return _width;
  }

  /**
   * The height of this Size component.
   * 
   * This value is clamped to the range specified by `minHeight` and `maxHeight`, if enabled.
   * 
   * A height can never be less than zero.
   * 
   * Changing this value will automatically update the `width` if the aspect ratio lock is enabled.
   * You can also use the `setHeight` and `getHeight` methods.
   */
  public var height(get, set):Float;

  function get_height() {
    return _height;
  }

  function set_height(value:Float) {
    setSize(_width, value);
    return _height;
  }
}