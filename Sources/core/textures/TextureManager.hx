package core.textures;

import core.gameobjects.components.TextureCrop;
import core.textures.Parser;
import core.gameobjects.GameObject;

/**
 * Textures are managed by the global TextureManager. This is a singleton class that is
 * responsible for creating and delivering Textures and their corresponding Frames to Game Objects.
 *
 * Sprites and other Game Objects get the texture data they need from the TextureManager.
 *
 * Access it via `scene.textures`.
 */
class TextureManager extends EventEmitter {
  // The Game that this TextureManager belongs to.
  public var game:Game;

  // The name of this manager.
  public var name:String = 'TextureManager';

  /**
   * An object that has all of textures that Texture Manager creates.
   * Textures are assigned to keys so we can access to any texture that this object has directly by key value without iteration.
   */
  public var list:Map<String, Texture> = new Map();

  // An counting value used for emitting 'ready' event after all of managers in game is loaded.
  public var _pending:Int = 0;

  public function new(_game:Game) {
    super();

    game = _game;

    game.events.once('BOOT', boot);
  }

  /**
   * The Boot Handler called by Phaser.Game when it first starts up.
   */
  public function boot() {
    on('LOAD', updatePending);
    on('ERROR', updatePending);

    // TODO: add default images
    
    game.events.once('DESTROY', destroy);
  }

  /**
   * After 'onload' or 'onerror' invoked twice, emit 'ready' event.
   */
  public function updatePending() {
    _pending--;

    if (_pending == 0) {
      removeListener('LOAD', updatePending);
      removeListener('ERROR');

      emit('READY');
    }
  }

  /**
   * Checks the given texture key and throws a console.warn if the key is already in use, then returns false.
   * If you wish to avoid the console.warn then use `TextureManager.exists` instead.
   */
  public function checkKey(key:String) {
    if (exists(key)) {
      trace('Texture key already in use: ' + key);
      return false;
    }

    return true;
  }

  /**
   * Removes a Texture from the Texture Manager and destroys it. This will immediately
   * clear all references to it from the Texture Manager, and if it has one, destroy its
   * WebGLTexture. This will emit a `removetexture` event.
   *
   * Note: If you have any Game Objects still using this texture they will start throwing
   * errors the next time they try to render. Make sure that removing the texture is the final
   * step when clearing down to avoid this.
   */
  public function remove(key:String) {
    var texture:Texture = null;
    if (exists(key)) {
      texture = get(key);
    } else {
      trace('No texture found matching key: ' + key);
      return this;
    }

    // By this point key should be a Texture, if not, the following fails anyway.
    if (list.exists(texture.key)) {
      texture.destroy();

      emit('REMOVE', texture.key);
    }

    return this;
  }

  /**
   * Removes a key from the Texture Manager but does not destroy the Texture that was using the key.
   */
  public function removeKey(key:String) {
		list.remove(key);

    return this;
  }

  /**
   * Adds a new Texture to the Texture Manager created from the given Image element.
   */
  public function addImage(key:String, source:kha.Image) {
    if (!checkKey(key)) return null;

    var texture = create(key, source);

    Parser.image(texture, 0);

    emit('ADD', key, source);

    return texture;
  }

  /**
   * Adds a Sprite Sheet to this Texture Manager.
   *
   * In Phaser terminology a Sprite Sheet is a texture containing different frames, but each frame is the exact
   * same size and cannot be trimmed or rotated.
   */
  public function addSpriteSheet(key:String, source:kha.Image, config:{frameWidth:Int,frameHeight:Int,startFrame:Int,endFrame:Int,margin:Int,spacing:Int}) {
    if (!checkKey(key)) return null;

    var texture = create(key, source);

    var width = texture.source[0].width;
    var height = texture.source[0].height;

    Parser.spriteSheet(texture, 0, 0, 0, width, height, config);

    emit('ADD', key, texture);

    return texture;
  }

  /**
   * Creates a new Texture using the given source and dimensions.
   */
  public function create(key:String, source:kha.Image, ?width:Int = 0, ?height:Int = 0) {
    if (!checkKey(key)) return null;

    var texture = new Texture(this, key, [source], width, height);

    list.set(key, texture);

    return texture;
  }

  /**
   * Checks the given key to see if a Texture using it exists within this Texture Manager.
   */
  public function exists(key:String) {
    return list.exists(key);
  }

  /**
   * Returns a Texture from the Texture Manager that matches the given key.
   *
   * If the key is `undefined` it will return the `__DEFAULT` Texture.
   *
   * If the key is an instance of a Texture, it will return the key directly.
   *
   * Finally. if the key is given, but not found and not a Texture instance, it will return the `__MISSING` Texture.
   */
  public function get(?key:String = '__DEFAULT') {
    if (list.exists(key)) return list.get(key);

    return list.get(key);
  }

	/**
	 * Takes a Texture key and Frame name and returns a reference to that Frame, if found.
	 */
	public function getFrame(key:String, frame:Any) {
		return list.exists(key) ? list.get(key).get(frame) : null;
	}

  /**
   * Sets the given Game Objects `texture` and `frame` properties so that it uses
   * the Texture and Frame specified in the `key` and `frame` arguments to this method.
   */
	public function setTexture(gameObject:TextureCrop, key:String, frame:String) {
    if (list.exists(key)) {
      gameObject.texture = list.get(key);
      gameObject.frame = gameObject.texture.get(frame);
    }

    return gameObject;
  }
  /* // King Check This Out Please, To-Do
  public function setTexture(gameObject:{ texture : Texture, frame : Frame }, key:String, frame:String) {
    if (list.exists(key)) {
      gameObject.texture = list.get(key);
      gameObject.frame = gameObject.texture.get(frame);
    }

    return gameObject;
  }*/

  /**
   * Destroys the Texture Manager and all Textures stored within it.
   */
  public function destroy() {
    for (texture in list.iterator()) {
      texture.destroy();
    }

    list.clear();

    game = null;
  }
}