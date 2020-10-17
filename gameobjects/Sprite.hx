package core.gameobjects;

import core.cameras.Camera;
import core.gameobjects.RenderableGameObject;
import core.animations.AnimationState;
import core.animations.AnimationFrame;
import core.scene.Scene;

/**
 * A Sprite Game Object.
 *
 * A Sprite Game Object is used for the display of both static and animated images in your game.
 * Sprites can have input events and physics bodies. They can also be tweened, tinted, scrolled
 * and animated.
 *
 * The main difference between a Sprite and an Image Game Object is that you cannot animate Images.
 * As such, Sprites take a fraction longer to process and have a larger API footprint due to the Animation
 * Component. If you do not require animation then you can safely use Images to replace Sprites in all cases.
 */
class Sprite extends RenderableGameObject {
  /**
   * The Animation State component of this Sprite.
   *
   * This component provides features to apply animations to this Sprite.
   * It is responsible for playing, loading, queuing animations for later playback,
   * mixing between animations and setting the current animation frame to this Sprite.
   */
  public var anims:AnimationState;

  public function new(scene:Scene, x:Float, y:Float, texture:String, ?frame:Any) {
    super(scene, 'Sprite');

    _crop = resetCropObject();

    anims = new AnimationState(this);

    setTexture(texture, frame);
    setPosition(x, y);
    setSizeToFrame();
    setOriginFromFrame();
    initPipeline();

    on('ADDED_TO_SCENE', addedToScene);
    on('REMOVED_FROM_SCENE', removedFromScene);
  }

  override public function addedToScene() {
    scene.sys.updateList.add(this);
  }

  override public function removedFromScene() {
    scene.sys.updateList.remove(this);
  }

  /**
   * Update this Sprite's animations.
   */
  override public function preUpdate(time:Float, delta:Float) {
    anims.update(time, delta);
  }

	/**
	 * Renders this Game Object with the Canvas Renderer to the given Camera.
	 * The object will not render if any of its renderFlags are set or it is being actively filtered out by the Camera.
	 * This method should not be called directly. It is a utility function of the Render module.
	 */
	override public function render(renderer:Renderer, camera:Camera) {
		renderer.batchImage(this, frame, camera);
	}

  /**
   * Start playing the given animation on this Sprite.
   *
   * Animations in Phaser can either belong to the global Animation Manager, or specifically to this Sprite.
   *
   * The benefit of a global animation is that multiple Sprites can all play the same animation, without
   * having to duplicate the data. You can just create it once and then play it on any Sprite.
   *
   * The following code shows how to create a global repeating animation. The animation will be created
   * from all of the frames within the sprite sheet that was loaded with the key 'muybridge':
   *
   * ```javascript
   * var config = {
   *     key: 'run',
   *     frames: 'muybridge',
   *     frameRate: 15,
   *     repeat: -1
   * };
   *
   * //  This code should be run from within a Scene:
   * this.anims.create(config);
   * ```
   *
   * However, if you wish to create an animation that is unique to this Sprite, and this Sprite alone,
   * you can call the `Animation.create` method instead. It accepts the exact same parameters as when
   * creating a global animation, however the resulting data is kept locally in this Sprite.
   *
   * With the animation created, either globally or locally, you can now play it on this Sprite:
   *
   * ```javascript
   * this.add.sprite(x, y).play('run');
   * ```
   *
   * Alternatively, if you wish to run it at a different frame rate, for example, you can pass a config
   * object instead:
   *
   * ```javascript
   * this.add.sprite(x, y).play({ key: 'run', frameRate: 24 });
   * ```
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   *
   * If you need a Sprite to be able to play both local and global animations, make sure they don't
   * have conflicting keys.
   *
   * See the documentation for the `PlayAnimationConfig` config object for more details about this.
   *
   * Also, see the documentation in the Animation Manager for further details on creating animations.
   */
  public function play(key:String, ?ignoreIfPlaying:Bool) {
    return anims.play(key, ignoreIfPlaying);
  }

