package core.input;

import core.gameobjects.RenderableGameObject;
import core.input.keyboard.KeyboardPlugin;
import core.geom.rectangle.Rectangle;
import core.scene.Settings;
import core.math.Distance;
import core.gameobjects.GameObject;
import core.cameras.CameraManager;
import core.gameobjects.DisplayList;
import core.scene.Systems;
import core.scene.Scene;

import core.geom.rectangle.RectangleUtils;

import core.input.InteractiveObject;

/**
 * The Input Plugin belongs to a Scene and handles all input related events and operations for it.
 *
 * You can access it from within a Scene using `this.input`.
 *
 * It emits events directly. For example, you can do:
 *
 * ```javascript
 * this.input.on('pointerdown', callback, context);
 * ```
 *
 * To listen for a pointer down event anywhere on the game canvas.
 *
 * Game Objects can be enabled for input by calling their `setInteractive` method. After which they
 * will directly emit input events:
 *
 * ```haxe
 * var sprite = this.add.sprite(x, y, texture);
 * sprite.setInteractive();
 * sprite.on('pointerdown', callback, context);
 * ```
 *
 * There are lots of game configuration options available relating to input.
 * See the [Input Config object]{@linkcode Phaser.Types.Core.InputConfig} for more details, including how to deal with Phaser
 * listening for input events outside of the canvas, how to set a default number of pointers, input
 * capture settings and more.
 *
 * Please also see the Input examples and tutorials for further information.
 *
 * **Incorrect input coordinates with Angular**
 *
 * If you are using Phaser within Angular, and use nglf or the router, to make the component in which the Phaser game resides
 * change state (i.e. appear or disappear) then you'll need to notify the Scale Manager about this, as Angular will mess with
 * the DOM in a way in which Phaser can't detect directly. Call `this.scale.updateBounds()` as part of your game init in order
 * to refresh the canvas DOM bounds values, which Phaser uses for input point position calculations.
 */
class InputPlugin extends EventEmitter {
  // A reference to the Scene that this Input Plugin is responsible for.
  public var scene:Scene;

  // A reference to the Scene Systems class.
  public var systems:Systems;

  // A reference to the Scene Systems Settings.
  public var settings:Settings;

  // A reference to the Game Input Manager.
  public var manager:InputManager;

  // Internal event queue used for plugins only.
  public var pluginEvents = new EventEmitter();

  // If `true` this Input Plugin will process Input Events.
  public var enabled = true;

  // A reference to the Scene Display List. This property is set during the `boot` method.
  public var displayList:DisplayList;

  // A reference to the Scene Cameras Manager. This property is set during the `boot` method.
  public var cameras:CameraManager;

  /**
   * A reference to the Keyboard Plugin.
   */
  public var keyboard:KeyboardPlugin;

  /**
   * A reference to the Mouse Manager.
   *
   * This property is only set if Mouse support has been enabled in your Game Configuration file.
   *
   * If you just wish to get access to the mouse pointer, use the `mousePointer` property instead.
   */
  public var mouse:MouseManager;

  /**
   * When set to `true` (the default) the Input Plugin will emulate DOM behavior by only emitting events from
   * the top-most Game Objects in the Display List.
   *
   * If set to `false` it will emit events from all Game Objects below a Pointer, not just the top one.
   */
  public var topOnly = true;

  /**
   * How often should the Pointers be checked?
   *
   * The value is a time, given in ms, and is the time that must have elapsed between game steps before
   * the Pointers will be polled again. When a pointer is polled it runs a hit test to see which Game
   * Objects are currently below it, or being interacted with it.
   *
   * Pointers will *always* be checked if they have been moved by the user, or press or released.
   *
   * This property only controls how often they will be polled if they have not been updated.
   * You should set this if you want to have Game Objects constantly check against the pointers, even
   * if the pointer didn't itself move.
   *
   * Set to 0 to poll constantly. Set to -1 to only poll on user movement.
   */
  public var pollRate:Int = -1;

  // Internal poll timer value.
  public var _pollTimer:Float = 0;

  // The distance, in pixels, a pointer has to move while being held down, before it thinks it is being dragged.
  public var dragDistanceThreshold:Float = 0;

  /**
   * The amount of time, in ms, a pointer has to be held down before it thinks it is dragging.
   *
   * The default polling rate is to poll only on move so once the time threshold is reached the
   * drag event will not start until you move the mouse. If you want it to start immediately
   * when the time threshold is reached, you must increase the polling rate by calling
   * [setPollAlways]{@linkcode Phaser.Input.InputPlugin#setPollAlways} or
   * [setPollRate]{@linkcode Phaser.Input.InputPlugin#setPollRate}.
   */
  public var dragTimeThreshold:Float = 0;

  // Used to temporarily store the results of the Hit Test
	public var _temp:Array<RenderableGameObject> = [];

  // Used to temporarily store the results of the Hit Test dropZones
  public var _tempZones = [];

  // A list of all Game Objects that have been set to be interactive in the Scene this Input Plugin is managing.
	public var _list:Array<RenderableGameObject> = [];

