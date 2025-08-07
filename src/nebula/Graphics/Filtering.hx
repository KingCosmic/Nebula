package nebula.graphics;

/**
 * Describes the different image filtering modes
 */
enum ImageFiltering {
  /**
   * Pixel is useful when you do not want smoothing aka antialiasing applied to your graphics.
   *
   * Useful for Pixel art aesthetics.
   */
  Pixel;

  /**
   * Blended is useful when you have high resolution artwork and would like it blended and smoothed
   */
  Blended;
}

class Filtering {
 /**
   * Parse the image filtering attribute value, if it doesn't match returns null
   */
  public static function parseImageFiltering(val: String): Null<ImageFiltering> {
    switch (val) {
      case 'Pixel':
        return ImageFiltering.Pixel;
      case 'Blended':
        return ImageFiltering.Blended;
      default:
        return null;
    }
  } 
}
