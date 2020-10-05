package core.cameras;

import core.gameobjects.components.RenderableMixin;
import core.gameobjects.components.ScrollFactor;
import core.gameobjects.components.TransformMatrix;
import core.geom.rectangle.Rectangle;
import core.gameobjects.GameObject;
import core.scale.ScaleManager;
import core.scene.SceneManager;
import core.scene.Scene;
import kha.math.Vector2;
import kha.Color;

/**
 * A Base Camera class.
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
 * The Base Camera is extended by the Camera class, which adds in special effects including Fade,
 * Flash and Camera Shake, as well as the ability to follow Game Objects.
 * 
 * The Base Camera was introduced in Phaser 3.12. It was split off from the Camera class, to allow
 * you to isolate special effects as needed. Therefore the 'since' values for properties of this class relate
 * to when they were added to the Camera class.
 */
class BaseCamera extends EventEmitter {
  // A reference to teh Scene this camera belongs to.
  public var scene:Scene;

  // A reference to the Game Scene Manager.
  public var sceneManager:SceneManager;

  // A reference to the Game Scale Manager.
  public var scaleManager:ScaleManager;

  // A reference to the Scene's Camera Manager to which this Camera belongs.
  public var cameraManager:CameraManager;

  // The Camera ID. Assigned by the Camera Manager and used to handle camera exclusion.
  // This value is a bitmask.
  public var id:Int = 0;

  // The name of the Camera. This is left empty for your own use.
  public var name:String = '';

  // The resolution of the Game, used in most Camera calculations.
  public var _resolution:Float = 1;

  // Should this camera round it's pixel values to integers?
  public var roundPixels:Bool = false;

  /**
   * Is this Camera visible or not?
   *
   * A visible camera will render and perform input tests.
   * An invisible camera will not render anything and will skip input tests.
   */
  public var visible:Bool = true;

  /**
   * Is this Camera using a bounds to restrict scrolling movement?
   *
   * Set this property along with the bounds via `Camera.setBounds`.
   */
  public var useBounds:Bool = false;

  /**
   * The World View is a Rectangle that defines the area of the 'world' the Camera is currently looking at.
   * This factors in the Camera viewport size, zoom and scroll position and is updated in the Camera preRender step.
   * If you have enabled Camera bounds the worldview will be clamped to those bounds accordingly.
   * You can use it for culling or intersection checks.
   */
  public var worldView:Rectangle = new Rectangle();

  /**
   * Is this Camera dirty?
   * 
   * A dirty Camera has had either its viewport size, bounds, scroll, rotation or zoom levels changed since the last frame.
   * 
   * This flag is cleared during the `postRenderCamera` method of the renderer.
   */
  public var dirty:Bool = true;

  /**
   * The x position of the Camera viewport, relative to the top-left of the game canvas.
   * The viewport is the area into which the camera renders.
   * To adjust the position the camera is looking at in the game world, see the `scrollX` value.
   */
  public var _x:Float;

  /**
   * The y position of the Camera, relative to the top-left of the game canvas.
   * The viewport is the area into which the camera renders.
   * To adjust the position the camera is looking at in the game world, see the `scrollY` value.
   */
  public var _y:Float;

  // Internal Camera X value multiplied by the resolution.
  public var _cx:Float = 0;

  // Internal Camera Y value multiplied by the resolution.
  public var _cy:Float = 0;

  // Internal Camera Width value multiplied by the resolution.
  public var _cw:Float = 0;

  // Internal Camera Height value multiplied by the resolution.
  public var _ch:Float = 0;

  /**
   * The width of the Camera viewport, in pixels.
   *
   * The viewport is the area into which the Camera renders. Setting the viewport does
   * not restrict where the Camera can scroll to.
   */
  public var _width:Float;

  /**
   * The height of the Camera viewport, in pixels.
   *
   * The viewport is the area into which the Camera renders. Setting the viewport does
   * not restrict where the Camera can scroll to.
   */
  public var _height:Float;

  // The bounds the camera is restrained to during scrolling.
  public var _bounds:Rectangle = new Rectangle();

