package nebula.director;

import nebula.util.Audio;
import nebula.util.Future;
import nebula.util.Util;

import nebula.resources.sound.Sound;

import nebula.Engine;

import nebula.Color;

import nebula.EventEmitter;

import nebula.interfaces.Loadable;

import nebula.graphics.Canvas;
import nebula.graphics.Filtering;

import nebula.math.Util;

interface DefaultLoaderOptions {
  /**
   * List of loadables
   */
  var loadables: Null<Array<Loadable<Any>>>;
}

typedef TLoaderEvents = {
  // Add event types here
  var beforeload: Null<Any>;
  var afterload: Null<Any>;
  var useraction: Null<Any>;
  var loadresourcestart: Loadable<Any>;
  var loadresourceend: Loadable<Any>;
};

var LoaderEvents = {
  // Add event types here
  BeforeLoad: 'beforeload',
  AfterLoad: 'afterload',
  UserAction: 'useraction',
  LoadResourceStart: 'loadresourcestart',
  LoadResourceEnd: 'loadresourceend'
};

class DefaultLoader implements Loadable<Array<Loadable<Any>>> {
  public var data: Array<Loadable<Any>>;
  public var events = new EventEmitter<LoaderEvents>();
  public var canvas: Canvas = new Canvas({
    filtering: ImageFiltering.Blended,
    smoothing: true,
    cache: false,
    draw: this.onDraw.bind(this)
  });
  private var _resources: Array<Loadable<Any>> = [];
  public var resources(get, never): Array<Loadable<Any>>;
  function get_resources(): Array<Loadable<Any>> {
    return this._resources;
  }
  private var _numLoaded: Int = 0;
  public var engine: Engine;

  /**
   * @param options Optionally provide the list of resources you want to load at constructor time
   */
  public function new(?options: DefaultLoaderOptions) {
    if (options && options.loadables.length) {
      this.addResources(options.loadables);
    }
  }

  /**
   * Called by the engine before loading
   * @param engine
   */
  public function onInitialize(engine: Engine) {
    this.engine = engine;
    this.canvas.width = this.engine.screen.resolution.width;
    this.canvas.height = this.engine.screen.resolution.height;
  }

  /**
   * Return a promise that resolves when the user interacts with the loading screen in some way, usually a click.
   *
   * It's important to implement this in order to unlock the audio context in the browser. Browsers automatically prevent
   * audio from playing until the user performs an action.
   *
   */
  public function onUserAction(): Any {
    return null;
  }

  /**
   * Overridable lifecycle method, called directly before loading starts
   */
  public function onBeforeLoad() {
    // override me
  }

  /**
   * Overridable lifecycle method, called after loading has completed
   */
  public function onAfterLoad() {
    // override me
    delay(500, this.engine.clock); // avoid a flicker
  }

  /**
   * Add a resource to the loader to load
   * @param loadable  Resource to add
   */
  public function addResource(loadable: Loadable<Any>) {
    this._resources.push(loadable);
  }

  /**
   * Add a list of resources to the loader to load
   * @param loadables  The list of resources to load
   */
  public function addResources(loadables: Array<Loadable<Any>>) {
    for (loadable in loadables) {
      this.addResource(loadable);
    }
  }

  public function markResourceComplete() {
    this._numLoaded++;
  }

  /**
   * Returns the progress of the loader as a number between [0, 1] inclusive.
   */
  public var progress(get, never): Float;
  function get_progress(): Float {
    var total = this._resources.length;
    return total > 0 ? clamp(this._numLoaded, 0, total) / total : 1;
  }

  /**
   * Returns true if the loader has completely loaded all resources
   */
  public function isLoaded() {
    return this._numLoaded == this._resources.length;
  }

  private var _totalTimeMs = 0;

  /**
   * Optionally override the onUpdate
   * @param engine
   * @param elapsed
   */
  function onUpdate(engine: Engine, elapsed: Float): Void {
    this._totalTimeMs += elapsed;
    // override me
  }

  /**
   * Optionally override the onDraw
   */
  function onDraw(ctx: Any) {
    var seconds = this._totalTimeMs / 1000;

    ctx.fillStyle = Color.Black.toRGBA();
    ctx.fillRect(0, 0, this.engine.screen.resolution.width, this.engine.screen.resolution.height);

    ctx.save();
    ctx.translate(this.engine.screen.resolution.width / 2, this.engine.screen.resolution.height / 2);
    var speed = seconds * 10;
    ctx.strokeStyle = 'white';
    ctx.lineWidth = 10;
    ctx.lineCap = 'round';
    ctx.arc(0, 0, 40, speed, speed + (Math.PI * 3) / 2);
    ctx.stroke();

    ctx.fillStyle = 'white';
    ctx.font = '16px sans-serif';
    var text = (this.progress * 100).toFixed(0) + '%';
    var textbox = ctx.measureText(text);
    var width = Math.abs(textbox.actualBoundingBoxLeft) + Math.abs(textbox.actualBoundingBoxRight);
    var height = Math.abs(textbox.actualBoundingBoxAscent) + Math.abs(textbox.actualBoundingBoxDescent);
    ctx.fillText(text, -width / 2, height / 2); // center
    ctx.restore();
  }

  private var _loadingFuture = new Future<Void>();
  public function areResourcesLoaded() {
    if (this._resources.length == 0) {
      // special case no resources mean loaded;
      return Promise.resolve();
    }
    return this._loadingFuture.promise;
  }

  /**
   * Not meant to be overridden
   *
   * Begin loading all of the supplied resources, returning a promise
   * that resolves when loading of all is complete AND the user has interacted with the loading screen
   */
  public function load(): Any {
    this.onBeforeLoad();
    this.events.emit('beforeload');
    this.canvas.flagDirty();

    Promise.all(
      this._resources.map((r) -> {
        this.events.emit('loadresourcestart', r);
        r.load().finally(() -> {
          // capture progress
          this._numLoaded++;
          this.canvas.flagDirty();
          this.events.emit('loadresourceend', r);
        });
      })
    );

    // Wire all sound to the engine
    for (resource in this._resources) {
      if (Std.isOfType(resource, Sound)) {
        resource.wireEngine(this.engine);
      }
    }

    this._loadingFuture.resolve();
    this.canvas.flagDirty();
    // Unlock browser AudioContext in after user gesture
    // See: https://github.com/excaliburjs/Excalibur/issues/262
    // See: https://github.com/excaliburjs/Excalibur/issues/1031
    this.onUserAction();
    this.events.emit('useraction');
    WebAudio.unlock();

    this.onAfterLoad();
    this.events.emit('afterload');
    return (this.data = this._resources);
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    this.events.off(eventName, handler);
  }
}
