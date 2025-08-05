package nebula.Graphics.Context;

import nebula.Color;
import nebula.Util.RentalPool;
import nebula.Graphics.Context.ExcaliburGraphicsContext;
import nebula.Graphics.Context.Material;

class ContextState implements ExcaliburGraphicsContextState {
  opacity: Float = 1;
  z: Int = 0;
  tint: Null<Color> = Color.White;
  material: Null<Material> = null;
}

class StateStack {
  private _pool = new RentalPool<ContextState>(
    () => new ContextState(),
    (s) => {
      s.opacity = 1;
      s.z = 0;
      s.tint = Color.White;
      s.material = null;
      return s;
    },
    100
  );
  public current: ExcaliburGraphicsContextState = this._pool.rent(true);
  private _states: ExcaliburGraphicsContextState[] = [];

  private _cloneState(dest: ContextState) {
    dest.opacity = this.current.opacity;
    dest.z = this.current.z;
    dest.tint = this.current.tint?.clone();
    dest.material = this.current.material; // TODO is this going to cause problems when cloning
    return dest;
  }

  public save(): Void {
    this._states.push(this.current);
    this.current = this._cloneState(this._pool.rent());
  }

  public restore(): Void {
    this._pool.return(this.current);
    this.current = this._states.pop()!;
  }
}