  /**
   * The horizontal scroll position of this Camera.
   *
   * Change this value to cause the Camera to scroll around your Scene.
   *
   * Alternatively, setting the Camera to follow a Game Object, via the `startFollow` method,
   * will automatically adjust the Camera scroll values accordingly.
   *
   * You can set the bounds within which the Camera can scroll via the `setBounds` method.
   */
  public var _scrollX:Float = 0;

  /**
   * The vertical scroll position of this Camera.
   *
   * Change this value to cause the Camera to scroll around your Scene.
   *
   * Alternatively, setting the Camera to follow a Game Object, via the `startFollow` method,
   * will automatically adjust the Camera scroll values accordingly.
   *
   * You can set the bounds within which the Camera can scroll via the `setBounds` method.
   */
  public var _scrollY:Float = 0;

  /**
   * The Camera zoom value. Change this value to zoom in, or out of, a Scene.
   *
   * A value of 0.5 would zoom the Camera out, so you can now see twice as much
   * of the Scene as before. A value of 2 would zoom the Camera in, so every pixel
   * now takes up 2 pixels when rendered.
   *
   * Set to 1 to return to the default zoom level.
   *
   * Be careful to never set this value to zero.
   */
  public var _zoom:Float = 1;

  /**
   * The rotation of the Camera in radians.
   *
   * Camera rotation always takes place based on the Camera viewport. By default, rotation happens
   * in the center of the viewport. You can adjust this with the `originX` and `originY` properties.
   *
   * Rotation influences the rendering of _all_ Game Objects visible by this Camera. However, it does not
   * rotate the Camera viewport itself, which always remains an axis-aligned rectangle.
   */
  public var _rotation:Float = 0;

  // A local transform matrix used for internal calculations.
  public var matrix:TransformMatrix = new TransformMatrix();

  // Does this Camera have a transparent background?
  public var transparent:Bool = true;

  // The background color of this Camera. Only used if `transparent` is `false`.
  public var backgroundColor:Color = Color.Black;

  /**
   * The Camera alpha value. Setting this property impacts every single object that this Camera
   * renders. You can either set the property directly, i.e. via a Tween, to fade a Camera in or out,
   * or via the chainable `setAlpha` method instead.
   */
  public var alpha:Float = 1;

  /**
   * Should the camera cull Game Objects before checking them for input hit tests?
   * In some special cases it may be beneficial to disable this.
   */
  public var disableCull:Bool = false;

  // A temporary array of culled objects.
  public var culledObjects:Array<RenderableMixin> = [];

  /**
   * The mid-point of the Camera in 'world' coordinates.
   *
   * Use it to obtain exactly where in the world the center of the camera is currently looking.
   *
   * This value is updated in the preRender method, after the scroll values and follower
   * have been processed.
   */
  public var midPoint:Vector2;

  /**
   * The horizontal origin of rotation for this Camera.
   *
   * By default the camera rotates around the center of the viewport.
   *
   * Changing the origin allows you to adjust the point in the viewport from which rotation happens.
   * A value of 0 would rotate from the top-left of the viewport. A value of 1 from the bottom right.
   *
   * See `setOrigin` to set both origins in a single, chainable call.
   */
  public var originX:Float = 0.5;

  /**
   * The vertical origin of rotation for this Camera.
   *
   * By default the camera rotates around the center of the viewport.
   *
   * Changing the origin allows you to adjust the point in the viewport from which rotation happens.
   * A value of 0 would rotate from the top-left of the viewport. A value of 1 from the bottom right.
   *
   * See `setOrigin` to set both origins in a single, chainable call.
   */
  public var originY:Float = 0.5;

  // Does this Camera have a custom viewport?
  public var _customViewport:Bool = false;

  /**
   * The Mask this Camera is using during render.
   * Set the mask using the `setMask` method. Remove the mask using the `clearMask` method.
   */
  public var mask = {};

  /**
   * The Camera that this Camera uses for translation during masking.
   * 
   * If the mask is fixed in position this will be a reference to
   * the CameraManager.default instance. Otherwise, it'll be a reference
   * to itself.
   */
  public var _maskCamera:BaseCamera;