  // Objects waiting to be inserted to the list on the next call to 'begin'.
	public var _pendingInsertion:Array<RenderableGameObject> = [];

  // Objects waiting to be removed from the list on the next call to 'begin'.
	public var _pendingRemoval:Array<RenderableGameObject> = [];

  // A list of all Game Objects that have been enabled for dragging.
	public var _draggable:Array<RenderableGameObject> = [];

  //  A list of all Interactive Objects currently considered as being 'draggable' by any pointer, indexed by pointer ID.
	public var _drag:Map<String, Array<RenderableGameObject>> = [
    '0' => [],
    '1' => [],
    '2' => [],
    '3' => [],
    '4' => [],
    '5' => [],
    '6' => [],
    '7' => [],
    '8' => [],
    '9' => [],
    '10' => []
  ];

  // A array containing the dragStates, for this Scene, index by the Pointer ID.
  public var _dragState:Array<Int> = [];

  // A list of all Interactive Objects currently considered as being 'over' by any pointer, indexed by pointer ID.
	public var _over:Map<String, Array<RenderableGameObject>> = [
    '0' => [],
    '1' => [],
    '2' => [],
    '3' => [],
    '4' => [],
    '5' => [],
    '6' => [],
    '7' => [],
    '8' => [],
    '9' => [],
    '10' => []
  ];
  
  // A list of valid DOM event types.
	public var _validTypes = [
		'onDown', 'onUp', 'onOver', 'onOut', 'onMove', 'onDragStart', 'onDrag', 'onDragEnd', 'onDragEnter', 'onDragLeave', 'onDragOver', 'onDrop'
  ];
  
  // Internal property that tracks the frame event state.
  public var _updatedThisFrame = false;

  public function new(_scene) {
    super();

    scene = _scene;
    systems = scene.sys;
    settings = scene.sys.settings;
    manager = scene.sys.game.input;
    mouse = manager.mouse;

    systems.events.once('BOOT', boot);
    systems.events.on('START', start);
  }

  /**
   * This method is called automatically, only once, when the Scene is first created.
   * Do not invoke it directly.
   */
  public function boot() {
    cameras = systems.cameras;
    displayList = systems.displayList;

    keyboard = new KeyboardPlugin(this);

    systems.events.once('DESTROY', destroy);

    // Registered input plugins listen for this.
    pluginEvents.emit('BOOT');
  }

  /**
   * This method is called automatically by the Scene when it is starting up.
   * It is responsible for creating local systems, properties and listening for Scene events.
   * Do not invoke it directly.
   */
  public function start() {
    /*systems.events.on('TRANSITION_START', transitionIn);
    systems.events.on('TRANSITION_OUT', transitionOut);
    systems.events.on('TRANSITION_COMPLETE', transitionComplete);*/
    systems.events.on('PRE_UPDATE', preUpdate);
    systems.events.on('SHUTDOWN', shutdown);
    
    manager.events.on('GAME_OUT', onGameOut);
    manager.events.on('GAME_OVER', onGameOver);

    enabled = true;

		// Populate the pointer drag states
		_dragState = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		// Registered input plugins listen for this
		pluginEvents.emit('START');
  }

  // Game Over handler.
  public function onGameOver(event) {
    if (isActive()) {
      emit('GAME_OVER', event.timeStamp, event);
    }
  }

  // Game Over handler.
  public function onGameOut(event) {
    if (isActive()) {
      emit('GAME_OUT', event.timeStamp, event);
    }
  }

  /**
   * The pre-update handler is responsible for checking the pending removal and insertion lists and
   * deleting old Game Objects.
   */
  public function preUpdate() {
    // Registered input plugins listen for this
    pluginEvents.emit('PRE_UPDATE');

    if (_pendingRemoval.length == 0 && _pendingInsertion.length == 0) {
      // Quick bail
      return;
    }

    // Delete old GameObjects
    for (i in 0..._pendingRemoval.length) {
      var go = _pendingRemoval[i];

      var index = _list.indexOf(go);

      if (index > -1) {
        _list.splice(index, 1);

        clear(go, true);
      }
    }

    // Clear the removal list.
    _pendingRemoval = [];

    // Move pendingInsertion to list (also clears pendingInsertion at the same time)
    _list = _list.concat(_pendingInsertion.splice(0, _pendingInsertion.length));
  }

  /**
   * Checks to see if both this plugin and the Scene to which it belongs is active.
   */
  public function isActive() {
    return (enabled && systems.isActive());
  }

