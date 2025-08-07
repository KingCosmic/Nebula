package nebula.graphics;

/**
 * Describes the different image wrapping modes
 */
enum ImageWrapping {
  Clamp;

  Repeat;

  Mirror;
}

class Wrapping {
  /**
   *
   */
  public static function parseImageWrapping(val: String): ImageWrapping {
    switch (val) {
      case 'Clamp':
        return ImageWrapping.Clamp;
      case 'Repeat':
        return ImageWrapping.Repeat;
      case 'Mirror':
        return ImageWrapping.Mirror;
      default:
        return ImageWrapping.Clamp;
    }
  }
}
