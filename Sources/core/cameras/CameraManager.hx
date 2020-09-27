package core.cameras;

import core.input.Pointer;
import core.structs.Size;
import core.gameobjects.DisplayList;
import core.scene.Scene;
import core.scene.Systems;

import core.geom.rectangle.RectangleUtils;
/**
 * @classdesc
 * The Camera Manager is a plugin that belongs to a Scene and is responsible for managing all of the Scene Cameras.
 * 
 * By default you can access the Camera Manager from within a Scene using `this.cameras`, although this can be changed
 * in your game config.
 * 
 * Create new Cameras using the `add` method. Or extend the Camera class with your own addition code and then add
 * the new Camera in using the `addExisting` method.
 * 
 * Cameras provide a view into your game world, and can be positioned, rotated, zoomed and scrolled accordingly.
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
 * allowing you to filter Game Objects out on a per-Camera basis. The Camera Manager can manage up to 31 unique 
 * 'Game Object ignore capable' Cameras. Any Cameras beyond 31 that you create will all be given a Camera ID of
 * zero, meaning that they cannot be used for Game Object exclusion. This means if you need your Camera to ignore
 * Game Objects, make sure it's one of the first 31 created.
 *
 * A Camera also has built-in special effects including Fade, Flash, Camera Shake, Pan and Zoom.
 */
class CameraManager {
  // The Scene that owns the Camera Manager plugin.
  public var scene:Scene;

  // A reference to the Scene.Systems handler for the Scene that owns the Camera Manager.
  public var systems:Systems;

  /**
   * All Cameras created by, or added to, this Camera Manager, will have their `roundPixels`
   * property set to match this value. By default it is set to match the value set in the
   * game configuration, but can be changed at any point. Equally, individual cameras can
   * also be changed as needed.
   */
  public var roundPixels:Bool;

  /**
   * An Array of the Camera objects being managed by this Camera Manager.
   * The Cameras are updated and rendered in the same order in which they appear in this array.
   * Do not directly add or remove entries to this array. However, you can move the contents
   * around the array should you wish to adjust the display order.
   */
  public var cameras:Array<Camera> = [];

  /**
   * A handy reference to the 'main' camera. By default this is the first Camera the
   * Camera Manager creates. You can also set it directly, or use the `makeMain` argument
   * in the `add` and `addExisting` methods. It allows you to access it from your game:
   * 
   * ```javascript
   * var cam = this.cameras.main;
   * ```
   * 
   * Also see the properties `camera1`, `camera2` and so on.
   */
  public var main:Camera;

  /**
   * A default un-transformed Camera that doesn't exist on the camera list and doesn't
   * count towards the total number of cameras being managed. It exists for other
   * systems, as well as your own code, should they require a basic un-transformed
   * camera instance from which to calculate a view matrix.
   */
  public var defaultCam:Camera;

  public function new(_scene:Scene) {
    scene = _scene;
		systems = scene.sys;
    
    systems.events.once('BOOT', boot);
    systems.events.on('START', start);
  }

  /**
   * This method is called automatically, only once, when the Scene is first created.
   * Do not invoke it directly.
   */
  public function boot() {
    add();

    main = cameras[0];

    // Create a default camera
    defaultCam = new Camera(0, 0, systems.game.config.width, systems.game.config.height).setScene(scene);

    systems.scale.on('RESIZE', onResize);
    systems.events.once('DESTROY', destroy);
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    if (main == null) {
      
      add();

      main = cameras[0];
    }

    systems.events.on('UPDATE', update);
    systems.events.on('SHUTDOWN', shutdown);
  }

  /**
   * Adds a new Camera into the Camera Manager. The Camera Manager can support up to 31 different Cameras.
   * 
   * Each Camera has its own viewport, which controls the size of the Camera and its position within the canvas.
   * 
   * Use the `Camera.scrollX` and `Camera.scrollY` properties to change where the Camera is looking, or the
   * Camera methods such as `centerOn`. Cameras also have built in special effects, such as fade, flash, shake,
   * pan and zoom.
   * 
   * By default Cameras are transparent and will render anything that they can see based on their `scrollX`
   * and `scrollY` values. Game Objects can be set to be ignored by a Camera by using the `Camera.ignore` method.
   * 
   * The Camera will have its `roundPixels` property set to whatever `CameraManager.roundPixels` is. You can change
   * it after creation if required.
   * 
   * See the Camera class documentation for more details.
   */
  public function add(?x:Int = 0, ?y:Int = 0, ?width:Float, ?height:Float, ?makeMain = false, ?name:String = '') {

    if (width == null) width = scene.scale.baseSize.width;
    if (height == null) height = scene.scale.baseSize.height;

    var camera = new Camera(x, y, width, height);

    camera.setName(name);
    camera.setScene(scene);
    camera.setRoundPixels(roundPixels);

    camera.id = getNextID();

    cameras.push(camera);

    if (makeMain) main = camera;

    return camera;
  }

  /**
   * Adds an existing Camera into the Camera Manager.
   * 
   * The Camera should either be a `Phaser.Cameras.Scene2D.Camera` instance, or a class that extends from it.
   * 
   * The Camera will have its `roundPixels` property set to whatever `CameraManager.roundPixels` is. You can change
   * it after addition if required.
   * 
   * The Camera will be assigned an ID, which is used for Game Object exclusion and then added to the
   * manager. As long as it doesn't already exist in the manager it will be added then returned.
   * 
   * If this method returns `null` then the Camera already exists in this Camera Manager.
   */
  public function addExisting(camera:Camera, ?makeMain:Bool = false) {
    var index = cameras.indexOf(camera);

    if (index != -1) return null;

    camera.id = getNextID();
    camera.setRoundPixels(roundPixels);
    cameras.push(camera);

    if (makeMain) main = camera;

    return camera;
  }

