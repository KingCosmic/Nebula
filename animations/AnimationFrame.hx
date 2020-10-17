package core.animations;

import core.textures.Frame;

/**
 * A single frame in an Animation sequence.
 *
 * An AnimationFrame consists of a reference to the Texture it uses for rendering, references to other
 * frames in the animation, and index data. It also has the ability to modify the animation timing.
 *
 * AnimationFrames are generated automatically by the Animation class.
 */
class AnimationFrame {
  // The key of the Texture this AnimationFrame uses.
  public var textureKey:String;

  // The key of the Frame within the Texture that this AnimationFrame uses.
  public var textureFrame:Dynamic; // String or Int.

  // The index of this AnimationFrame within the Animation sequence.
  public var index:Int;

  // A reference to the Texture Frame this AnimationFrame uses for rendering.
  public var frame:Frame;

  // Is this the first frame in an animation sequence?
  public var isFirst:Bool = false;

  // Is this the last frame in an animation sequence?
  public var isLast:Bool = false;

  // A reference to the AnimationFrame that comes before this one in the animation, if any.
  public var prevFrame:AnimationFrame = null;

  // A reference to the AnimationFrame that comes after this one in the animation, if any.
  public var nextFrame:AnimationFrame = null;

  /**
   * Additional time (in ms) that this frame should appear for during playback.
   * The value is added onto the msPerFrame set by the animation.
   */
  public var duration:Float = 0;

  /**
   * What % through the animation does this frame come?
   * This value is generated when the animation is created and cached here.
   */
  public var progress:Float = 0;

  public function new(_textureKey:String, _textureFrame:Dynamic, _index:Int, _frame:Frame) {
    textureKey = _textureKey;
    textureFrame = _textureFrame;
    index = _index;
    frame = _frame;
  }

  /**
   * Destroys this object by removing references to external resources and callbacks.
   */
  public function destroy() {
    frame = null;

    // Shouldn't we also remove the nextFrame and prevFrame?
  }
}