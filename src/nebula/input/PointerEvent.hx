package nebula.input;

import nebula.math.GlobalCoordinates;
import nebula.math.Vector;

import nebula.input.PointerButton;
import nebula.input.PointerType;

class PointerEvent {
  public var active = true;
  public function cancel() {
    this.active = false;
  }

  public var pagePos(get, never): Vector;
  function get_pagePos(): Vector {
    return this.coordinates.pagePos;
  }

  public var screenPos(get, never): Vector;
  function get_screenPos(): Vector {
    return this.coordinates.screenPos;
  }

  public var worldPos(get, never): Vector;
  function get_worldPos(): Vector {
    return this.coordinates.worldPos;
  }

  public function new(
    type: String,
    pointerId: Int,
    button: PointerButton,
    pointerType: PointerType,
    coordinates: GlobalCoordinates,
    nativeEvent: Event
  ) {}
}
