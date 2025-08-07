package nebula.input;

import nebula.input.WheelDeltaMode;

class WheelEvent {
  public var active = true;
  public function cancel() {
    this.active = false;
  }
  public function new(
    x: Int,
    y: Int,
    pageX: Int,
    pageY: Int,
    screenX: Int,
    screenY: Int,
    index: Int,
    deltaX: Float,
    deltaY: Float,
    deltaZ: Float,
    deltaMode: WheelDeltaMode,
    ev: Event
  ) {}
}