  /**
   * This is called automatically by the Input Manager.
   * It emits events for plugins to listen to and also handles polling updates, if enabled.
   */
  public function updatePoll(time:Float, delta:Float) {
    if (!isActive()) return false;

		// The plugins should update every frame, regardless if there has been
		// any DOM input events or not (such as the Gamepad and Keyboard)
    pluginEvents.emit('UPDATE', time, delta);
    
		// We can leave now if we've already updated once this frame via the immediate DOM event handlers
    if (_updatedThisFrame) {
      _updatedThisFrame = false;
      return false;
    }

    for (pointer in manager.pointers) {
      pointer.updateMotion();
    }

    // No point going any further if there aren't any interactive objects
    if (_list.length == 0) return false;

    if (pollRate == -1) return false;

    if (pollRate > 0) {
      _pollTimer -= delta;

      if (_pollTimer < 0) {
				// Discard timer diff, we're ready to poll again
				_pollTimer = pollRate;
      } else {
				// Not enough time has elapsed since the last poll, so abort now
				return false;
      }
    }

    // We got this far? Then we should poll for movement
    var captured = false;

    for (i in 0...manager.pointersTotal) {
      var total = 0;

      var pointer = manager.pointers[i];

      // Always reset this array
      _tempZones = [];

      // _temp contains a hit tested and camera culled list of IO objects
      _temp = hitTestPointer(pointer);

      sortGameObjects(_temp);
      sortGameObjects(_tempZones);

			if (topOnly) {
				// Only the top-most one counts now, so safely ignore the rest
				if (_temp.length > 0) {
					_temp.splice(1, _temp.length);
				}

				if (_tempZones.length > 0) {
					_tempZones.splice(1, _tempZones.length);
				}
			}

			total += processOverOutEvents(pointer);

			if (getDragState(pointer) == 2) {
				processDragThresholdEvent(pointer, time);
			}

			if (total > 0) {
				// We interacted with an event in this Scene, so block any Scenes below us from doing the same this frame
				captured = true;
			}
    }

    return captured;
  }

  /**
   * This method is called when a DOM Event is received by the Input Manager. It handles dispatching the events
   * to relevant input enabled Game Objects in this scene.
   */
  public function update(type:Int, pointers:Array<Pointer>) {
    if (!isActive()) return false;

    var captured = false;

    for (i in 0...pointers.length) {
      
      var total = 0;
      var pointer = pointers[i];

			// Always reset this array
			_tempZones = [];

			// _temp contains a hit tested and camera culled list of IO objects
			_temp = hitTestPointer(pointer);

			sortGameObjects(_temp);
			sortGameObjects(_tempZones);

			if (topOnly) {
				// Only the top-most one counts now, so safely ignore the rest
				if (_temp.length > 0) {
					_temp.splice(1, _temp.length);
				}

				if (_tempZones.length > 0) {
					_tempZones.splice(1, _tempZones.length);
				}
      }
      
      switch (type) {
        case INPUT_CONST.MOUSE_DOWN:
          total += processDragDownEvent(pointer);
          total += processDownEvents(pointer);
          total += processOverOutEvents(pointer);
        
        case INPUT_CONST.MOUSE_UP:
          total += processDragUpEvent(pointer);
          total += processUpEvents(pointer);
          total += processOverOutEvents(pointer);

        case INPUT_CONST.MOUSE_MOVE:
          total += processDragMoveEvent(pointer);
          total += processMoveEvents(pointer);
          total += processOverOutEvents(pointer);

        case INPUT_CONST.MOUSE_WHEEL:
          total += processWheelEvent(pointer);
      }

      if (total > 0) {
        // We interacted with an event in this Scene, so block any Scenes below us from doing the same this frame
        captured = true;
      }
    }

    _updatedThisFrame = true;

    return captured;
  }

  /**
   * Clears a Game Object so it no longer has an Interactive Object associated with it.
   * The Game Object is then queued for removal from the Input Plugin on the next update.
   */
	public function clear(go:RenderableGameObject, ?skipQueue:Bool = false) {

    // If GameObject.input already cleared from higher class
    if (go.input != null) return;

    if (!skipQueue) queueForRemoval(go);

    go.input.gameObject = null;
    go.input.target = null;
    go.input.hitArea = null;
    go.input.hitAreaCallback = null;

    go.input = null;

    // Clear from _draggable, _drag and _over
    var index = _draggable.indexOf(go);

    if (index > -1)
      _draggable.splice(index, 1);

    index = _drag.get('0').indexOf(go);

    if (index > -1)
      _drag.get('0').splice(index, 1);

    index = _over.get('0').indexOf(go);

    if (index > -1) {
      _over.get('0').splice(index, 1);
    }
  }

  /**
   * Disables Input on a single Game Object.
   *
   * An input disabled Game Object still retains its Interactive Object component and can be re-enabled
   * at any time, by passing it to `InputPlugin.enable`.
   */
	public function disable(go:RenderableGameObject) {
    go.input.enabled = false;
  }

