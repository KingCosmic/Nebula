package nebula.collision;

import nebula.math.Vector;

/**
 * An enum that describes the sides of an axis aligned box for collision
 */
enum ESide {
  None;
  Top;
  Bottom;
  Left;
  Right;
}

class Side {
  /**
   * Returns the opposite side from the current
   */
  static public function getOpposite(side: ESide): ESide {
    switch (side) {
      case ESide.Top:
        return ESide.Bottom;
      case ESide.Bottom:
        return ESide.Top;
      case ESide.Left:
        return ESide.Right;
      case ESide.Right:
        return ESide.Left;
      default:
        return ESide.None;
    }
  }

  /**
   * Given a vector, return the Side most in that direction
   */
  static public function fromDirection(direction: Vector): Side {
    if (Math.abs(direction.x) >= Math.abs(direction.y)) {
      if (direction.x <= 0) {
        return Side.Left;
      }

      return Side.Right;
    }

    if (direction.y <= 0) {
      return Side.Top;
    }

    return Side.Bottom;
  }
}
