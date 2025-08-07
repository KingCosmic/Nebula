package nebula.graphics.context;

import nebula.Color;
import nebula.util.RentalPool;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.graphics.context.Material;

class ContextState implements ExcaliburGraphicsContextState {
  var opacity: Float = 1;
  var z: Int = 0;
  var tint: Null<Color> = Color.White;
  var material: Null<Material> = null;
}

class StateStack {
  private var _pool = new RentalPool<ContextState>(
    () -> new ContextState(),
    (s) -> {
      s.opacity = 1;
      s.z = 0;
      s.tint = Color.White;
      s.material = null;
      return s;
    },
    100
  );
  public var current: ExcaliburGraphicsContextState = this._pool.rent(true);
  private var _states: Array<ExcaliburGraphicsContextState> = [];

  private function _cloneState(dest: ContextState) {
    dest.opacity = this.current.opacity;
    dest.z = this.current.z;
    dest.tint = this.current.tint?.clone();
    dest.material = this.current.material; // TODO is this going to cause problems when cloning
    return dest;
  }

  public function save(): Void {
    this._states.push(this.current);
    this.current = this._cloneState(this._pool.rent());
  }

  public function restore(): Void {
    this._pool.restore(this.current);
    this.current = this._states.pop()!;
  }
}