  public function new(_x:Float = 0, _y:Float = 0, _width:Float = 0, _height:Float = 0) {
    super();

    x = _x;
    y = _y;
    width = _width;
    height = _height;

    midPoint = new Vector2(width / 2, height / 2);
  }

  /**
   * Set the Alpha level of this Camera. The alpha controls the opacity of the Camera as it renders.
   * Alpha values are provided as a float between 0, fully transparent, and 1, fully opaque.
   */
  public function setAlpha(?_alpha:Float = 1) {
    alpha = _alpha;
  }

  /**
   * Sets the rotation origin of this Camera.
   *
   * The values are given in the range 0 to 1 and are only used when calculating Camera rotation.
   *
   * By default the camera rotates around the center of the viewport.
   *
   * Changing the origin allows you to adjust the point in the viewport from which rotation happens.
   * A value of 0 would rotate from the top-left of the viewport. A value of 1 from the bottom right.
   */
  public function setOrigin(?x:Float = 0.5, ?y:Float) {
    if (y == null) y = x;

    originX = x;
    originY = y;

    return this;
  }

  /**
   * Calculates what the Camera.scrollX and scrollY values would need to be in order to move
   * the Camera so it is centered on the given x and y coordinates, without actually moving
   * the Camera there. The results are clamped based on the Camera bounds, if set.
   */
  public function getScroll(x:Float, y:Float, ?out:Vector2) {
    if (out == null) out = new Vector2();

    var xOrigin = width * 0.5;
    var yOrigin = height * 0.5;

    out.x = x - xOrigin;
    out.y = y - yOrigin;

    if (useBounds) {
      out.x = clampX(out.x);
      out.y = clampY(out.y);
    }

    return out;
  }

  /**
   * Moves the Camera horizontally so that it is centered on the given x coordinate, bounds allowing.
   * Calling this does not change the scrollY value.
   */
  public function centerOnX(x:Float) {
    var xOrigin = width * 0.5;

    midPoint.x = x;

    scrollX = x - xOrigin;

    if (useBounds) {
      scrollX = clampX(scrollX);
    }

    return this;
  }

  /**
   * Moves the Camera vertically so that it is centered on the given y coordinate, bounds allowing.
   * Calling this does not change the scrollX value.
   */
  public function centerOnY(Y:Float) {
		var yOrigin = height * 0.5;

		midPoint.y = y;

		scrollY = y - yOrigin;

		if (useBounds) {
			scrollY = clampY(scrollY);
		}

		return this;
  }

  /**
   * Moves the Camera so that it is centered on the given coordinates, bounds allowing.
   */
  public function centerOn(x:Float, y:Float) {
    centerOnX(x);
    centerOnY(y);

    return this;
  }

  // Moved the Camera so that it is looking at the center of the Camera Bounds, if enabled.
  public function centerToBounds() {
    if (useBounds) {
      var xOrigin = width * 0.5;
      var yOrigin = height * 0.5;

      midPoint.x = _bounds.centerX - xOrigin;
      midPoint.y = _bounds.centerY - yOrigin;
    }

    return this;
  }

  // Moves the Camera so that it is re-centered based on its viewport size.
  public function centerToSize() {
    scrollX = width * 0.5;
    scrollY = height * 0.5;

    return this;
  }