  /**
   * Enable a Game Object for interaction.
   *
   * If the Game Object already has an Interactive Object component, it is enabled and returned.
   *
   * Otherwise, a new Interactive Object component is created and assigned to the Game Object's `input` property.
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
	public function enable(go:RenderableGameObject, hitArea:Any, hitAreaCallback:Any, ?dropZone:Bool = false) {
    if (go.input != null) {
      // If it already has an InteractiveObject then just enable it and return
      go.input.enabled = true;
    } else {
      // Create an InteractiveObject and enabled it
      setHitArea([go]/*, hitArea, hitAreaCallback*/);
    }

    if (go.input != null && dropZone != null && go.input.dropZone == null) {
      go.input.dropZone = dropZone;
    }

    return this;
  }

  /**
   * Takes the given Pointer and performs a hit test against it, to see which interactive Game Objects
   * it is currently above.
   *
   * The hit test is performed against which-ever Camera the Pointer is over. If it is over multiple
   * cameras, it starts checking the camera at the top of the camera list, and if nothing is found, iterates down the list.
   */
  public function hitTestPointer(pointer:Pointer) {
    var _cameras = cameras.getCamerasBelowPointer(pointer);

    for (camera in _cameras) {
			// Get a list of all objects that can be seen by the camera below the pointer in the scene and store in 'over' array.
			// All objects in this array are input enabled, as checked by the hitTest method, so we don't need to check later on as well.
      var over = manager.hitTest(pointer, _list, camera);

      // Filter out the drop zones
      for (obj in over) {

        if (obj.input.dropZone != null) {
          _tempZones.push(obj);
        }
      }

      if (over.length > 0) {
        pointer.camera = camera;

        return over;
      }
    }

		// If we got this far then there were no Game Objects below the pointer, but it was still over
    // a camera, so set that the top-most one into the pointer
    
    pointer.camera = cameras.cameras[0];

    return [];
  }

  // An internal method that handles the Pointer down event.
  public function processDownEvents(pointer:Pointer) {
    var total = 0;
    
    // _eventData.cancelled = false;

    var aborted = false;

		// Go through all objects the pointer was over and fire their events / callbacks
    for (go in _temp) {

      if (go.input == null) continue;

      total++;

      go.emit('GAMEOBJECT_POINTER_DOWN', pointer, go.input.localX, go.input.localY/*, _eventContainer*/);
      
      if (/*_eventData.cancelled | */go.input == null) {
        aborted = true;
        break;
      }

      emit('GAMEOBJECT_DOWN', pointer, go/*, _eventContainer*/);

      if (/*_eventData.cancelled || */go.input == null) {
        aborted = true;
        break;
      }
    }

    // If they released outside the canvas, but pressed down inside it, we'll still dispatch the event.
    if (!aborted && manager != null) {
      // TODO: find out if the pointer was inside the window.
      emit('POINTER_DOWN', pointer, _temp);

      // emit('POINTER_DOWN_OUTSIDE', pointer);
    }

    return total;
  }

  /**
   * Returns the drag state of the given Pointer for this Input Plugin.
   *
   * The state will be one of the following:
   *
   * 0 = Not dragging anything
   * 1 = Primary button down and objects below, so collect a draglist
   * 2 = Pointer being checked if meets drag criteria
   * 3 = Pointer meets criteria, notify the draglist
   * 4 = Pointer actively dragging the draglist and has moved
   * 5 = Pointer actively dragging but has been released, notify draglist
   */
  public function getDragState(pointer:Pointer) {
    return _dragState[pointer.id];
  }

  /**
   * Sets the drag state of the given Pointer for this Input Plugin.
   *
   * The state must be one of the following values:
   *
   * 0 = Not dragging anything
   * 1 = Primary button down and objects below, so collect a draglist
   * 2 = Pointer being checked if meets drag criteria
   * 3 = Pointer meets criteria, notify the draglist
   * 4 = Pointer actively dragging the draglist and has moved
   * 5 = Pointer actively dragging but has been released, notify draglist
   */
  public function setDragState(pointer:Pointer, state:Int) {
    _dragState[pointer.id] = state;
  }

  /**
   * Checks to see if a Pointer is ready to drag the objects below it, based on either a distance
   * or time threshold.
   */
  public function processDragThresholdEvent(pointer:Pointer, time:Float) {
    var passed = false;

		if (dragDistanceThreshold > 0 && Distance.distanceBetween(pointer.x, pointer.y, pointer.downX, pointer.downY) >= dragDistanceThreshold) {
      // It has moved far enough to be considered a drag
      passed = true;
		} else if (dragTimeThreshold > 0 && (time >= pointer.downTime + dragTimeThreshold)) {
      // It has been held down long enough to be considered a drag
      passed = true;
    }

    if (passed) {
      setDragState(pointer, 3);

      processDragStartList(pointer);
    }
  }

  /**
   * Processes the drag list for the given pointer and dispatches the start events for each object on it.
   */
  public function processDragStartList(pointer:Pointer) {
    // 3 = Pointer meets criteria and is freshly down, notify the draglist
    if (getDragState(pointer) != 3) return 0;

    var list = _drag.get(pointer.id + '');

    for (go in list) {
      
      go.input.dragState = 2;

      go.input.dragStartX = go.x;
      go.input.dragStartY = go.y;

      go.input.dragStartXGlobal = pointer.worldX;
      go.input.dragStartYGlobal = pointer.worldY;

      go.input.dragX = go.input.dragStartXGlobal - go.input.dragStartX;
      go.input.dragY = go.input.dragStartYGlobal - go.input.dragStartY;

      go.emit('GAMEOBJECT_DRAG_START', pointer, go.input.dragX, go.input.dragY);

      emit('DRAG_START', pointer, go);
    }

    setDragState(pointer, 4);

    return list.length;
  }

  /**
   * Processes a 'drag down' event for the given pointer. Checks the pointer state, builds-up the drag list
   * and prepares them all for interaction.
   */
  public function processDragDownEvent(pointer:Pointer) {
		if (_draggable.length == 0 || _temp.length == 0 || !pointer.primaryDown || getDragState(pointer) != 0) {
			// There are no draggable items, no over items or the pointer isn't down, so let's not even bother going further
			return 0;
    }
    
    // 1 = Primary button down and objects below, so collect a draglist
    setDragState(pointer, 1);

    // Get draggable objects, sort them, pick the top (or all) and store them somewhere
		var dragList:Array<RenderableGameObject> = [];

    for (go in _temp) {
      if (go.input.isDraggable && (go.input.dragState == 0)) {
        dragList.push(go);
      }
    }

    if (dragList.length == 0) {
      setDragState(pointer, 0);

      return 0;
    } else if (dragList.length > 1) {
      sortGameObjects(dragList);

      if (topOnly) dragList.splice(0, 1);
    }

    // draglist now contains all potential candidates for dragging
    _drag.set(pointer.id + '', dragList);

    if (dragDistanceThreshold == 0 && dragTimeThreshold == 0) {
      // No drag critera, so snap immediately to mode 3
      setDragState(pointer, 3);

      return processDragStartList(pointer);
    } else {
      // Check the distance / time on the next event
      setDragState(pointer, 2);

      return 0;
    }
  }

  /**
   * Processes a 'drag move' event for the given pointer.
   */
  public function processDragMoveEvent(pointer:Pointer) {
    // 2 = Pointer being checked if meets drag criteria
    if (getDragState(pointer) == 2) {
      processDragThresholdEvent(pointer, manager.game.loop.now);
    }

    if (getDragState(pointer) != 4) {
      return 0;
    }

    // 4 = Pointer actively dragging the draglist and has moved
    var list = _drag.get(pointer.id + '');

    for (go in list) {

      // If this GO has a target then let's check it
      if (go.input.target != null) {
        var index = _tempZones.indexOf(go.input.target);

        // Got a target, are we still over it?
        if (index == 0) {
          // We're still over it, and it's still the top of the display list, phew ...
					go.emit('GAMEOBJECT_DRAG_OVER', pointer, go.input.target);

					emit('DRAG_OVER', pointer, go, go.input.target);
        } else if (index > 0) {
          // Still over it but it's no longer top of the display list (targets must always be at the top)
					go.emit('GAMEOBJECT_DRAG_LEAVE', pointer, go.input.target);

					emit('DRAG_LEAVE', pointer, go, go.input.target);

          go.input.target = _tempZones[0];

					go.emit('GAMEOBJECT_DRAG_ENTER', pointer, go.input.target);

					emit('DRAG_ENTER', pointer, go, go.input.target);
        } else {
					// Nope, we've moved on (or the target has!), leave the old target
					go.emit('GAMEOBJECT_DRAG_LEAVE', pointer, go.input.target);

					emit('DRAG_LEAVE', pointer, go, go.input.target);

					// Anything new to replace it?
					// Yup!
					if (_tempZones[0] != null) {
            go.input.target = _tempZones[0];

						go.emit('GAMEOBJECT_DRAG_ENTER', pointer, go.input.target);

						emit('DRAG_ENTER', pointer, go, go.input.target);
					} else {
						// Nope
						go.input.target = null;
					}
        }
			} else if (go.input.target == null && _tempZones[0] != null) {
        go.input.target = _tempZones[0];

				go.emit('GAMEOBJECT_DRAG_ENTER', pointer, go.input.target);

				emit('DRAG_ENTER', pointer, go, go.input.target);
      }

      var dragX:Float;
      var dragY:Float;

      // TODO: container code

      dragX = pointer.worldX - go.input.dragX;
      dragY = pointer.worldY - go.input.dragY;

      go.emit('GAMEOBJECT_DRAG', pointer, dragX, dragY);

      emit('DRAG', pointer, go, dragX, dragY);
    }

    return list.length;
  }

  /**
   * Processes a 'drag down' event for the given pointer. Checks the pointer state, builds-up the drag list
   * and prepares them all for interaction.
   */
  public function processDragUpEvent(pointer:Pointer) {
		//  5 = Pointer was actively dragging but has been released, notify draglist
		var list = _drag.get(pointer.id + '');

		for (go in list) {
			if (go.input != null && go.input.dragState == 2) {
				go.input.dragState = 0;

				go.input.dragX = go.input.localX - go.displayOriginX;
				go.input.dragY = go.input.localY - go.displayOriginY;

				var dropped = false;

				if (go.input.target != null) {
					go.emit('GAMEOBJECT_DROP', pointer, go.input.target);

					emit('DROP', pointer, go, go.input.target);

					go.input.target = null;

					dropped = true;
				}

				// And finally the dragend event
				if (go.input != null) {
					go.emit('GAMEOBJECT_DRAG_END', pointer, go.input.dragX, go.input.dragY, dropped);

					emit('DRAG_END', pointer, go, dropped);
				}
			}
		}

		setDragState(pointer, 0);

		list.splice(0, list.length);

		return 0;
  }

  /**
   * An internal method that handles the Pointer movement event.
   */
  public function processMoveEvents(pointer:Pointer) {
		var total = 0;

		// _eventData.cancelled = false;

		var aborted = false;

		//  Go through all objects the pointer was over and fire their events / callbacks
		for (go in _temp) {
			if (go.input == null) {
				continue;
			}

			total++;

			go.emit('GAMEOBJECT_POINTER_MOVE', pointer, go.input.localX, go.input.localY/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}

			emit('GAMEOBJECT_MOVE', pointer, go/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}

			if (topOnly) {
				break;
			}
		}

		if (!aborted) {
			emit('POINTER_MOVE', pointer, _temp);
		}

		return total;
  }

  /**
   * An internal method that handles a mouse wheel event.
   */
  public function processWheelEvent(pointer:Pointer) {
		var total = 0;

		// _eventData.cancelled = false;

		var aborted = false;

		var delta = pointer.delta;

		// Go through all objects the pointer was over and fire their events / callbacks
		for (go in _temp) {
			if (go.input == null) {
				continue;
			}

			total++;

			go.emit('GAMEOBJECT_POINTER_WHEEL', pointer, delta/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}

			emit('GAMEOBJECT_WHEEL', pointer, go, delta/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}
		}

		if (!aborted) {
			emit('POINTER_WHEEL', pointer, _temp, delta);
		}

		return total;
  }

  /**
   * An internal method that handles the Pointer over events.
   * This is called when a touch input hits the canvas, having previously been off of it.
   */
  public function processOverEvents(pointer:Pointer) {
		var totalInteracted = 0;

		var total = _temp.length;

		var justOver = [];

		if (total > 0) {
			// _eventData.cancelled = false;

			var aborted = false;

			for (go in _temp) {
				if (go.input == null) {
					continue;
				}

				justOver.push(go);

				go.emit('GAMEOBJECT_POINTER_OVER', pointer, go.input.localX, go.input.localY/*, _eventContainer*/);

				totalInteracted++;

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}

				emit('GAMEOBJECT_OVER', pointer, go/*, _eventContainer*/);

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}
			}

			if (!aborted) {
				emit('POINTER_OVER', pointer, justOver);
			}
		}

		// Then sort it into display list order
		_over.set(pointer.id +'', justOver);

		return totalInteracted;
  }

  /**
   * An internal method that handles the Pointer out events.
   * This is called when a touch input leaves the canvas, as it can never be 'over' in this case.
   */
  public function processOutEvents(pointer:Pointer) {
		var previouslyOver = _over.get(pointer.id + '');

		var totalInteracted = 0;

		if (previouslyOver.length > 0) {
			// _eventData.cancelled = false;

			var aborted = false;

			sortGameObjects(previouslyOver);

			// Call onOut for everything in the previouslyOver array
			for (go in previouslyOver) {
        if (go.input == null) {
          continue;
        }

        go.emit('GAMEOBJECT_POINTER_OUT', pointer/*, _eventContainer*/);

        totalInteracted++;

        if (/*_eventData.cancelled || */go.input == null) {
          aborted = true;
          break;
        }

        emit('GAMEOBJECT_OUT', pointer, go/*, _eventContainer*/);

        if (/*_eventData.cancelled || */go.input == null) {
          aborted = true;
          break;
        }
      }

      if (!aborted) {
        emit('POINTER_OUT', pointer, previouslyOver);
      }

			_over.set(pointer.id + '', []);
		}

		return totalInteracted;
  }

  /**
   * An internal method that handles the Pointer over and out events.
   */
  public function processOverOutEvents(pointer:Pointer) {

		var justOut = [];
		var justOver = [];
		var stillOver = [];
		var previouslyOver = _over.get(pointer.id + '');
		var currentlyDragging = _drag.get(pointer.id + '');

		// Go through all objects the pointer was previously over, and see if it still is.
		// Splits the previouslyOver array into two parts: justOut and stillOver

		for (go in previouslyOver) {
			if (_temp.indexOf(go) == -1 && currentlyDragging.indexOf(go) == -1) {
				// Not in the currentlyOver array, so must be outside of this object now
				justOut.push(go);
			} else {
				// In the currentlyOver array
				stillOver.push(go);
			}
		}

		// Go through all objects the pointer is currently over (the hit test results)
		// and if not in the previouslyOver array we know it's a new entry, so add to justOver
		for (go in _temp) {
			// Is this newly over?
			if (previouslyOver.indexOf(go) == -1) {
				justOver.push(go);
			}
		}

		// By this point the arrays are filled, so now we can process what happened...

		// Process the Just Out objects
		var total = justOut.length;

		var totalInteracted = 0;

		// _eventData.cancelled = false;

		var aborted = false;

		if (justOut.length > 0) {
			sortGameObjects(justOut);

			//  Call onOut for everything in the justOut array
			for (go in justOut) {
				if (go.input == null) {
					continue;
				}

				go.emit('GAMEOBJECT_POINTER_OUT', pointer/*, _eventContainer*/);

				totalInteracted++;

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}

        emit('GAMEOBJECT_OUT', pointer, go/*, _eventContainer*/);

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}
			}

			if (!aborted) {
				emit('POINTER_OUT', pointer, justOut);
			}
		}

		// Process the Just Over objects
		total = justOver.length;

		// _eventData.cancelled = false;

		aborted = false;

		if (total > 0) {
			sortGameObjects(justOver);

			// Call onOver for everything in the justOver array
			for (go in justOver) {
				if (go.input == null) {
					continue;
				}

				go.emit('GAMEOBJECT_POINTER_OVER', pointer, go.input.localX, go.input.localY/*, _eventContainer*/);

				totalInteracted++;

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}

				emit('GAMEOBJECT_OVER', pointer, go/*, _eventContainer*/);

				if (/*_eventData.cancelled || */go.input == null) {
					aborted = true;
					break;
				}
			}

			if (!aborted) {
				emit('POINTER_OVER', pointer, justOver);
			}
		}

		// Add the contents of justOver to the previously over array
		previouslyOver = stillOver.concat(justOver);

		// Then sort it into display list order
		_over.set(pointer.id + '', sortGameObjects(previouslyOver));

		return totalInteracted;
  }

  /**
   * An internal method that handles the Pointer up events.
   */
  public function processUpEvents(pointer:Pointer) {
		// _eventData.cancelled = false;

		var aborted = false;

		// Go through all objects the pointer was over and fire their events / callbacks
		for (go in _temp) {
      if (go.input == null) {
				continue;
			}

			go.emit('GAMEOBJECT_POINTER_UP', pointer, go.input.localX, go.input.localY/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}

			emit('GAMEOBJECT_UP', pointer, go/*, _eventContainer*/);

			if (/*_eventData.cancelled || */go.input == null) {
				aborted = true;
				break;
			}
		}

		//  If they released outside the canvas, but pressed down inside it, we'll still dispatch the event.
		if (!aborted && manager != null) {
      // TODO: check and see if pointer was up on game window
			//if (pointer.upElement == manager.game.canvas) {
				//emit('POINTER_UP', pointer, currentlyOver);
			//} else {
				emit('POINTER_UP_OUTSIDE', pointer);
			//}
		}

		return _temp.length;
  }

  /**
   * Queues a Game Object for insertion into this Input Plugin on the next update.
   */
	public function queueForInsertion(go:RenderableGameObject) {
		if (_pendingInsertion.indexOf(go) == -1 && _list.indexOf(go) == -1) {
			_pendingInsertion.push(go);
		}

		return this;
  }

  /**
   * Queues a Game Object for removal from this Input Plugin on the next update.
   */
	public function queueForRemoval(go:RenderableGameObject) {
    _pendingRemoval.push(go);

    return this;
  }

  /**
   * Sets the draggable state of the given array of Game Objects.
   *
   * They can either be set to be draggable, or can have their draggable state removed by passing `false`.
   *
   * A Game Object will not fire drag events unless it has been specifically enabled for drag.
   */
	public function setDraggable(children:Array<RenderableGameObject>, ?value:Bool = true) {
		for (go in children) {
			go.input.isDraggable = value;

			var index = _draggable.indexOf(go);

			if (value && index == -1) {
				_draggable.push(go);
			} else if (!value && index > -1) {
				_draggable.splice(index, 1);
			}
		}

		return this;
  }

  /**
   * Given an array of Game Objects, sort the array and return it, so that the objects are in depth index order
   * with the lowest at the bottom.
   */
	public function sortGameObjects(children:Array<RenderableGameObject>) {
		if (children.length < 2) {
			return children;
		}

		scene.sys.depthSort();

    children.sort(sortHandlerGO);

    return children;
  }

  /**
   * Return the child lowest down the display list (with the smallest index)
   * Will iterate through all parent containers, if present.
   */
  public function sortHandlerGO(childA:GameObject, childB:GameObject) {
    // TODO: add container code

		return displayList.getIndex(childB) - displayList.getIndex(childA);
  }

	/**
	 * Sets the hit area for the given array of Game Objects.
	 *
	 * A hit area is typically one of the geometric shapes Phaser provides, such as a `Phaser.Geom.Rectangle`
	 * or `Phaser.Geom.Circle`. However, it can be any object as long as it works with the provided callback.
	 *
	 * If no hit area is provided a Rectangle is created based on the size of the Game Object, if possible
	 * to calculate.
	 *
	 * The hit area callback is the function that takes an `x` and `y` coordinate and returns a boolean if
	 * those values fall within the area of the shape or not. All of the Phaser geometry objects provide this,
	 * such as `Phaser.Geom.Rectangle.Contains`.
   */
	public function setHitArea(gameObjects:Array<RenderableGameObject>) {
    // TODO: code for more complext hit areas
    return setHitAreaFromTexture(gameObjects);
  }

  /**
   * Sets the hit area for an array of Game Objects to be a `Phaser.Geom.Rectangle` shape, using
   * the Game Objects texture frame to define the position and size of the hit area.
   */
	public function setHitAreaFromTexture(gameObjects:Array<RenderableGameObject>, ?callback:Rectangle->Float->Float->RenderableGameObject->Bool) {
		if (callback == null)
			callback = (rect:Rectangle, x:Float, y:Float, go:RenderableGameObject) -> { RectangleUtils.contains(rect, x, y); };

    for (go in gameObjects) {
      var frame = go.frame;

      var width:Float = 0;
      var height:Float = 0;

      if (go.width > 0) {
        width = go.width;
        height = go.height;
      } else if (frame != null) {
        width = frame.realWidth;
        height = frame.realHeight;
      }

			if (width != 0 && height != 0) {
				go.input = new InteractiveObject(go, new Rectangle(0, 0, width, height), callback);

				queueForInsertion(go);
			}
    }
  }

  /**
   * The Scene that owns this plugin is shutting down.
   * We need to kill and reset all internal properties as well as stop listening to Scene events.
   */
  public function shutdown() {
		// Registered input plugins listen for this
		pluginEvents.emit('SHUTDOWN');

		_temp = [];
		_list = [];
		_draggable = [];
		_pendingRemoval = [];
		_pendingInsertion = [];
		_dragState = [];

		_drag.clear();
		_over.clear();

		removeAllListeners();

		var eventEmitter = systems.events;

		eventEmitter.removeListener('PRE_UPDATE', preUpdate);

		manager.events.removeListener('GAME_OUT', onGameOut);
		manager.events.removeListener('GAME_OVER', onGameOver);

		eventEmitter.removeListener('SHUTDOWN', shutdown);
  }

  /**
   * The Scene that owns this plugin is being destroyed.
   * We need to shutdown and then kill off all external references.
   */
  public function destroy() {
		shutdown();

		// Registered input plugins listen for this
		pluginEvents.emit('DESTROY');

		pluginEvents.removeAllListeners();

		scene.sys.events.removeListener('START', start);

		scene = null;
		cameras = null;
		manager = null;
		mouse = null;
  }

  /**
   * The x coordinates of the ActivePointer based on the first camera in the camera list.
   * This is only safe to use if your game has just 1 non-transformed camera and doesn't use multi-touch.
   */
  public var x(get, null):Float;

  function get_x() {
    return manager.activePointer.x;
  }

  /**
   * The y coordinates of the ActivePointer based on the first camera in the camera list.
   * This is only safe to use if your game has just 1 non-transformed camera and doesn't use multi-touch.
   */
  public var y(get, null):Float;

  function get_y() {
    return manager.activePointer.y;
  }

  /**
   * Are any mouse or touch pointers currently over the game canvas?
   */
  public var isOver(get, null):Bool;

  function get_isOver() {
    return manager.isOver;
  }

  /**
   * The mouse has its own unique Pointer object, which you can reference directly if making a _desktop specific game_.
   * If you are supporting both desktop and touch devices then do not use this property, instead use `activePointer`
   * which will always map to the most recently interacted pointer.
   */
  public var mousePointer(get, null):Pointer;

  function get_mousePointer() {
    return manager.mousePointer;
  }

  /**
   * The current active input Pointer.
   */
  public var activePointer(get, null):Pointer;

  function get_activePointer() {
    return manager.activePointer;
  }

  /**
   * A touch-based Pointer object.
   * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
   */
  public var pointer1(get, null):Pointer;

  function get_pointer1() {
    return manager.pointers[1];
  }

	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer2(get, null):Pointer;

	function get_pointer2() {
		return manager.pointers[2];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer3(get, null):Pointer;

	function get_pointer3() {
		return manager.pointers[3];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer4(get, null):Pointer;

	function get_pointer4() {
		return manager.pointers[4];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer5(get, null):Pointer;

	function get_pointer5() {
		return manager.pointers[5];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer6(get, null):Pointer;

	function get_pointer6() {
		return manager.pointers[6];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer7(get, null):Pointer;

	function get_pointer7() {
		return manager.pointers[7];
  }
  
  /**
   * A touch-based Pointer object.
   * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
   */
  public var pointer8(get, null):Pointer;

  function get_pointer8() {
    return manager.pointers[8];
  }

	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer9(get, null):Pointer;

	function get_pointer9() {
		return manager.pointers[9];
  }
  
	/**
	 * A touch-based Pointer object.
	 * This will be `undefined` by default unless you add a new Pointer using `addPointer`.
	 */
	public var pointer10(get, null):Pointer;

	function get_pointer10() {
		return manager.pointers[10];
	}
}