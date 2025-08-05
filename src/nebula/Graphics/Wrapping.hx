package nebula.Graphics;

/**
 * Describes the different image wrapping modes
 */
enum ImageWrapping {
  Clamp = 'Clamp',

  Repeat = 'Repeat',

  Mirror = 'Mirror'
}

/**
 *
 */
function parseImageWrapping(val: String): ImageWrapping {
  switch (val) {
    case ImageWrapping.Clamp:
      return ImageWrapping.Clamp;
    case ImageWrapping.Repeat:
      return ImageWrapping.Repeat;
    case ImageWrapping.Mirror:
      return ImageWrapping.Mirror;
    default:
      return ImageWrapping.Clamp;
  }
}
