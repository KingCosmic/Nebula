package core.animations;

import core.animations.Animation.AnimationConfig;
import core.utils.ArrayUtils;
import core.gameobjects.Sprite;
import core.gameobjects.GameObject;
import core.textures.TextureManager;
import core.EventEmitter;
import core.structs.CustomMap;

// TODO: Stagger play

typedef GenerateFrameNumbersConfig = {
  ?start:Int,
  ?end:Int,
  ?first:String,
  ?out:Array<Dynamic>,
  ?frames:Array<Dynamic>
}

class AnimationManager extends EventEmitter {
  // A reference to the Phaser.Game instance.
  public var game:Game;

  // A reference to the Texture Manager.
  public var textureManager:TextureManager;

  // The global time scale of the Animation Manager.
  // This scales the time delta between two frames, thus influencing the speed of time for the Animation Manager.
  public var globalTimeScale:Int = 1;

  // The Animations registered in the Animation Manager.
	// This map should be modified with the {@link #add} and {@link #create} methods of the Animation Manager.
  public var anims:CustomMap<Animation> = new CustomMap();

	/**
   * A list of animation mix times.
   *
   * See the {@link #setMix} method for more details.
   */
  public var mixes:CustomMap<Float> = new CustomMap();

  // Whether the Animation Manager is paused along with all of its Animations.
  public var paused:Bool = false;

  // The name of this Animation Manager.
  public var name:String = 'AnimationManager';

  public function new(_game:Game) {
    super();

    game = _game;

		game.events.once('BOOT', boot);
  }

	// Registers event listeners after the Game boots.
  public function boot() {
    textureManager = game.textures;

    game.events.once('DESTROY', destroy);
  }

	/**
  * Returns the mix delay between two animations.
  *
  * If no mix has been set-up, this method will return zero.
  *
  * If you wish to create, or update, a new mix, call the `addMix` method.
  * If you wish to remove a mix, call the `removeMix` method.
  */
  public function getMix(animA:Dynamic, animB:Dynamic) {
    
    var keyA = Std.isOfType(animA, String) ? animA : animA.key;
    var keyB = Std.isOfType(animB, String) ? animB : animB.key;

    var mixObj = mixes.get(keyA);

    if (mixObj != null && Reflect.hasField(mixObj, keyB)) {
      return Reflect.getProperty(mixObj, keyB);
    } else {
      return 0;
    }
  }

  // Adds an existing Animation to the Animation Manager.
  public function add(key:String, animation:Animation) {
    if (anims.has(key)) {
      // TODO: learn to debug
      return this;
    }

    animation.key = key;

    anims.set(key, animation);

    emit('ADD_ANIMATION', key, animation);

    return this;
  }

  // Checks to see if the given key is already in use within the Animation Manager or not.
  // Animations are global. Keys created in one scene can be used from any other Scene in your game. They are not Scene specific.
  public function exists(key: String) {
    return anims.has(key);
  }

  /**
   * Create one, or more animations from a loaded Aseprite JSON file.
   *
   * Aseprite is a powerful animated sprite editor and pixel art tool.
   *
   * You can find more details at https://www.aseprite.org/
   *
   * To export a compatible JSON file in Aseprite, please do the following:
   *
   * 1. Go to "File - Export Sprite Sheet"
   *
   * 2. On the **Layout** tab:
   * 2a. Set the "Sheet type" to "Packed"
   * 2b. Set the "Constraints" to "None"
   * 2c. Check the "Merge Duplicates" checkbox
   *
   * 3. On the **Sprite** tab:
   * 3a. Set "Layers" to "Visible layers"
   * 3b. Set "Frames" to "All frames", unless you only wish to export a sub-set of tags
   *
   * 4. On the **Borders** tab:
   * 4a. Check the "Trim Sprite" and "Trim Cells" options
   * 4b. Ensure "Border Padding", "Spacing" and "Inner Padding" are all > 0 (1 is usually enough)
   *
   * 5. On the **Output** tab:
   * 5a. Check "Output File", give your image a name and make sure you choose "png files" as the file type
   * 5b. Check "JSON Data" and give your json file a name
   * 5c. The JSON Data type can be either a Hash or Array, Phaser doesn't mind.
   * 5d. Make sure "Tags" is checked in the Meta options
   * 5e. In the "Item Filename" input box, make sure it says just "{frame}" and nothing more.
   *
   * 6. Click export
   *
   * This was tested with Aseprite 1.2.25.
   *
   * This will export a png and json file which you can load using the Atlas Loader, i.e.:
   *
   * ```javascript
   * function preload ()
   * {
   *     this.load.path = 'assets/animations/aseprite/';
   *     this.load.atlas('paladin', 'paladin.png', 'paladin.json');
   * }
   * ```
   *
   * Once exported, you can call this method from within a Scene with the 'atlas' key:
   *
   * ```javascript
   * this.anims.createFromAseprite('paladin');
   * ```
   *
   * Any animations defined in the JSON will now be available to use in Phaser and you play them
   * via their Tag name. For example, if you have an animation called 'War Cry' on your Aseprite timeline,
   * you can play it in Phaser using that Tag name:
   *
   * ```javascript
   * this.add.sprite(400, 300).play('War Cry');
   * ```
   *
   * When calling this method you can optionally provide an array of tag names, and only those animations
   * will be created. For example:
   *
   * ```javascript
   * this.anims.createFromAseprite('paladin', [ 'step', 'War Cry', 'Magnum Break' ]);
   * ```
   *
   * This will only create the 3 animations defined. Note that the tag names are case-sensitive.
   */
  public function createFromAseprite(key: String, tags) {
    // TODO: 
  }

