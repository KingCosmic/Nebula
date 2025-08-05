package nebula.Events;

import nebula.Math.GlobalCoordinates;
import nebula.Input.WheelDeltaMode;

import nebula.Events.ExEvent;

abstract class PointerEvent extends ExEvent<'down' | 'up' | 'move' | 'cancel'> {
  public function new(
    public pointerId: Int,
    public coordinates: GlobalCoordinates,
    public nativeEvent: Event
  ) {
    super();
  }
}
class PointerUp extends PointerEvent {
  public readonly type = 'up';
}
class PointerDown extends PointerEvent {
  public readonly type = 'down';
}
class PointerMove extends PointerEvent {
  public readonly type = 'move';
}
class PointerCancel extends PointerEvent {
  public readonly type = 'cancel';
}

class Wheel extends ExEvent<'wheel'> {
  public readonly type = 'wheel';
  public function new(
    public x: Int,
    public y: Int,
    public pageX: Int,
    public pageY: Int,
    public screenX: Int,
    public screenY: Int,
    public index: Int,
    public deltaX: Float,
    public deltaY: Float,
    public deltaZ: Float,
    public deltaMode: WheelDeltaMode,
    public ev: Event
  ) {
    super();
  }
}