  /**
   * Gets the next available Camera ID number.
   * 
   * The Camera Manager supports up to 31 unique cameras, after which the ID returned will always be zero.
   * You can create additional cameras beyond 31, but they cannot be used for Game Object exclusion.
   */
  public function getNextID() {
    var testID = 1;

    // Find the first free camera ID we can use
    for (t in 0...32) {
      var found = false;

      for (camera in cameras) {
        
        if (camera != null && camera.id == testID) {
          found = true;
          continue;
        }
      }

      if (found) {
        testID = testID << 1;
      } else {
        return testID;
      }
    }

    return 0;
  }

  /**
   * Gets the total number of Cameras in this Camera Manager.
   * 
   * If the optional `isVisible` argument is set it will only count Cameras that are currently visible.
   */
  public function getTotal(?isVisible:Bool = false) {
    var total = 0;

    for (camera in cameras) {
      if (!isVisible || (isVisible && camera.visible)) total++;
    }

    return total;
  }

  /**
   * Populates this Camera Manager based on the given configuration object, or an array of config objects.
   * 
   * See the `Phaser.Types.Cameras.Scene2D.CameraConfig` documentation for details of the object structure.
   *//* TODO: finish this
  public function fromJSON(configs:Array<Any>) {
    var gameWidth = scene.sys.scale.width;
    var gameHeight = scene.sys.scale.height;

    for (config in configs) {

    }
  }*/

  /**
   * Gets a Camera based on its name.
   * 
   * Camera names are optional and don't have to be set, so this method is only of any use if you
   * have given your Cameras unique names.
   */
  public function getCamera(name:String) {
    for (camera in cameras) {
      if (camera.name == name) return camera;
    }

    return null;
  }

  /**
   * Removes the given Camera, or an array of Cameras, from this Camera Manager.
   * 
   * If found in the Camera Manager it will be immediately removed from the local cameras array.
   * If also currently the 'main' camera, 'main' will be reset to be camera 0.
   * 
   * The removed Cameras are automatically destroyed if the `runDestroy` argument is `true`, which is the default.
   * If you wish to re-use the cameras then set this to `false`, but know that they will retain their references
   * and internal data until destroyed or re-added to a Camera Manager.
   */
  public function remove(_cameras:Array<Camera>, ?runDestroy:Bool = false) {
    var total = 0;

    for (camera in _cameras) {
      var index = cameras.indexOf(camera);

      if (index != -1) {
        if (runDestroy) camera.destroy();

        cameras.splice(index, 1);

        total++;
      }
    }

    if (main == null && cameras[0] != null) {
      main = cameras[0];
    }

    return total;
  }

  /**
   * The internal render method. This is called automatically by the Scene and should not be invoked directly.
   * 
   * It will iterate through all local cameras and render them in turn, as long as they're visible and have
   * an alpha level > 0.
   */
  public function render(renderer:Renderer, children:DisplayList) {

    for (camera in cameras) {
      if (camera.visible && camera.alpha > 0) {
        // Hard-coded to 1 for now
        camera.preRender(1);

				renderer.render(scene, children, camera);
      }
    }
  }

  /**
   * Resets this Camera Manager.
   * 
   * This will iterate through all current Cameras, destroying them all, then it will reset the
   * cameras array, reset the ID counter and create 1 new single camera using the default values.
   */
  public function resetAll() {

    for (camera in cameras) {
      camera.destroy();
    }

    cameras = [];

    main = add();

    return main;
  }

  // The main update loop. Called automatically when the Scene steps.
  public function update(time:Float, delta:Float) {
    for (camera in cameras) {
      camera.update(time, delta);
    }
  }

  // The event handler that manages the `resize` event dispatched by the Scale Manager.
	public function onResize(gameSize:Size, baseSize:Size, previousWidth:Float, previousHeight:Float) {
    for (cam in cameras) {
			//  if camera is at 0x0 and was the size of the previous game size, then we can safely assume it
			//  should be updated to match the new game size too
			if (cam._x == 0 && cam._y == 0 && cam._width == previousWidth && cam._height == previousHeight) {
				cam.setSize(baseSize.width, baseSize.height);
			}
    }
  }

	/**
	 * Returns an array of all cameras below the given Pointer.
	 *
	 * The first camera in the array is the top-most camera in the camera list.
   */
  public function getCamerasBelowPointer(pointer:Pointer) {
		var x = pointer.x;
		var y = pointer.y;

		var output = [];

		for (camera in cameras) {
			if (camera.visible && camera.inputEnabled && RectangleUtils.containsPoint(camera.worldView, x, y)) {
				// So the top-most camera is at the top of the search array
				output.unshift(camera);
			}
		}

		return output;
  }

  /**
   * The Scene that owns this plugin is shutting down.
   * We need to kill and reset all internal properties as well as stop listening to Scene events.
   */
  public function shutdown() {

    for (camera in cameras) {
      camera.destroy();
    }

    cameras = [];

    systems.events.removeListener('UPDATE', update);
    systems.events.removeListener('SHUTDOWN', shutdown);
  }

  /**
   * The Scene that owns this plugin is being destroyed.
   * We need to shutdown and then kill off all external references.
   */
  public function destroy() {
    shutdown();

    defaultCam.destroy();

    systems.events.removeListener('START', start);

    scene = null;
    systems = null;
  }

}