package core.animations;

import core.utils.ArrayUtils;
import core.math.CMath;
import core.textures.TextureManager;

typedef AnimationConfig = {
  ?key:String,
  ?frames:Array<AnimationFrame>,
  ?defaultTextureKey:Null<String>,
  ?frameRate:Float,
  ?duration:Float,
  ?skipMissedFrames:Bool,
  ?delay:Float,
  ?repeat:Int,
  ?repeatDelay:Float,
  ?yoyo:Bool,
  ?showOnStart:Bool,
  ?hideOnComplete:Bool
}

/**
 * A Frame based Animation.
 *
 * Animations in Phaser consist of a sequence of `AnimationFrame` objects, which are managed by
 * this class, along with properties that impact playback, such as the animations frame rate
 * or delay.
 *
 * This class contains all of the properties and methods needed to handle playback of the animation
 * directly to an `AnimationState` instance, which is owned by a Sprite, or similar Game Object.
 *
 * You don't typically create an instance of this class directly, but instead go via
 * either the `AnimationManager` or the `AnimationState` and use their `create` methods,
 * depending on if you need a global animation, or local to a specific Sprite.
 */
class Animation {
  // A reference to the global Animaiton Manager.
  public var manager:AnimationManager;

  // The unique identifying string for this animation.
  public var key:String;

  // A frame based animation (as opposed to a bone based animation)
  public var type:String = 'frame';

  // Extract all the frame data into the frames array.
  public var frames:Array<AnimationFrame> = [];

  // The frame rate of playback in frames per second (default 24 if duration is null)
  public var frameRate:Float = null;

  /**
   * How long the animation should play for, in milliseconds.
   * If the `frameRate` property has been set then it overrides this value,
   * otherwise the `frameRate` is derived from `duration`.
   */
  public var duration:Float = null;

  // How ms per frame, not including the frame specific modifiers.
  public var msPerFrame:Float;

  // Skip frames if the time lags, or always advance anyway?
  public var skipMissedFrames:Bool = true;

  // The delay in ms before the playback will begin.
  public var delay:Float = 0;

  // Number of times to repeat the animation. Set to -1 to repeat forever.
  public var repeat:Int = 0;

  // The delay in ms before the repeat starts.
  public var repeatDelay:Float = 0;

  // Should the animation yoyo (reverse back down to the start) before repeating?
  public var yoyo:Bool = false;

  // Should the GameObject's 'visible' property be set to 'true' when the animation starts to play?
  public var showOnStart:Bool = false;

  // Should the GameObject's `visible` property be set to `false` when the animation finishes?
  public var hideOnComplete:Bool = false;

  // Global pause. All Game Objects using this Animation instance are impacted by this property.
  public var paused:Bool = false;

  public function new(_manager:AnimationManager, _key:String, config:AnimationConfig) {
    manager = _manager;
    key = _key;

    frames = getFrames(manager.textureManager, config.frames, null);

    frameRate = (config.frameRate != null) ? config.frameRate : null;
    duration = (config.duration != null) ? config.duration : null;

		repeat = (config.repeat != null) ? config.repeat : 0;
    
    // TODO: get rest of config

    calculateDuration(this, getTotalFrames(), duration, frameRate);

    manager.on('PAUSE_ALL', pause);
    manager.on('RESUME_ALL', resume);
  }

  /**
   * Gets the total number of frames in this animation.
   */
  public function getTotalFrames() {
    return frames.length;
  }

  /**
   * Calculates the duration, frame rate and msPerFrame values.
   */
  public function calculateDuration(target:Dynamic, totalFrames:Float, duration:Float, frameRate:Float) {
    if (duration == null && frameRate == null) {
			// No duration or frameRate given, use default frameRate of 24fps
			target.frameRate = 24;
			target.duration = (24 / totalFrames) * 1000;
    } else if (duration != null && frameRate == null) {
			// Duration given but no frameRate, so set the frameRate based on duration
			// I.e. 12 frames in the animation, duration = 4000 ms
			// So frameRate is 12 / (4000 / 1000) = 3 fps
      target.duration = duration;
			target.frameRate = totalFrames / (duration / 1000);
    } else {
			// frameRate given, derive duration from it (even if duration also specified)
			// I.e. 15 frames in the animation, frameRate = 30 fps
			// So duration is 15 / 30 = 0.5 * 1000 (half a second, or 500ms)
			target.frameRate = frameRate;
      target.duration = (totalFrames / frameRate) * 1000;
    }

    target.msPerFrame = 1 / target.frameRate;
  }

  /**
   * Add frames to the end of the animation.
   */
	public function addFrame(config:Array<{key:String, frame:String}>) {
    return addFrameAt(frames.length, config);
  }

