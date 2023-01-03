package nebula.assets;

import nebula.gameobjects.GameObject;
import nebula.assets.Texture;
import nebula.assets.Parser;
import kha.Image;
import kha.Blob;
import kha.Font;

typedef FrameConfig = {
	frameWidth:Int,
	frameHeight:Int,
	startFrame:Int,
	endFrame:Int,
	margin:Int,
	spacing:Int
}

/**
 * Assets are managed by the global AssetManager. This is a singleton class that is
 * responsible for creating and delivering Assets to GameObjects.
 *
 * Access it via `scene.assets`.
 */
class AssetManager {
	/**
	 * The AssetManager instance for global use.
	 */
	static public var instance:AssetManager;

	/**
	 * A Map that has all of textures that the AssetManager creates.
	 * Textures are assigned to keys so we can access to any texture that this Map
	 * has directly by key value without iteration.
	 */
	public var textures:Map<String, Texture> = new Map();

	/**
	 * A Map that has all of the fonts that the AssetManager creates.
	 * Fonts are assigned to keys so we can access any Font that this Map
	 * has directly by key without iteration.
	 */
	public var fonts:Map<String, Font> = new Map();

	/**
	 * A Map that has all of the Json that the AssetManager loads.
	 * Json is assigned to keys so we can access any Json that this Map
	 * has directly by key without iteration.
	 * 
	 * Note this holds the Blob that was loaded.
	 */
	public var json:Map<String, Blob> = new Map();

  /**
   * Our EventEmitter.
   */
  public var events:EventEmitter = new EventEmitter();

  /**
	 * The Boot Handler called by Nebula.Game when it first starts up.
	 */
  public function new() {
    Game.get().events.once('DESTROY', destroy);
  }

  static public function get():AssetManager {
    if (instance == null) {
      instance = new AssetManager();
    }

    return instance;
  }

	/**
	 * Checks the given texture key and throws a console.warn if the key is already in use, then returns false.
	 * If you wish to avoid the console.warn then use `AssetManager.textureExists` instead.
	 */
	public function checkTextureKey(key:String) {
		if (textureExists(key)) {
			trace('Texture key already in use: ' + key);
			return false;
		}

		return true;
	}

	/**
	 * Checks the given font key and throws a console.warn if the key is already in use, then returns false.
	 * If you wish to avoid the trace then use `AssetManager.fontExists` instead.
	 */
	public function checkFontKey(key:String) {
		if (fontExists(key)) {
			trace('Font key already in use: ' + key);
			return false;
		}

		return true;
	}

