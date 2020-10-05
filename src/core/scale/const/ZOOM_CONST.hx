package core.scale.const;

/**
 * Phaser Scale Manager constants for zoom modes.
 * 
 * To find out what each mode does please see [Phaser.Scale.Zoom]{@link Phaser.Scale.Zoom}.
 */
class ZoomConst {
  // The game canvas will not be zoomed by Phaser.
  static public var NO_ZOOM = 1;

  // The game canvas will be 2x zoomed by Phaser.
  static public var ZOOM_2X = 2;

  // The game canvas will be 4x zoomed by Phaser.
  static public var ZOOM_4X = 4;

  /**
   * Calculate the zoom value based on the maximum multiplied game size that will
   * fit into the parent, or browser window if no parent is set.
   */
  static public var MAX_ZOOM = -1;
}