  /**
   * Takes an array of Game Objects and returns a new array featuring only those objects
   * visible by this camera.
   */
  public function cull(renderableObjects:Array<RenderableMixin>) {
    if (disableCull) return renderableObjects;

    var cameraMatrix = matrix.matrix;

    var mva = cameraMatrix[0];
    var mvb = cameraMatrix[1];
    var mvc = cameraMatrix[2];
    var mvd = cameraMatrix[3];

    // First Invert Matrix
    var determinant = (mva * mvd) - (mvb * mvc);

    // TODO: make sure this is correct
    if (determinant == 0) return renderableObjects;

    var mve = cameraMatrix[4];
    var mvf = cameraMatrix[5];
    
    var cullTop = y;
    var cullBottom = y + height;
    var cullLeft = x;
    var cullRight = x + width;

    determinant = 1 / determinant;

    culledObjects = [];

    for (object in renderableObjects) {
      /* TODO: make containers
      if (object.parentContainer != null) {
        culledObjects.push(object);
        continue;
      }*/

      var objectW = object.width;
      var objectH = object.height;
      var objectX = (object.x - (scrollX * object.scrollFactorX)) - (objectW * object.originX);
      var objectY = (object.y - (scrollY * object.scrollFactorY)) - (objectH * object.originY);
      var tx = (objectX * mva + objectY * mvc + mve);
      var ty = (objectX * mvb + objectY * mvd + mvf);
      var tw = ((objectX + objectW) * mva + (objectY + objectH) * mvc + mve);
      var th = ((objectX + objectW) * mvb + (objectY + objectH) * mvd + mvf);

			if ((tw > cullLeft && tx < cullRight) && (th > cullTop && ty < cullBottom)) {
        culledObjects.push(object);
      }
    }

    return culledObjects;
  }

  /**
   * Converts the given `x` and `y` coordinates into World space, based on this Cameras transform.
   * You can optionally provide a Vector2, or similar object, to store the results in.
   */
  public function getWorldPoint(x:Float, y:Float, ?out:Vector2) {
    if (out == null) out = new Vector2();

    var cameraMatrix = matrix.matrix;

		var mva = cameraMatrix[0];
		var mvb = cameraMatrix[1];
		var mvc = cameraMatrix[2];
		var mvd = cameraMatrix[3];
		var mve = cameraMatrix[4];
    var mvf = cameraMatrix[5];
    
		//  Invert Matrix
		var determinant = (mva * mvd) - (mvb * mvc);

    // TODO: make sure this is correct
		if (determinant == 0) {
			out.x = x;
			out.y = y;

			return out;
    }
    
		determinant = 1 / determinant;

		var ima = mvd * determinant;
		var imb = -mvb * determinant;
		var imc = -mvc * determinant;
		var imd = mva * determinant;
		var ime = (mvc * mvf - mvd * mve) * determinant;
		var imf = (mvb * mve - mva * mvf) * determinant;

		var c = Math.cos(rotation);
		var s = Math.sin(rotation);

		var res = _resolution;

		var scrollX = scrollX;
		var scrollY = scrollY;

		//  Works for zoom of 1 with any resolution, but resolution > 1 and zoom !== 1 breaks
		var sx = x + ((scrollX * c - scrollY * s) * zoom);
		var sy = y + ((scrollX * s + scrollY * c) * zoom);

		//  Apply transform to point
		out.x = (sx * ima + sy * imc) * res + ime;
		out.y = (sx * imb + sy * imd) * res + imf;

		return out;
  }

  /**
   * Given a Game Object, or an array of Game Objects, it will update all of their camera filter settings
   * so that they are ignored by this Camera. This means they will not be rendered by this Camera.
   */
  public function ignore(entries:Array<GameObject>) {
    
    // TODO: accomodate groups
    for (entry in entries) {
      entry.cameraFilter |= id;
    }

    return this;
  }

  // Internal preRender step.
  public function preRender(res:Float) {
    
    var halfWidth = width * 0.5;
    var halfHeight = height * 0.5;

    var realZoom = zoom * res;
    
    var xOrigin = width * originX;
    var yOrigin = height * originY;

    if (useBounds) {
			// Values are in pixels and not impacted by zooming the Camera.
      scrollX = clampX(scrollX);
      scrollY = clampY(scrollY);
    }

    if (roundPixels) {
      xOrigin = Math.round(xOrigin);
      yOrigin = Math.round(yOrigin);
    }

    var midX = scrollX + halfWidth;
    var midY = scrollY + halfHeight;

		// The center of the camera, in world space, so taking zoom into account
		// Basically the pixel value of what it's looking at in the middle of the cam
    midPoint.x = midX;
    midPoint.y = midY;

    var displayWidth = width / zoom;
    var displayHeight = height / zoom;

    worldView.setTo(
      midX - (displayWidth / 2),
      midY - (displayHeight / 2),
      displayWidth,
      displayHeight
    );

		matrix.applyITRS(x + xOrigin, y + yOrigin, rotation, realZoom, realZoom);
		matrix.translate(-xOrigin, -yOrigin);
  }