  /**
   * Add frame/s into the animation.
   */
  public function addFrameAt(index:Int, config:Array<{ key:String, frame:String }>) {
    var newFrames = getFrames(manager.textureManager, config);

    if (newFrames.length > 0) {
      if (index == 0) {
        frames = newFrames.concat(frames);
      } else if (index == frames.length) {
        frames = frames.concat(newFrames);
      } else {
        var pre = frames.slice(0, index);
        var post = frames.slice(index, frames.length);

        frames = pre.concat(newFrames);
        frames = frames.concat(post);
      }

      updateFrameSequence();
    }

    return this;
  }

  /**
   * Check if the given frame index is valid.
   */
  public function checkFrame(index:Int) {
    return (index >= 0 && index < frames.length);
  }

  /**
   * Called internally when this Animation first starts to play.
   * Sets the accumulator and nextTick properties.
   */
  public function getFirstTick(comp:AnimationState) {
    // When is the first update due?
    comp.accumulator = 0;

    comp.nextTick = comp.msPerFrame + comp.currentFrame.duration;
  }

  /**
   * Returns the AnimationFrame at the provided index
   */
  public function getFrameAt(index:Int) {
    return frames[index];
  }

	/**
	 * Creates AnimationFrame instances based on the given string.
   */
	public function getFramesFromString(textureManager:TextureManager, textureKey:String, ?sortFrames:Bool = true) {
		var frames:Array<{key:String, frame:String}> = [];
    
    var texture = textureManager.get(textureKey);
    var frameKeys = texture.getFrameNames();

    if (sortFrames) {
      // TODO:
    }

    for (frame in frameKeys) {
      frames.push({ key: textureKey, frame: frame });
    }

    return getFrames(textureManager, frames, textureKey);
  }

  /**
   * Creates AnimationFrame instances based on the given frame data.
   */
	public function getFrames(textureManager:TextureManager, _frames:Array<Dynamic>, ?defaultTextureKey:String) {
    var out:Array<AnimationFrame> = [];

    var prev:AnimationFrame = null;
    var animationFrame:AnimationFrame = null;

		for (i in 0..._frames.length) {
			var item = _frames[i];
      var key = (item.key != null) ? item.key : defaultTextureKey;

      if (key == null) continue;

      // Could be an integer or a string
      var frame:Dynamic = (item.frame != null) ? item.frame : 0;

      // The actual texture frame
      var textureFrame = textureManager.getFrame(key, frame);

      animationFrame = new AnimationFrame(key, frame, i, textureFrame);

      animationFrame.duration = (item.duration != null) ? item.duration : 0;

      animationFrame.isFirst = (prev == null);

      // The previously created animationFrame
      if (prev != null) {
        prev.nextFrame = animationFrame;

        animationFrame.prevFrame = prev;
      }

      out.push(animationFrame);

      prev = animationFrame;
    }

		if (out.length > 0) {
      animationFrame.isLast = true;
      
      // Link them end-to-end, so they loop
      animationFrame.nextFrame = out[0];

      out[0].prevFrame = animationFrame;

      // Generate the progress data
      var slice = 1 / (out.length - 1);

      for (i in 0...out.length) {
        out[i].progress = i * slice;
      }
    }

    return out;
  }

  /**
   * Called internally. Sets the accumulator and nextTick values of the current Animation.
   */
	public function getNextTick(comp:AnimationState) {
    comp.accumulator -= comp.nextTick;

		comp.nextTick = comp.msPerFrame + comp.currentFrame.duration;
  }

  /**
   * Returns the frame closest to the given progress value between 0 and 1.
   */
  public function getFrameByProgress(value:Float) {
    value = CMath.clamp(value, 0, 1);

    return ArrayUtils.findClosestInSortedFromKey(value, frames, 'progress');
  }

  /**
   * Advance the animation frame.
   */
	public function nextFrame(comp:AnimationState) {
    var frame = comp.currentFrame;

    if (frame.isLast) {
      // We're at the end of te animtion

      // Yoyo? (happens before repeat)
      if (comp.yoyo) {
        handleYoyoFrame(comp);
      } else if (comp.repeatCounter > 0) {
        // Repeat (happens before complete)
        
        if (comp.inReverse && comp.forward) {
          comp.forward = false;
        } else {
          repeatAnimation(comp);
        }
      } else {
        comp.complete();
      }
    } else {
      updateAndGetNextTick(comp, frame.nextFrame);
    }
  }

  /**
   * Handle the yoyo functionality in nextFrame and previousFrame methods.
   */
	public function handleYoyoFrame(comp:AnimationState, ?isReverse:Bool = false) {
    if (comp.inReverse == !isReverse && comp.repeatCounter > 0) {
      if (comp.repeatDelay == 0 || comp.pendingRepeat) {
        comp.forward = isReverse;
      }

      repeatAnimation(comp);

      return;
    }

    if (comp.inReverse != isReverse && comp.repeatCounter == 0) {
      comp.complete();

      return;
    }

    comp.forward = isReverse;

    var frame = isReverse ? comp.currentFrame.nextFrame : comp.currentFrame.prevFrame;

    updateAndGetNextTick(comp, frame);
  }

