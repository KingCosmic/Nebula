package nebula.math;

/**
 * @module
 * Pseudo-Random Utility
 *
 * A pseudo-random utility to add seeded random support for help in
 * generating things like terrain or reproducible randomness. Uses the
 * [Mersenne Twister](https://en.wikipedia.org/wiki/Mersenne_Twister) algorithm.
 */

/**
 * 32-bit mask
 */
final BITMASK32: Int = 0xffffffff;
final initialSeed = Date.now();
var seedOffset = 0;

/**
 * Pseudo-random number generator following the Mersenne_Twister algorithm. Given a seed this generator will produce the same sequence
 * of numbers each time it is called.
 * See https://en.wikipedia.org/wiki/Mersenne_Twister for more details.
 * Uses the MT19937-32 (2002) implementation documented here http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html
 *
 * Api inspired by http://chancejs.com/# https://github.com/chancejs/chancejs
 */
class Random {
  // Separation point of one one word, the number of bits in the lower bitmask 0 <= r <= w-1
  private var _lowerMask: Int = 0x7fffffff; // 31 bits same as _r
  private var _upperMask: Int = 0x80000000; // 34 high bits

  // Word size, 64 bits
  private var _w: Int = 32;

  // Degree of recurrence
  private var _n: Int = 624;

  // Middle word, an offset used in the recurrence defining the series x, 1<=m<n
  private var _m: Int = 397;
  // coefficients of teh rational normal form twist matrix
  private var _a: Int = 0x9908b0df;

  // tempering bit shifts and masks
  private var _u: Int = 11;
  private var _s: Int = 7;
  private var _b: Int = 0x9d2c5680;
  private var _t: Int = 15;
  private var _c: Int = 0xefc60000;
  private var _l: Int = 18;
  private var _f: Int = 1812433253;

  private var _mt: Array<Int>;

  private var _index: Int;
  private var _seed: Int;

  /**
   * If no seed is specified, the Date.now() is used
   */
  public function new(?seed: Int) {
    this._mt = new Array<Int>(this._n);
    // need to mask to support higher bit machines

    this._mt[0] = (seed || initialSeed + seedOffset++) >>> 0;
    this._seed = this._mt[0];

    for (i in 1...this._n) {
      final s = this._mt[i - 1] ^ (this._mt[i - 1] >>> (this._w - 2));
      // numbers are bigger than the JS max safe int, add in 16-bit chunks to prevent IEEE rounding errors on high bits
      this._mt[i] = (((this._f * ((s & 0xffff0000) >>> 16)) << 16) + this._f * (s & 0xffff) + i) >>> 0;
    }
    this._index = this._n;
  }

  /**
   * Apply the twist
   */
  private function _twist():Void {
    final mag01 = [0x0, this._a];
    var y:Int = 0;
    var i:Int = 0;

    while (i < this._n - this._m) {
      y = (this._mt[i] & this._upperMask) | (this._mt[i + 1] & this._lowerMask);
      this._mt[i] = this._mt[i + this._m] ^ (y >>> 1) ^ (mag01[y & 0x1] & BITMASK32);
      i++;
    }

    while (i < this._n - 1) {
      y = (this._mt[i] & this._upperMask) | (this._mt[i + 1] & this._lowerMask);
      this._mt[i] = this._mt[i + (this._m - this._n)] ^ (y >>> 1) ^ (mag01[y & 0x1] & BITMASK32);
      i++;
    }

    y = (this._mt[this._n - 1] & this._upperMask) | (this._mt[0] & this._lowerMask);
    this._mt[this._n - 1] = this._mt[this._m - 1] ^ (y >>> 1) ^ (mag01[y & 0x1] & BITMASK32);

    this._index = 0;
  }

  /**
   * Return next 32 bit integer number in sequence
   */
  public function nextInt(): Int {
    if (this._index >= this._n) {
      this._twist();
    }

    var y = this._mt[this._index++];

    y ^= y >>> this._u;
    y ^= (y << this._s) & this._b;
    y ^= (y << this._t) & this._c;
    y ^= y >>> this._l;

    return y >>> 0;
  }

  /**
   * Return a random floating point number between [0, 1)
   */
  public function next(): Float {
    return this.nextInt() * (1.0 / 4294967296.0); // divided by 2^32
  }

  /**
   * Return a random floating point in range [min, max) min is included, max is not included
   */
  public function floating(min: Float, max: Float): Float {
    return (max - min) * this.next() + min;
  }