  // Calculates a linear (interpolation) value over t.
  public function linear(p0:Float, p1:Float, t:Float) {
		return (p1 - p0) * t + p0;
  }

  /**
   * Takes an x value and checks it's within the range of the Camera bounds, adjusting if required.
   * Do not call this method if you are not using camera bounds.
   */
  public function clampX(x:Float) {
    var dw = displayWidth;

    var bx = _bounds.x + ((dw - width) / 2);
    var bw = Math.max(bx, bx + _bounds.width - dw);

    if (x < bx) {
      x = bx;
    } else if (x > bw) {
      x = bw;
    }

    return x;
  }

  /**
   * Takes a y value and checks it's within the range of the Camera bounds, adjusting if required.
   * Do not call this method if you are not using camera bounds.
   */
	public function clampY(y:Float) {
		var dh = displayHeight;

		var by = _bounds.y + ((dh - height) / 2);
		var bh = Math.max(by, by + _bounds.height - dh);

		if (y < by) {
			y = by;
		} else if (y > bh) {
			y = bh;
		}

		return y;
  }
  
  // If this Camera has previously had movement bounds set on it, this will remove them.
  public function removeBounds() {
    useBounds = false;

    dirty = true;

    _bounds.setEmpty();

    return this;
  }

  /**
   * Set the rotation of this Camera. This causes everything it renders to appear rotated.
   *
   * Rotating a camera does not rotate the viewport itself, it is applied during rendering.
   */
  public function setAngle(?value:Float = 0) {
		rotation = value * (Math.PI / 180);

    return this;
  }

  /**
   * Sets the background color for this Camera.
   *
   * By default a Camera has a transparent background but it can be given a solid color, with any level
   * of transparency, via this method.
   *
   * The color value can be specified using CSS color notation, hex or numbers.
   */
  public function setBackgroundColor(?color:Color = Color.Black) {
    backgroundColor = color;

    transparent = (backgroundColor.A == 0);

    return this;
  }

  /**
   * Set the bounds of the Camera. The bounds are an axis-aligned rectangle.
   * 
   * The Camera bounds controls where the Camera can scroll to, stopping it from scrolling off the
   * edges and into blank space. It does not limit the placement of Game Objects, or where
   * the Camera viewport can be positioned.
   * 
   * Temporarily disable the bounds by changing the boolean `Camera.useBounds`.
   * 
   * Clear the bounds entirely by calling `Camera.removeBounds`.
   * 
   * If you set bounds that are smaller than the viewport it will stop the Camera from being
   * able to scroll. The bounds can be positioned where-ever you wish. By default they are from
   * 0x0 to the canvas width x height. This means that the coordinate 0x0 is the top left of
   * the Camera bounds. However, you can position them anywhere. So if you wanted a game world
   * that was 2048x2048 in size, with 0x0 being the center of it, you can set the bounds x/y
   * to be -1024, -1024, with a width and height of 2048. Depending on your game you may find
   * it easier for 0x0 to be the top-left of the bounds, or you may wish 0x0 to be the middle.
   */
  public function setBounds(x:Float, y:Float, width:Float, height:Float, ?centerOn:Bool = false) {

    _bounds.setTo(x, y, width, height);

    dirty = true;
    useBounds = true;

    if (centerOn) {
      centerToBounds();
    } else {
      scrollX = clampX(scrollX);
      scrollY = clampY(scrollY);
    }

    return this;
  }

  /**
   * Returns a rectangle containing the bounds of the Camera.
   * 
   * If the Camera does not have any bounds the rectangle will be empty.
   * 
   * The rectangle is a copy of the bounds, so is safe to modify.
   */
  public function getBounds(?out:Rectangle) {
    if (out == null) out = new Rectangle();

    out.setTo(_bounds.x, _bounds.y, _bounds.width, _bounds.height);

    return out;
  }

  /**
   * Sets the name of this Camera.
   * This value is for your own use and isn't used internally.
   */
  public function setName(?value:String = '') {
    name = value;

    return this;
  }

