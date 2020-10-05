package core.textures;

/**
 * A Texture consists of a source, usually an Image from the Cache, and a collection of Frames.
 * The Frames represent the different areas of the Texture. For example a texture atlas
 * may have many Frames, one for each element within the atlas. Where-as a single image would have
 * just one frame, that encompasses the whole image.
 * 
 * Every Texture, no matter where it comes from, always has at least 1 frame called the `__BASE` frame.
 * This frame represents the entirety of the source image.
 *
 * Textures are managed by the global TextureManager. This is a singleton class that is
 * responsible for creating and delivering Textures and their corresponding Frames to Game Objects.
 *
 * Sprites and other Game Objects get the texture data they need from the TextureManager.
 */
class Texture {
  // A reference to the Texture Manager this Texture belongs to.
  public var manager:TextureManager;

  // The unique string-based key of this Texture.
  public var key:String;

  /**
   * An array of TextureSource instances.
   * These are unique to this Texture and contain the actual Image (or Canvas) data.
   */
  public var source:Array<TextureSource> = [];

  // TODO: data source

  /**
   * A key-value object pair associating the unique Frame keys with the Frames objects.
   */
  public var frames:Map<String, Frame> = new Map();

  // The name of the first frame of the texture.
  public var firstFrame = '__BASE';

  /**
   * The total number of Frames in this Texture, including the `__BASE` frame.
   * 
   * A Texture will always contain at least 1 frame because every Texture contains a `__BASE` frame by default,
   * in addition to any extra frames that have been added to it, such as when parsing a Sprite Sheet or Texture Atlas.
   */
  public var frameTotal:Int = 0;

  public function new(_manager:TextureManager, _key:String, _sources:Array<kha.Image>, width:Int, height:Int) {
    manager = _manager;
    key = _key;

    for (_source in _sources) {
      source.push(new TextureSource(this, _source, width, height));
    }
  }

  /**
   * Adds a new Frame to this Texture.
   *
   * A Frame is a rectangular region of a TextureSource with a unique index or string-based key.
   * 
   * The name given must be unique within this Texture. If it already exists, this method will return `null`.
   */
  public function add(name:String, sourceIndex:Int, x:Int, y:Int, width:Int, height:Int) {
    if (has(name)) return null;

    var frame = new Frame(this, name, sourceIndex, x, y, width, height);

    frames.set(name, frame);

		// Set the first frame of the Texture (other than __BASE)
		// This is used to ensure we don't spam the display with entire
		// atlases of sprite sheets, but instead just the first frame of them
    // should the dev incorrectly specify the frame index
    if (firstFrame == '__BASE') {
      firstFrame = name;
    }

    frameTotal++;

    return frame;
  }

  /**
   * Removes the given Frame from this Texture. The Frame is destroyed immediately.
   * 
   * Any Game Objects using this Frame should stop using it _before_ you remove it,
   * as it does not happen automatically.
   */
  public function remove(name:String) {
    if (!has(name)) return false;

    var frame = get(name);

    frame.destroy();

    frames.remove(name);

    return true;
  }

  /**
   * Checks to see if a Frame matching the given key exists within this Texture.
   */
  public function has(name:String) {
    return frames.exists(name);
  }

  /**
   * Gets a Frame from this Texture based on either the key or the index of the Frame.
   *
   * In a Texture Atlas Frames are typically referenced by a key.
   * In a Sprite Sheet Frames are referenced by an index.
   * Passing no value for the name returns the base texture.
   */
  public function get(?name:String = '') {
    if (name == '') name = firstFrame;

    var frame = frames.get(name);

    if (frame == null) {
      trace('TEXTURE MISSING :' + name);

      frame = frames.get(firstFrame);
    }

    return frame;
  }

  /**
   * Takes the given TextureSource and returns the index of it within this Texture.
   * If it's not in this Texture, it returns -1.
   * Unless this Texture has multiple TextureSources, such as with a multi-atlas, this
   * method will always return zero or -1.
   */
  public function getTextureSourceIndex(_source:TextureSource) {
    for (i in 0...source.length) {
      if (source[i] == _source) {
        return i;
      }
    }

    return -1;
  }

  /**
   * Returns an array of all the Frames in the given TextureSource.
   */
  public function getFramesFromTextureSource() {
    // TODO:
  }

  /**
   * Returns an array with all of the names of the Frames in this Texture.
   *
   * Useful if you want to randomly assign a Frame to a Game Object, as you can
   * pick a random element from the returned array.
   */
  public function getFrameNames(?includeBase:Bool = false) {
    var out:Array<String> = [];

    for (key in frames.keys()) {
      out.push(key);
    }

    if (!includeBase) {
      var idx = out.indexOf('__BASE');

      if (idx != -1) out.splice(idx, 1);
    }

    return out;
  }

  /**
   * Given a Frame name, return the source image it uses to render with.
   *
   * This will return the actual DOM Image or Canvas element.
   */
  public function getSourceImage() {
    // TODO:
  }

  /**
   * Given a Frame name, return the data source image it uses to render with.
   * You can use this to get the normal map for an image for example.
   */
  public function getDataSourceImage() {
    // TODO:
  }

  /**
   * Adds a data source image to this Texture.
   *
   * An example of a data source image would be a normal map, where all of the Frames for this Texture
   * equally apply to the normal map.
   */
  public function setDataSource() {
    // TODO:
  }

  /**
   * Destroys this Texture and releases references to its sources and frames.
   */
  public function destroy() {
    for (frame in frames.iterator()) {
      frame.destroy();
    }

    source = [];
    frames.clear();

    manager.removeKey(key);

    manager = null;
  }
}