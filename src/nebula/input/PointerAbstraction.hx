package nebula.input;

import nebula.math.Vector;
import nebula.input.PointerEvent;
import nebula.EventEmitter;
import nebula.input.PointerEventReceiver;
import nebula.math.GlobalCoordinates;
import nebula.Engine;

class PointerAbstraction {
  public var events = new EventEmitter<PointerEvents>();
  /**
   * The last position on the document this pointer was at. Can be `null` if pointer was never active.
   */
  public var lastPagePos: Null<Vector> = Vector.Zero;

  /**
   * The last position on the screen this pointer was at. Can be `null` if pointer was never active.
   */
  public var lastScreenPos: Null<Vector> = Vector.Zero;

  /**
   * The last position in the game world coordinates this pointer was at. Can be `null` if pointer was never active.
   */
  public var lastWorldPos: Null<Vector> = Vector.Zero;

  public function new() {
    this.on('move', this._onPointerMove);
    this.on('down', this._onPointerDown);
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

  /**
   * Called internally by excalibur to keep pointers up to date
   * @internal
   * @param engine
   */
  public function _updateWorldPosition(engine: Engine) {
    final coord = GlobalCoordinates.fromPagePosition(this.lastPagePos, engine);
    this.lastScreenPos = coord.screenPos;
    this.lastWorldPos = coord.worldPos;
  }

  private function _onPointerMove(ev: PointerEvent): Void {
    this.lastPagePos = new Vector(ev.pagePos.x, ev.pagePos.y);
    this.lastScreenPos = new Vector(ev.screenPos.x, ev.screenPos.y);
    this.lastWorldPos = new Vector(ev.worldPos.x, ev.worldPos.y);
  };

  private function _onPointerDown(ev: PointerEvent): Void {
    this.lastPagePos = new Vector(ev.pagePos.x, ev.pagePos.y);
    this.lastScreenPos = new Vector(ev.screenPos.x, ev.screenPos.y);
    this.lastWorldPos = new Vector(ev.worldPos.x, ev.worldPos.y);
  };
}
