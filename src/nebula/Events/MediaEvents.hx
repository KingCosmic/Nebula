package nebula.Events;

import nebula.Events;
import Nebual.Resources.Sound.Sound;
import nebula.Actor;
import nebula.Resources.Sound.WebAudioInstance;

class MediaEvent extends GameEvent<Sound> {
  /**
   * Media event cannot bubble
   */
  public set bubbles(_value: Bool) {
    // stubbed
  }
  /**
   * Media event cannot bubble
   */
  public get bubbles(): Bool {
    return false;
  }
  /**
   * Media event cannot bubble, so they have no path
   */
  protected get _path(): Actor[] {
    return null;
  }
  /**
   * Media event cannot bubble, so they have no path
   */
  protected set _path(_val: Actor[]) {
    // stubbed
  }

  constructor(
    public target: Sound,
    protected _name: String = 'MediaEvent'
  ) {
    super();
  }

  /**
   * Prevents event from bubbling
   */
  public stopPropagation() {
    /**
     * Stub
     */
  }
  /**
   * Action, that calls when event happens
   */
  public action() {
    /**
     * Stub
     */
  }
  /**
   * Propagate event further through event path
   */
  public propagate() {
    /**
     * Stub
     */
  }

  public layPath(_actor: Actor) {
    /**
     * Stub
     */
  }
}

class NativeSoundEvent extends MediaEvent {
  public function new(
    target: Sound,
    public track?: WebAudioInstance
  ) {
    super(target, 'NativeSoundEvent');
  }
}

class NativeSoundProcessedEvent extends MediaEvent {
  public data: String | AudioBuffer;

  public function new(
    target: Sound,
    private _processedData: String | AudioBuffer
  ) {
    super(target, 'NativeSoundProcessedEvent');

    this.data = this._processedData;
  }
}
