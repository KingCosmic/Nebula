package nebula.Graphics;

/**
 * Describes the different image filtering modes
 */
enum ImageFiltering {
  /**
   * Pixel is useful when you do not want smoothing aka antialiasing applied to your graphics.
   *
   * Useful for Pixel art aesthetics.
   */
  Pixel = 'Pixel',

  /**
   * Blended is useful when you have high resolution artwork and would like it blended and smoothed
   */
  Blended = 'Blended'
}

/**
 * Parse the image filtering attribute value, if it doesn't match returns null
 */
function parseImageFiltering(val: String): ImageFiltering | undefined {
  switch (val) {
    case ImageFiltering.Pixel:
      return ImageFiltering.Pixel;
    case ImageFiltering.Blended:
      return ImageFiltering.Blended;
    default:
      return undefined;
  }
}
