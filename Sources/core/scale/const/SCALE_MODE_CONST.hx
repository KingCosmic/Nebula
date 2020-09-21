package core.scale.const;

class SCALE_MODE_CONST {
  /**
   * No scaling happens at all. The canvas is set to the size given in the game config and Phaser doesn't change it
   * again from that point on. If you change the canvas size, either via CSS, or directly via code, then you need
   * to call the Scale Managers `resize` method to give the new dimensions, or input events will stop working.
   */
  static public var NONE = 0;

  // The height is automatically adjusted based on the width.
  static public var WIDTH_CONTROLS_HEIGHT = 1;

  // The width is automatically adjusted based on the height.
  static public var HEIGHT_CONTROLS_WIDTH = 2;

  /**
   * The width and height are automatically adjusted to fit inside the given target area,
   * while keeping the aspect ratio. Depending on the aspect ratio there may be some space
   * inside the area which is not covered.
   */
  static public var FIT = 3;

  /**
   * The width and height are automatically adjusted to make the size cover the entire target
   * area while keeping the aspect ratio. This may extend further out than the target size.
   */
  static public var ENVELOP = 4;

  // The Canvas is resized to fit all available _parent_ space, regardless of aspect ratio.
  static public var RESIZE = 5;
}