  /**
   * Return a random integer in range [min, max] min is included, max is included.
   * Implemented with rejection sampling, see https://medium.com/@betable/tifu-by-using-math-random-f1c308c4fd9d#.i13tdiu5a
   */
  public function integer(min: Int, max: Int): Int {
    return Math.floor((max - min + 1) * this.next() + min);
  }

  /**
   * Returns true or false randomly with 50/50 odds by default.
   * By default the likelihood of returning a true is .5 (50%).
   * @param likelihood takes values between [0, 1]
   */
  public function bool(likelihood: Float = 0.5): Bool {
    return this.next() <= likelihood;
  }

  /**
   * Returns one element from an array at random
   */
  public function pickOne<T>(array: Array<T>): T {
    return array[this.integer(0, array.length - 1)];
  }

  /**
   * Returns a new array random picking elements from the original
   * @param array Original array to pick from
   * @param numPicks can be any positive number
   * @param allowDuplicates indicates whether the returned set is allowed duplicates (it does not mean there will always be duplicates
   * just that it is possible)
   */
  public function pickSet<T>(array: Array<T>, numPicks: Int, allowDuplicates: Bool = false): Array<T> {
    if (allowDuplicates) {
      return this._pickSetWithDuplicates(array, numPicks);
    } else {
      return this._pickSetWithoutDuplicates(array, numPicks);
    }
  }

  /**
   * Returns a new array randomly picking elements in the original (not reused)
   * @param array Array to pick elements out of
   * @param numPicks must be less than or equal to the number of elements in the array.
   */
  private function _pickSetWithoutDuplicates<T>(array: Array<T>, numPicks: Int): Array<T> {
    if (numPicks > array.length || numPicks < 0) {
      throw new Error('Invalid number of elements to pick, must pick a value 0 < n <= length');
    }
    if (numPicks == array.length) {
      return array;
    }

    final result: Array<T> = new Array<T>(numPicks);
    var currentPick = 0;
    final tempArray = array.slice(0);
    while (currentPick < numPicks) {
      final index = this.integer(0, tempArray.length - 1);
      result[currentPick++] = tempArray[index];
      tempArray.splice(index, 1);
    }

    return result;
  }

  /**
   * Returns a new array random picking elements from the original allowing duplicates
   * @param array Array to pick elements out of
   * @param numPicks can be any positive number
   */
  private function _pickSetWithDuplicates<T>(array: Array<T>, numPicks: Int): Array<T> {
    // Typescript numbers are all floating point, so do we add check for int? (or floor the input?)
    if (numPicks < 0) {
      throw new Error('Invalid number of elements to pick, must pick a value 0 <= n < MAX_INT');
    }
    final result = new Array<T>(numPicks);
    for (i in 0...numPicks) {
      result[i] = this.pickOne(array);
    }
    return result;
  }

  /**
   * Returns a new array that has its elements shuffled. Using the Fisher/Yates method
   * https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
   */
  public function shuffle<T>(array: Array<T>): Array<T> {
    final tempArray = array.slice(0);
    var swap: T;
    for (i in 0...tempArray.length) {
      final randomIndex = this.integer(i, tempArray.length - 1);
      swap = tempArray[i];
      tempArray[i] = tempArray[randomIndex];
      tempArray[randomIndex] = swap;
    }

    return tempArray;
  }

  /**
   * Generate a list of random integer numbers
   * @param length the length of the final array
   * @param min the minimum integer number to generate inclusive
   * @param max the maximum integer number to generate inclusive
   */
  public function range(length: Int, min: Int, max: Int): Array<Int> {
    final result: Array<Int> = new Array(length);
    for (i in 0...length) {
      result[i] = this.integer(min, max);
    }
    return result;
  }

  /**
   * Returns the result of a d4 dice roll
   */
  public function d4() {
    return this.integer(1, 4);
  }

  /**
   * Returns the result of a d6 dice roll
   */
  public function d6() {
    return this.integer(1, 6);
  }

  /**
   * Returns the result of a d8 dice roll
   */
  public function d8() {
    return this.integer(1, 8);
  }

  /**
   * Returns the result of a d10 dice roll
   */
  public function d10() {
    return this.integer(1, 10);
  }

  /**
   * Returns the result of a d12 dice roll
   */
  public function d12() {
    return this.integer(1, 12);
  }

  /**
   * Returns the result of a d20 dice roll
   */
  public function d20() {
    return this.integer(1, 20);
  }

  public var seed(get, never): Int;
  function get_seed() {
    return this._seed;
  }
}
