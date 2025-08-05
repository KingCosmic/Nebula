package nebula.Util;

class RentalPool<T> {
  private var _pool: Array<T> = [];
  private var _size: Int = 0;
  public function new(
    builder: () -> T,
    cleaner: (used: T) -> T,
    preAllocate: Int = 1
  ) {
    this.grow(preAllocate);
  }

  /**
   * Grow the pool size by an amount
   * @param amount
   */
  function grow(amount: Int): Void {
    if (amount > 0) {
      this._size += amount;
      for (let i = 0; i < amount; i++) {
        this._pool.push(this.builder());
      }
    }
  }

  /**
   * Rent an object from the pool, optionally clean it. If not cleaned previous state may be set.
   *
   * The pool will automatically double if depleted
   * @param clean
   */
  function rent(clean: Bool = false): T {
    if (this._pool.length == 0) {
      this.grow(this._size);
    }

    return clean ? this.cleaner(this._pool.pop()) : this._pool.pop();
  }

  /**
   * Return an object to the pool
   * @param object
   */
  function return(object: T): Void {
    this._pool.push(object);
  }
}