  /**
   * Returns the animation last frame.
   */
  public function getLastFrame() {
    return frames[frames.length - 1];
  }

  /**
   * Called internally when the Animation is playing backwards.
   * Sets the previous frame, causing a yoyo, repeat, complete or update, accordingly.
   */
	public function previousFrame(comp:AnimationState) {
    var frame = comp.currentFrame;

    if (frame.isFirst) {
      // We're at the start of the animation
      if (comp.yoyo) {
        handleYoyoFrame(comp, true);
      } else if (comp.repeatCounter > 0) {
        if (comp.inReverse && !comp.forward) {
          repeatAnimation(comp);
        } else {
          // Repeat (happens before complete)
          comp.forward = true;

          repeatAnimation(comp);
        }
      } else {
        comp.complete();
      }
    } else {
      updateAndGetNextTick(comp, frame.prevFrame);
    }
  }

  /**
   * Update Frame and Wait next tick.
   */
	public function updateAndGetNextTick(comp:AnimationState, frame:AnimationFrame) {
    comp.setCurrentFrame(frame);

    getNextTick(comp);
  }

  /**
   * Removes the given AnimationFrame from this Animation instance.
   * This is a global action. Any Game Object using this Animation will be impacted by this change.
   */
  public function removeFrame(frame:AnimationFrame) {
    var index = frames.indexOf(frame);

    if (index != -1)
      removeFrameAt(index);

    return this;
  }

  /**
   * Removes a frame from the AnimationFrame array at the provided index
   * and updates the animation accordingly.
   */
  public function removeFrameAt(index:Int) {
    frames.splice(index, 1);

    updateFrameSequence();

    return this;
  }

  /**
   * Called internally during playback. Forces the animation to repeat, providing there are enough counts left
   * in the repeat counter.
   */
	public function repeatAnimation(comp:AnimationState) {
    if (comp._pendingStop == 2) {
      if (comp._pendingStopValue == 0) {
        comp.stop();
        return;
      } else {
        comp._pendingStopValue--;
      }
    }

    if (comp.repeatDelay > 0 && !comp.pendingRepeat) {
      comp.pendingRepeat = true;
      comp.accumulator -= comp.nextTick;
      comp.nextTick += comp.repeatDelay;
    } else {
      comp.repeatCounter--;

      if (comp.forward) {
        comp.setCurrentFrame(comp.currentFrame.nextFrame);
      } else {
        comp.setCurrentFrame(comp.currentFrame.prevFrame);
      }

      if (comp.isPlaying) {
        getNextTick(comp);

        comp.handleRepeat();
      }
    }
  }

  /**
   * Called internally whenever frames are added to, or removed from, this Animation.
   */
  public function updateFrameSequence() {
    var len = frames.length;
    var slice = 1 / (len - 1);

    var frame:AnimationFrame;

    for (i in 0...frames.length) {
      frame = frames[i];

      frame.index = i + 1;
      frame.isFirst = false;
      frame.isLast = false;
      frame.progress = i * slice;

      if (i == 0) {
        frame.isFirst = true;

        if (len == 1) {
          frame.isLast = true;
          frame.nextFrame = frame;
          frame.prevFrame = frame;
        } else {
          frame.isLast = false;
          frame.prevFrame = frames[len - 1];
          frame.nextFrame = frames[i + 1];
        }
      } else if (i == frames.length - 1 && frames.length > 1) {
        frame.isLast = true;
        frame.prevFrame = frames[len - 2];
        frame.nextFrame = frames[0];
      } else if (frames.length > 1) {
        frame.prevFrame = frames[i - 1];
        frame.nextFrame = frames[i + 1];
      }
    }

    return this;
  }

  /**
   * Pauses playback of this Animation. The paused state is set immediately.
   */
  public function pause() {
    paused = true;

    return this;
  }

  /**
   * Resumes playback of this Animation. The paused state is reset immediately.
   */
  public function resume() {
    paused = false;

    return this;
  }

  /**
   * Destroys this Animation instance. It will remove all event listeners,
   * remove this animation and its key from the global Animation Manager,
   * and then destroy all Animation Frames in turn.
   */
  public function destroy() {
    manager.removeListener('PAUSE_ALL', pause);
    manager.removeListener('RESUME_ALL', resume);

    manager.remove(key);

    for (i in 0...frames.length) {
      frames[i].destroy();
    }

    frames = [];

    manager = null;
  }
}