	/**
	 * Checks the given json key and trace's if the key is already in use, then returns false.
	 * If you wish to avoid the trace then use `AssetManager.jsonExists` instead.
	 */
	public function checkJsonKey(key:String) {
		if (jsonExists(key)) {
			trace('Json key already in use: ' + key);
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
	public function removeTexture(key:String) {
		var texture:Texture = null;

		if (textureExists(key)) {
			texture = getTexture(key);
		} else {
			trace('No texture found matching key: ' + key);
      return;
		}

		// By this point key should be a Texture, if not, the following fails anyway.
		if (textures.exists(texture.key)) {
			texture.destroy();

			events.emit('REMOVE', texture.key);
		}
	}

	/**
	 * Removes a Font from the Font Manager and destroys it. This will immediately
	 * clear all references to it from the Texture Manager. This will emit a `removeFont` event.
	 *
	 * Note: If you have any Game Objects still using this font they will start throwing
	 * errors the next time they try to render. Make sure that removing the font is the final
	 * step when clearing down to avoid this.
	 */
	public function removeFont(key:String) {
		if (!fontExists(key)) {
			trace('No Font found matching key: ' + key);
			return;
		}

		if (fonts.remove(key)) {
			events.emit('REMOVE', key);
		}
	}

	/**
	 * Removes a key from the Texture Manager but does not destroy the Texture that was using the key.
	 */
	public function removeTextureKey(key:String) {
		textures.remove(key);
	}

	/**
	 * Adds a new Texture to the Asset Manager created from the given Image element.
	 */
	public function addImage(key:String, source:Image) {
		if (!checkTextureKey(key))
			return null;

		var texture = createTexture(key, source);

		Parser.image(texture);

		events.emit('ADD', key, source);

		return texture;
	}

	/**
	 * Adds a new Font to the Asset Manager.
	 */
	public function addFont(key:String, source:Font) {
		if (!checkFontKey(key))
			return null;

		fonts.set(key, source);

		return source;
	}

	/**
	 * Adds a new Json to the Asset Manager.
	 */
	public function addJson(key:String, source:Blob) {
		if (!checkJsonKey(key))
			return null;

		json.set(key, source);

		return source;
	}

	/**
	 * Adds a Sprite Sheet to this Texture Manager.
	 *
	 * In Phaser terminology a Sprite Sheet is a texture containing different frames, but each frame is the exact
	 * same size and cannot be trimmed or rotated.
	 */
	public function addSpriteSheet(key:String, source:Image, config:FrameConfig) {
		if (!checkTextureKey(key))
			return null;

		var texture = createTexture(key, source);

		var width = texture.width;
		var height = texture.height;

		Parser.spriteSheet(texture, 0, 0, 0, width, height, config);

		events.emit('ADD', key, texture);

		return texture;
	}

	/**
	 * Creates a new Texture using the given source and dimensions.
	 */
	public function createTexture(key:String, source:Image) {
		if (!checkTextureKey(key))
			return null;

		var texture = new Texture(key, source);

		textures.set(key, texture);

		return texture;
	}

	/**
	 * Checks the given key to see if a Texture using it exists within this Asset Manager.
	 */
	public function textureExists(key:String) {
		return textures.exists(key);
	}

	/**
	 * Checks the given key to see if a Font using it exists within this Asset Manager.
	 */
	public function fontExists(key:String) {
		return fonts.exists(key);
	}

	/**
	 * Checks the given key to see if a Json using it exists within this Asset Manager.
	 */
	public function jsonExists(key:String) {
		return json.exists(key);
	}

	/**
	 * Returns a Font from the AssetManager that matches the given key.
	 *
	 * If the key is `undefined` it will return the `__DEFAULT` Font.
	 *
	 * If the key is an instance of a Font, it will return the key directly.
	 */
	public function getFont(?key:String = '__DEFAULT') {
		if (fonts.exists(key))
			return fonts.get(key);

		return fonts.get('__DEFAULT');
	}

	/**
	 * Returns a Font from the AssetManager that matches the given key.
	 *
	 * If the key is `undefined` it will return the `__DEFAULT` Font.
	 *
	 * If the key is an instance of a Font, it will return the key directly.
	 */
	public function getJson(?key:String = '') {
		return json.get(key);
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
	public function getTexture(?key:String = '__DEFAULT') {
		if (textures.exists(key))
			return textures.get(key);

		return textures.get('__MISSING');
	}

	/**
	 * Takes a Texture key and Frame name and returns a reference to that Frame, if found.
	 */
	public function getFrame(key:String, frame:Any) {
		return textures.exists(key) ? textures.get(key).get(frame) : null;
	}

	/**
	 * Sets the given Game Objects `texture` and `frame` properties so that it uses
	 * the Texture and Frame specified in the `key` and `frame` arguments to this method.
	 */
  public function setTexture(go:GameObject, key:String, frame:String) {
		if (textures.exists(key)) {
			go.texture = textures.get(key);
			go.frame = go.texture.get(frame);
		}

		return go;
	}

	/**
	 * Destroys the Texture Manager and all Textures stored within it.
	 */
	public function destroy() {
		for (texture in textures.iterator()) {
			texture.destroy();
		}

		// TODO: Look into unloading these Textures
		// and Fonts.
    // ^ I think this is unnecesarry since the AssetManager should only
    // be destroyed when the game is closed by the user and memory is cleared anyways.

		textures.clear();
		fonts.clear();
		json.clear();
	}
}