  /**
   * Start playing the given animation on this Sprite, in reverse.
   *
   * Animations in Phaser can either belong to the global Animation Manager, or specifically to this Sprite.
   *
   * The benefit of a global animation is that multiple Sprites can all play the same animation, without
   * having to duplicate the data. You can just create it once and then play it on any Sprite.
   *
   * The following code shows how to create a global repeating animation. The animation will be created
   * from all of the frames within the sprite sheet that was loaded with the key 'muybridge':
   *
   * ```javascript
   * var config = {
   *     key: 'run',
   *     frames: 'muybridge',
   *     frameRate: 15,
   *     repeat: -1
   * };
   *
   * //  This code should be run from within a Scene:
   * this.anims.create(config);
   * ```
   *
   * However, if you wish to create an animation that is unique to this Sprite, and this Sprite alone,
   * you can call the `Animation.create` method instead. It accepts the exact same parameters as when
   * creating a global animation, however the resulting data is kept locally in this Sprite.
   *
   * With the animation created, either globally or locally, you can now play it on this Sprite:
   *
   * ```javascript
   * this.add.sprite(x, y).playReverse('run');
   * ```
   *
   * Alternatively, if you wish to run it at a different frame rate, for example, you can pass a config
   * object instead:
   *
   * ```javascript
   * this.add.sprite(x, y).playReverse({ key: 'run', frameRate: 24 });
   * ```
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   *
   * If you need a Sprite to be able to play both local and global animations, make sure they don't
   * have conflicting keys.
   *
   * See the documentation for the `PlayAnimationConfig` config object for more details about this.
   *
   * Also, see the documentation in the Animation Manager for further details on creating animations.
   */
  public function playReverse(key:String, ?ignoreIfPlaying:Bool) {
    return anims.playReverse(key, ignoreIfPlaying);
  }

  /**
   * Waits for the specified delay, in milliseconds, then starts playback of the given animation.
   *
   * If the animation _also_ has a delay value set in its config, it will be **added** to the delay given here.
   *
   * If an animation is already running and a new animation is given to this method, it will wait for
   * the given delay before starting the new animation.
   *
   * If no animation is currently running, the given one begins after the delay.
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   */
  public function playAfterDelay(key:String, delay:Float) {
    return anims.playAfterDelay(key, delay);
  }

  /**
   * Waits for the current animation to complete the `repeatCount` number of repeat cycles, then starts playback
   * of the given animation.
   *
   * You can use this to ensure there are no harsh jumps between two sets of animations, i.e. going from an
   * idle animation to a walking animation, by making them blend smoothly into each other.
   *
   * If no animation is currently running, the given one will start immediately.
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   */
  public function playAfterRepeat(key:String, ?repeatCount:Int) {
    return anims.playAfterRepeat(key, repeatCount);
  }

  /**
   * Sets an animation, or an array of animations, to be played immediately after the current one completes or stops.
   *
   * The current animation must enter a 'completed' state for this to happen, i.e. finish all of its repeats, delays, etc,
   * or have the `stop` method called directly on it.
   *
   * An animation set to repeat forever will never enter a completed state.
   *
   * You can chain a new animation at any point, including before the current one starts playing, during it,
   * or when it ends (via its `animationcomplete` event).
   *
   * Chained animations are specific to a Game Object, meaning different Game Objects can have different chained
   * animations without impacting the animation they're playing.
   *
   * Call this method with no arguments to reset all currently chained animations.
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   */
  public function chain(key:Array<Any>) {
    return anims.chain(key);
  }

  /**
   * Immediately stops the current animation from playing and dispatches the `ANIMATION_STOP` events.
   *
   * If no animation is playing, no event will be dispatched.
   *
   * If there is another animation queued (via the `chain` method) then it will start playing immediately.
   */
  public function stop() {
    return anims.stop();
  }

  /**
   * Stops the current animation from playing after the specified time delay, given in milliseconds.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   */
  public function stopAfterDelay(delay:Float) {
    return anims.stopAfterDelay(delay);
  }

  /**
   * Stops the current animation from playing after the given number of repeats.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   */
  public function stopAfterRepeat(?repeatCount:Int) {
    return anims.stopAfterRepeat(repeatCount);
  }

  /**
   * Stops the current animation from playing when it next sets the given frame.
   * If this frame doesn't exist within the animation it will not stop it from playing.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   */
  public function stopOnFrame(frame:AnimationFrame) {
    return anims.stopOnFrame(frame);
  }

  /**
   * Handles the pre-destroy step for the Sprite, which removes the Animation component.
   */
  override public function preDestroy() {
    anims.destroy();

    anims = null;
  }
}