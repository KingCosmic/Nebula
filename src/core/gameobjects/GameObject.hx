package core.gameobjects;

import core.cameras.Camera;
import core.scene.Scene;

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
	 * If this Game Object is enabled for Arcade or Matter Physics then this property will contain a reference to a Physics Body.
	 */
	public var body = null; // To-Do {?(Phaser.Physics.Arcade.Body|Phaser.Physics.Arcade.StaticBody|MatterJS.BodyType)}

	/**
	 * This Game Object will ignore all calls made to its destroy method if this flag is set to `true`.
	 * This includes calls that may come from a Group, Container or the Scene itself.
	 * While it allows you to persist a Game Object across Scenes, please understand you are entirely
	 * responsible for managing references to and from this Game Object.
	 */
	public var ignoreDestroy:Bool = false;

	// INITIALIZE//
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