package core.cameras;

import core.gameobjects.components.TransformMixin;
import core.geom.rectangle.Rectangle;
import core.cameras.BaseCamera;
import core.scene.Scene;
import kha.math.Vector2;

/**
 * A Camera.
 *
 * The Camera is the way in which all games are rendered in Phaser. They provide a view into your game world,
 * and can be positioned, rotated, zoomed and scrolled accordingly.
 *
 * A Camera consists of two elements: The viewport and the scroll values.
 *
 * The viewport is the physical position and size of the Camera within your game. Cameras, by default, are
 * created the same size as your game, but their position and size can be set to anything. This means if you
 * wanted to create a camera that was 320x200 in size, positioned in the bottom-right corner of your game,
 * you'd adjust the viewport to do that (using methods like `setViewport` and `setSize`).
 *
 * If you wish to change where the Camera is looking in your game, then you scroll it. You can do this
 * via the properties `scrollX` and `scrollY` or the method `setScroll`. Scrolling has no impact on the
 * viewport, and changing the viewport has no impact on the scrolling.
 *
 * By default a Camera will render all Game Objects it can see. You can change this using the `ignore` method,
 * allowing you to filter Game Objects out on a per-Camera basis.
 *
 * A Camera also has built-in special effects including Fade, Flash and Camera Shake.
 */
class Camera extends BaseCamera {
  // Does this Camera allow the Game Objects it renders to receive input events?
  public var inputEnabled:Bool = true;

  // TODO: add effects


  /**
   * The linear interpolation value to use when following a target.
   *
   * Can also be set via `setLerp` or as part of the `startFollow` call.
   *
   * The default values of 1 means the camera will instantly snap to the target coordinates.
   * A lower value, such as 0.1 means the camera will more slowly track the target, giving
   * a smooth transition. You can set the horizontal and vertical values independently, and also
   * adjust this value in real-time during your game.
   *
   * Be sure to keep the value between 0 and 1. A value of zero will disable tracking on that axis.
   */
  public var lerp:Vector2 = new Vector2(1, 1);

  /**
   * The values stored in this property are subtracted from the Camera targets position, allowing you to
   * offset the camera from the actual target x/y coordinates by this amount.
   * Can also be set via `setFollowOffset` or as part of the `startFollow` call.
   */
  public var followOffset:Vector2 = new Vector2();

  /**
   * The Camera dead zone.
   *
   * The deadzone is only used when the camera is following a target.
   *
   * It defines a rectangular region within which if the target is present, the camera will not scroll.
   * If the target moves outside of this area, the camera will begin scrolling in order to follow it.
   *
   * The `lerp` values that you can set for a follower target also apply when using a deadzone.
   *
   * You can directly set this property to be an instance of a Rectangle. Or, you can use the
   * `setDeadzone` method for a chainable approach.
   *
   * The rectangle you provide can have its dimensions adjusted dynamically, however, please
   * note that its position is updated every frame, as it is constantly re-centered on the cameras mid point.
   *
   * Calling `setDeadzone` with no arguments will reset an active deadzone, as will setting this property
   * to `null`.
   */
  public var deadzone:Rectangle;

  // Internal follow target reference.
  public var _follow:TransformMixin;

  /**
   * Is this Camera rendering directly to the canvas or to a texture?
   *
   * Enable rendering to texture with the method `setRenderToTexture` (just enabling this boolean won't be enough)
   *
   * Once enabled you can toggle it by switching this property.
   *
   * To properly remove a render texture you should call the `clearRenderToTexture()` method.
   */
  public var renderToTexture:Bool = false;

  /**
   * If this Camera is rendering to a texture (via `setRenderToTexture`) then you
   * have the option to control if it should also render to the Game canvas as well.
   * 
   * By default, a Camera will render both to its texture and to the Game canvas.
   * 
   * However, if you set ths property to `false` it will only render to the texture
   * and skip rendering to the Game canvas.
   * 
   * Setting this property if the Camera isn't rendering to a texture has no effect.
   */
  public var renderToGame:Bool = true;



