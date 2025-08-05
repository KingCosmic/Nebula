package nebula.Director;

import nebula.Util.Audio;
import nebula.Util.Future;
import nebula.Util.Util;

import nebula.Resources.Sound.Sound;

import nebula.Engine;

import nebula.Color;

import Nebul.EventEmitter;

import nebula.Interfaces.Loadable;

import nebula.Graphics.Canvas;
import nebula.Graphics.Filtering;

import nebula.Math.Util;

interface DefaultLoaderOptions {
  /**
   * List of loadables
   */
  loadables?: Loadable<any>[];
}

type LoaderEvents = {
  // Add event types here
  beforeload: void;
  afterload: void;
  useraction: void;
  loadresourcestart: Loadable<any>;
  loadresourceend: Loadable<any>;
};

var LoaderEvents = {
  // Add event types here
  BeforeLoad: 'beforeload',
  AfterLoad: 'afterload',
  UserAction: 'useraction',
  LoadResourceStart: 'loadresourcestart',
  LoadResourceEnd: 'loadresourceend'
};

type LoaderConstructor = new (...args: any[]) => DefaultLoader;
/**
 * Returns true if the constructor is for an Excalibur Loader
 */
function isLoaderConstructor(x: any): x is LoaderConstructor {
  return !!x?.prototype && !!x?.prototype?.constructor?.name;
}

class DefaultLoader implements Loadable<Loadable<any>[]> {
  public data!: Loadable<any>[];
  public events = new EventEmitter<LoaderEvents>();
  public canvas: Canvas = new Canvas({
    filtering: ImageFiltering.Blended,
    smoothing: true,
    cache: false,
    draw: this.onDraw.bind(this)
  });
  private _resources: Loadable<any>[] = [];
  public get resources(): readonly Loadable<any>[] {
    return this._resources;
  }
  private _numLoaded: Int = 0;
  public engine!: Engine;

  /**
   * @param options Optionally provide the list of resources you want to load at constructor time
   */
  constructor(options?: DefaultLoaderOptions) {
    if (options && options.loadables?.length) {
      this.addResources(options.loadables);
    }
  }

  /**
   * Called by the engine before loading
   * @param engine
   */
  public onInitialize(engine: Engine) {
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
  public async onUserAction(): Promise<void> {
    return await Promise.resolve();
  }

  /**
   * Overridable lifecycle method, called directly before loading starts
   */
  public async onBeforeLoad() {
    // override me
  }

  /**
   * Overridable lifecycle method, called after loading has completed
   */
  public async onAfterLoad() {
    // override me
    await delay(500, this.engine.clock); // avoid a flicker
  }

  /**
   * Add a resource to the loader to load
   * @param loadable  Resource to add
   */
  public addResource(loadable: Loadable<any>) {
    this._resources.push(loadable);
  }

  /**
   * Add a list of resources to the loader to load
   * @param loadables  The list of resources to load
   */
  public addResources(loadables: Loadable<any>[]) {
    var i = 0;
    var len = loadables.length;

    for (i; i < len; i++) {
      this.addResource(loadables[i]);
    }
  }

  public markResourceComplete(): void {
    this._numLoaded++;
  }

  /**
   * Returns the progress of the loader as a number between [0, 1] inclusive.
   */
  public get progress(): Float {
    var total = this._resources.length;
    return total > 0 ? clamp(this._numLoaded, 0, total) / total : 1;
  }

  /**
   * Returns true if the loader has completely loaded all resources
   */
  public isLoaded() {
    return this._numLoaded === this._resources.length;
  }

  private _totalTimeMs = 0;

  /**
   * Optionally override the onUpdate
   * @param engine
   * @param elapsed
   */
  onUpdate(engine: Engine, elapsed: Float): void {
    this._totalTimeMs += elapsed;
    // override me
  }

  /**
   * Optionally override the onDraw
   */
  onDraw(ctx: CanvasRenderingContext2D) {
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

  private _loadingFuture = new Future<void>();
  public areResourcesLoaded() {
    if (this._resources.length === 0) {
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
  public async load(): Promise<Loadable<any>[]> {
    await this.onBeforeLoad();
    this.events.emit('beforeload');
    this.canvas.flagDirty();

    await Promise.all(
      this._resources.map(async (r) => {
        this.events.emit('loadresourcestart', r);
        await r.load().finally(() => {
          // capture progress
          this._numLoaded++;
          this.canvas.flagDirty();
          this.events.emit('loadresourceend', r);
        });
      })
    );

    // Wire all sound to the engine
    for (var resource of this._resources) {
      if (resource instanceof Sound) {
        resource.wireEngine(this.engine);
      }
    }

    this._loadingFuture.resolve();
    this.canvas.flagDirty();
    // Unlock browser AudioContext in after user gesture
    // See: https://github.com/excaliburjs/Excalibur/issues/262
    // See: https://github.com/excaliburjs/Excalibur/issues/1031
    await this.onUserAction();
    this.events.emit('useraction');
    await WebAudio.unlock();

    await this.onAfterLoad();
    this.events.emit('afterload');
    return (this.data = this._resources);
  }

  public emit<TEventName extends EventKey<LoaderEvents>>(eventName: TEventName, event: LoaderEvents[TEventName]): void;
  public emit(eventName: String, event?: any): void;
  public emit<TEventName extends EventKey<LoaderEvents> | String>(eventName: TEventName, event?: any): void {
    this.events.emit(eventName, event);
  }

  public on<TEventName extends EventKey<LoaderEvents>>(eventName: TEventName, handler: Handler<LoaderEvents[TEventName]>): Subscription;
  public on(eventName: String, handler: Handler<unknown>): Subscription;
  public on<TEventName extends EventKey<LoaderEvents> | String>(eventName: TEventName, handler: Handler<any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public once<TEventName extends EventKey<LoaderEvents>>(eventName: TEventName, handler: Handler<LoaderEvents[TEventName]>): Subscription;
  public once(eventName: String, handler: Handler<unknown>): Subscription;
  public once<TEventName extends EventKey<LoaderEvents> | String>(eventName: TEventName, handler: Handler<any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public off<TEventName extends EventKey<LoaderEvents>>(eventName: TEventName, handler: Handler<LoaderEvents[TEventName]>): void;
  public off(eventName: String, handler: Handler<unknown>): void;
  public off(eventName: String): void;
  public off<TEventName extends EventKey<LoaderEvents> | String>(eventName: TEventName, handler?: Handler<any>): void {
    (this.events as any).off(eventName, handler);
  }
}