  /**
   * Creates a new Animation and adds it to the Animation Manager.
   *
   * Animations are global. Once created, you can use them in any Scene in your game. They are not Scene specific.
   *
   * If an invalid key is given this method will return `false`.
   *
   * If you pass the key of an animation that already exists in the Animation Manager, that animation will be returned.
   *
   * A brand new animation is only created if the key is valid and not already in use.
   *
   * If you wish to re-use an existing key, call `AnimationManager.remove` first, then this method.
   */
	public function create(config:AnimationConfig) {
		var key:String = config.key;

		var anim:Animation = null;

		if (key != null) {
			anim = get(key);

			if (anim == null) {
				anim = new Animation(this, key, config);

				anims.set(key, anim);

				emit('ADD_ANIMATION', key, anim);
			}
		}

		return anim;
  }

	/**
	 * Generate an array of {@link Phaser.Types.Animations.AnimationFrame} objects from a texture key and configuration object.
	 *
	 * Generates objects with numbered frame names, as configured by the given {@link Phaser.Types.Animations.GenerateFrameNumbers}.
	 *
	 * If you're working with a texture atlas, see the `generateFrameNames` method instead.
   */
  public function generateFrameNumbers(key:String, config:GenerateFrameNumbersConfig):Array<AnimationFrame> {
    var start = (config.start != null) ? config.start : 0;
    var end = (config.end != null) ? config.end : -1;
    var first = (config.first != null) ? config.first : '';
		var out = (config.out != null) ? config.out : [];
    var frames:Array<Dynamic> = (config.frames != null) ? config.frames : [];
    
    var texture = textureManager.get(key);

		if (texture == null) {
      var output:Array<AnimationFrame> = cast out;
      return output;
    }

    if (first != '' && texture.has(first))
      out.push({ key: key, frame: first });

    // No 'frames' array? Then generate one automatically
    if (frames.length == 0) {
      if (end == -1) {
				// -1 because of __BASE, which we don't want in our results
				// and -1 because frames are zero based
				end = texture.frameTotal - 2;
      }

      frames = ArrayUtils.numberArray(start, end);
    }

    for (i in 0...frames.length) {
      if (texture.has(frames[i])) {
        out.push({ key: key, frame: frames[i] });
      } else {
        trace('generateFrameNumbers: Frame ' + i + ' missing from texture: ' + key);
      }
    }

		var output:Array<AnimationFrame> = cast out;
		return output;
  }

  public function get(key:String) {
    return anims.get(key);
  }

  // Play an animation on the given Game Objects that have an Animation Component.
  public function play(key:String, children:Array<Sprite>) {

    for (child in children) {
      child.anims.play(key);
    }

    return this;
  }

	public function pauseAll() {
    if (!paused) {
      paused = true;
      emit('PAUSE_ALL');
    }
    return this;
  }

	/**
  * Removes an Animation from this Animation Manager, based on the given key.
  *
  * This is a global action. Once an Animation has been removed, no Game Objects
  * can carry on using it.
  */
  public function remove(key:String) {
    var anim = get(key);

    if (anim != null) {
      emit('REMOVE_ANIMATION', key, anim);

      anims.delete(key);
    }

    return anim;
  }

  // Resume all paused animations
	public function resumeAll() {
		if (paused) {
			paused = false;
			emit('RESUME_ALL');
		}
		return this;
	}

  /**
   * Destroy this Animation Manager and clean up animation definitions and references to other objects.
   * This method should not be called directly. It will be called automatically as a response to a `destroy` event from the Phaser.Game instance.
   */
  public function destroy() {
		this.anims.clear();

		this.textureManager = null;

		this.game = null;
  }
}