  /**
   * Set the position of the Camera viewport within the game.
   *
   * This does not change where the camera is 'looking'. See `setScroll` to control that.
   */
  public function setPosition(_x:Float, ?_y:Float) {
    if (_y == null) _y = _x;

    x = _x;
    y = _y;

    return this;
  }

  /**
   * Set the rotation of this Camera. This causes everything it renders to appear rotated.
   *
   * Rotating a camera does not rotate the viewport itself, it is applied during rendering.
   */
  public function setRotation(?value:Float = 0) {
    rotation = value;

    return this;
  }

  /**
   * Should the Camera round pixel values to whole integers when rendering Game Objects?
   * 
   * In some types of game, especially with pixel art, this is required to prevent sub-pixel aliasing.
   */
  public function setRoundPixels(value:Bool) {
    roundPixels = value;

    return this;
  }

  /**
   * Sets the Scene the Camera is bound to.
   * 
   * Also populates the `resolution` property and updates the internal size values.
   */
  public function setScene(_scene:Scene) {
    if (scene != null && _customViewport) {
      sceneManager.customViewports--;
    }

    scene = _scene;

    sceneManager = scene.sys.game.scene;
    scaleManager = scene.sys.scale;
    cameraManager = scene.sys.cameras;

    var res = scaleManager.resolution;

    _resolution = res;

    _cx = x * res;
    _cy = y * res;
    _cw = width * res;
    _ch = height * res;

    updateSystem();

    return this;
  }

  /**
   * Set the position of where the Camera is looking within the game.
   * You can also modify the properties `Camera.scrollX` and `Camera.scrollY` directly.
   * Use this method, or the scroll properties, to move your camera around the game world.
   *
   * This does not change where the camera viewport is placed. See `setPosition` to control that.
   */
  public function setScroll(_x:Float, ?_y:Float) {
    if (_y == null) _y = _x;

    scrollX = _x;
    scrollY = _y;

    return this;
  }

  /**
   * Set the size of the Camera viewport.
   *
   * By default a Camera is the same size as the game, but can be made smaller via this method,
   * allowing you to create mini-cam style effects by creating and positioning a smaller Camera
   * viewport within your game.
   */
  public function setSize(_width:Float, ?_height:Float) {
    if (_height == null) _height = _width;

    width = _width;
    height = _height;

    return this;
  }

  /**
   * This method sets the position and size of the Camera viewport in a single call.
   *
   * If you're trying to change where the Camera is looking at in your game, then see
   * the method `Camera.setScroll` instead. This method is for changing the viewport
   * itself, not what the camera can see.
   *
   * By default a Camera is the same size as the game, but can be made smaller via this method,
   * allowing you to create mini-cam style effects by creating and positioning a smaller Camera
   * viewport within your game.
   */
  public function setViewport(_x:Float, _y:Float, _width:Float, ?_height:Float) {
    if (_height == null) _height = _width;

    x = _x;
    y = _y;
    width = _width;
    height = _height;

    return this;
  }

  /**
   * Set the zoom value of the Camera.
   *
   * Changing to a smaller value, such as 0.5, will cause the camera to 'zoom out'.
   * Changing to a larger value, such as 2, will cause the camera to 'zoom in'.
   *
   * A value of 1 means 'no zoom' and is the default.
   *
   * Changing the zoom does not impact the Camera viewport in any way, it is only applied during rendering.
   */
  public function setZoom(?value:Float = 1) {
    if (value == 0) {
      value = 0.001;
    }
    
    zoom = value;

    return this;
  }

  /**
   * Sets the mask to be applied to this Camera during rendering.
   *
   * The mask must have been previously created and can be either a GeometryMask or a BitmapMask.
   * 
   * Bitmap Masks only work on WebGL. Geometry Masks work on both WebGL and Canvas.
   *
   * If a mask is already set on this Camera it will be immediately replaced.
   * 
   * Masks have no impact on physics or input detection. They are purely a rendering component
   * that allows you to limit what is visible during the render pass.
   * 
   * Note: You cannot mask a Camera that has `renderToTexture` set.
   */
  public function setMask(_mask:Any, ?fixedPosition:Bool = true):BaseCamera {
    mask = _mask;

    _maskCamera = (fixedPosition) ? cameraManager.defaultCam : this;

    return this;
  }