  public function new(_x:Float, _y:Float, _width:Float, _height:Float) {
    super(_x, _y, _width, _height);
  }

  override public function preRender(res:Float) {
    var halfWidth = width * 0.5;
    var halfHeight = height * 0.5;

    var realZoom = zoom * res;

    var xOrigin = width * originX;
    var yOrigin = height * originY;

    var sx = scrollX;
    var sy = scrollY;

    if (_follow != null) {
      var fx = (_follow.x - followOffset.x);
      var fy = (_follow.y - followOffset.y);

      // TODO: deadzone
      if (deadzone != null) {

      } else {
        sx = linear(sx, fx - xOrigin, lerp.x);
        sy = linear(sy, fy - yOrigin, lerp.y);
      }
    }

    if (useBounds) {
      scrollX = clampX(scrollX);
      scrollY = clampY(scrollY);
    }

    if (roundPixels) {
      xOrigin = Math.round(xOrigin);
      yOrigin = Math.round(yOrigin);
    }

    scrollX = sx;
    scrollY = sy;

    var midX = sx + halfWidth;
    var midY = sy + halfHeight;

    midPoint.x = midX;
    midPoint.y = midY;

    var displayWidth = width / realZoom;
    var displayHeight = height / realZoom;

    worldView.setTo(
      midX - (displayWidth / 2),
      midY - (displayHeight / 2),
      displayWidth,
      displayHeight
    );

    matrix.applyITRS(x + xOrigin, y + yOrigin, rotation, realZoom, realZoom);
    matrix.translate(-xOrigin, -yOrigin);

    // shakeEffect.preRender();
  }

  /**
   * Sets the Camera to follow a Game Object.
   *
   * When enabled the Camera will automatically adjust its scroll position to keep the target Game Object
   * in its center.
   *
   * You can set the linear interpolation value used in the follow code.
   * Use low lerp values (such as 0.1) to automatically smooth the camera motion.
   *
   * If you find you're getting a slight "jitter" effect when following an object it's probably to do with sub-pixel
   * rendering of the targets position. This can be rounded by setting the `roundPixels` argument to `true` to
   * force full pixel rounding rendering. Note that this can still be broken if you have specified a non-integer zoom
   * value on the camera. So be sure to keep the camera zoom to integers.
   */
	public function startFollow(target:TransformMixin, ?_roundPixels:Bool = false, ?lerpX:Float = 1, ?lerpY:Float = 1, ?offsetX:Float = 0, ?offsetY:Float = 0) {
    if (lerpY == null) lerpY = lerpX;
    if (offsetY == null) offsetY = offsetX;

    _follow = target;

    roundPixels = _roundPixels;

    lerpX = Math.max(0, Math.min(1, lerpX));
    lerpY = Math.max(0, Math.min(1, lerpY));
    
    lerp.x = lerpX;
    lerp.y = lerpY;

    followOffset.x = offsetX;
    followOffset.y = offsetY;

    var centerX = width / 2;
    var centerY = height / 2;

    var fx = target.x - offsetX;
    var fy = target.y - offsetY;

    midPoint.x = fx;
    midPoint.y = fy;

    scrollX = fx - centerX;
    scrollY = fy - centerY;

    if (useBounds) {
      scrollX = clampX(scrollX);
      scrollY = clampX(scrollY);
    }

    return this;
  }

  // Stops a Camera from following a Game Object, if previously set via `Camera.startFollow`.
  public function stopFollow() {
    _follow = null;

    return this;
  }

  override public function setScene(_scene:Scene) {
    super.setScene(_scene);

    return this;
  }

  override public function update(time:Float, delta:Float) {}

  override public function destroy() {
    super.destroy();

    _follow = null;
    deadzone = null;
  }
}