  // Clears the mask that this Camera was using.
  /*
  public function clearMask(?destroyMask:Bool = false) {
    if (destroyMask && mask != null) {
      mask.desroy();
    }

    mask = null;

    return this;
  }*/

  /**
   * Sets the visibility of this Camera.
   *
   * An invisible Camera will skip rendering and input tests of everything it can see.
   */
  public function setVisible(?value:Bool = true) {
    visible = value;

    return this;
  }

  // Internal method called automatically by the Camera Manager.
  public function update(time:Float, delta:Float) {}

  // Internal method called automatically when the viewport changes.
  public function updateSystem() {
    if (scaleManager == null) return;

		var custom = (x != 0 || y != 0 || scaleManager.game.config.width != width || scaleManager.game.config.height != height);

		if (custom && !_customViewport) {
			//  We need a custom viewport for this Camera
			sceneManager.customViewports++;
		} else if (!custom && _customViewport) {
			//  We're turning off a custom viewport for this Camera
			sceneManager.customViewports--;
		}

		dirty = true;
		_customViewport = custom;
  }

  /**
   * Destroys this Camera instance and its internal properties and references.
   * Once destroyed you cannot use this Camera again, even if re-added to a Camera Manager.
   * 
   * This method is called automatically by `CameraManager.remove` if that methods `runDestroy` argument is `true`, which is the default.
   * 
   * Unless you have a specific reason otherwise, always use `CameraManager.remove` and allow it to handle the camera destruction,
   * rather than calling this method directly.
   */
  public function destroy() {
    emit('DESTROY', this);

    removeAllListeners();

    matrix.destroy();

    culledObjects = [];

    if (_customViewport) {
      // We're turning off a custom viewport for this Camera
      sceneManager.customViewports--;
    }

    _bounds = null;
    scene = null;
    scaleManager = null;
    sceneManager = null;
    cameraManager = null;
  }

  public var x(get, set):Float;
  
  function get_x() {
    return _x;
  }

  function set_x(value:Float) {
    _x = value;
    _cx = value * _resolution;
    updateSystem();
    
    return _x;
  }


	public var y(get, set):Float;

	function get_y() {
		return _y;
	}

	function set_y(value:Float) {
		_y = value;
		_cy = value * _resolution;
		updateSystem();

		return _y;
  }


	public var width(get, set):Float;

	function get_width() {
		return _width;
	}

	function set_width(value:Float) {
		_width = value;
		_cw = value * _resolution;
		updateSystem();

		return _width;
  }
  
	public var height(get, set):Float;

	function get_height() {
		return _height;
	}

	function set_height(value:Float) {
		_height = value;
		_ch = value * _resolution;
		updateSystem();

		return _height;
  }


	public var scrollX(get, set):Float;

	function get_scrollX() {
		return _scrollX;
	}

	function set_scrollX(value:Float) {
		_scrollX = value;
		dirty = true;

		return _scrollX;
  }


	public var scrollY(get, set):Float;

	function get_scrollY() {
		return _scrollY;
	}

	function set_scrollY(value:Float) {
		_scrollY = value;
		dirty = true;

		return _scrollY;
  }


	public var zoom(get, set):Float;

	function get_zoom() {
		return _zoom;
	}

	function set_zoom(value:Float) {
		_zoom = value;
		dirty = true;

		return _zoom;
  }
  

	public var rotation(get, set):Float;

	function get_rotation() {
		return _rotation;
	}

	function set_rotation(value:Float) {
		_rotation = value;
		dirty = true;

		return _rotation;
  }
  

	public var centerX(get, null):Float;

	function get_centerX() {
		return x + (0.5 * width);
  }


	public var centerY(get, null):Float;

	function get_centerY() {
		return y + (0.5 * height);
  }
  

	public var displayWidth(get, null):Float;

	function get_displayWidth() {
		return width / zoom;
  }


	public var displayHeight(get, null):Float;

	function get_displayHeight() {
		return height / zoom;
	}
}