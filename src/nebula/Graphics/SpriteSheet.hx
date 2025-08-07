package nebula.graphics;

import nebula.graphics.ImageSource;
import nebula.graphics.Sprite;
import nebula.graphics.Graphic;
import nebula.graphics.TiledSprite;

import nebula.math.Vector;

/**
 * Specify sprite sheet spacing options, useful if your sprites are not tightly packed
 * and have space between them.
 */
interface SpriteSheetSpacingDimensions {
  /**
   * The starting point to offset and start slicing the sprite sheet from the top left of the image.
   * Default is (0, 0)
   */
  var originOffset: Null<Vector>;

  /**
   * The margin between sprites.
   * Default is (0, 0)
   */
  var margin: Null<Vector>;
}

/**
 * Sprite sheet options for slicing up images
 */
interface SpriteSheetGridOptions {
  /**
   * Source image to use for each sprite
   */
  var image: ImageSource;
  /**
   * Grid definition for the sprite sheet
   */
  var grid: {
    /**
     * Number of rows in the sprite sheet
     */
    rows: Int,
    /**
     * Number of columns in the sprite sheet
     */
    columns: Int,
    /**
     * Width of each individual sprite
     */
    spriteWidth: Int,
    /**
     * Height of each individual sprite
     */
    spriteHeight: Int,
  };
  /**
   * Optionally specify any spacing information between sprites
   */
  var spacing: Null<SpriteSheetSpacingDimensions>;
}

interface SpriteSheetSparseOptions {
  /**
   * Source image to use for each sprite
   */
  var image: ImageSource;
  /**
   * List of source view rectangles to create a sprite sheet from
   */
  var sourceViews: Array<SourceView>;
}

interface SpriteSheetOptions {
  /**
   * Source sprites for the sprite sheet
   */
  var sprites: Array<Sprite>;
  /**
   * Optionally specify the number of rows in a sprite sheet (default 1 row)
   */
  var rows: Null<Int>;
  /**
   * Optionally specify the number of columns in a sprite sheet (default sprites.length)
   */
  var columns: Null<Int>;
}

interface GetSpriteOptions extends GraphicOptions {}

/**
 * Represents a collection of sprites from a source image with some organization in a grid
 */
class SpriteSheet {
  public var sprites: Array<Sprite> = [];
  public var rows: Int;
  public var columns: Int;

  /**
   * Build a new sprite sheet from a list of sprites
   *
   * Use {@apilink SpriteSheet.fromImageSource} to create a SpriteSheet from an {@apilink ImageSource} organized in a grid
   * @param options
   */
  public function new(options: SpriteSheetOptions) {
    final sprites = options.sprites,
          rows = options.rows,
          columns = options.columns;

    this.sprites = sprites;
    this.rows = rows ?? 1;
    this.columns = columns ?? this.sprites.length;
  }

  /**
   * Find a sprite by their x/y integer coordinates in the SpriteSheet, for example `getSprite(0, 0)` is the {@apilink Sprite} in the top-left
   * and `getSprite(1, 0)` is the sprite one to the right.
   * @param x
   * @param y
   */
  public function getSprite(x: Int, y: Int, ?options: GetSpriteOptions): Sprite {
    if (x >= this.columns || x < 0) {
      throw Error('No sprite exists in the SpriteSheet at (${x}, ${y}), x: ${x} should be between 0 and ${this.columns - 1} columns');
    }
    if (y >= this.rows || y < 0) {
      throw Error('No sprite exists in the SpriteSheet at (${x}, ${y}), y: ${y} should be between 0 and ${this.rows - 1} rows');
    }
    final spriteIndex = x + y * this.columns;
    final sprite = this.sprites[spriteIndex];
    if (sprite) {
      if (options) {
        final spriteWithOptions = sprite.clone();
        spriteWithOptions.flipHorizontal = options.flipHorizontal ?? spriteWithOptions.flipHorizontal;
        spriteWithOptions.flipVertical = options.flipVertical ?? spriteWithOptions.flipVertical;
        spriteWithOptions.width = options.width ?? spriteWithOptions.width;
        spriteWithOptions.height = options.height ?? spriteWithOptions.height;
        spriteWithOptions.rotation = options.rotation ?? spriteWithOptions.rotation;
        spriteWithOptions.scale = options.scale ?? spriteWithOptions.scale;
        spriteWithOptions.opacity = options.opacity ?? spriteWithOptions.opacity;
        spriteWithOptions.tint = options.tint ?? spriteWithOptions.tint;
        spriteWithOptions.origin = options.origin ?? spriteWithOptions.origin;
        return spriteWithOptions;
      }
      return sprite;
    }
    throw Error('Invalid sprite coordinates (${x}, ${y})');
  }

  /**
   * Find a sprite by their x/y integer coordinates in the SpriteSheet and configures tiling to repeat by default,
   * for example `getTiledSprite(0, 0)` is the {@apilink TiledSprite} in the top-left
   * and `getTiledSprite(1, 0)` is the sprite one to the right.
   *
   * Example:
   *
   * ```typescript
   * spriteSheet.getTiledSprite(1, 0, {
   * width: game.screen.width,
   * height: 200,
   * wrapping: {
   * x: ex.ImageWrapping.Repeat,
   * y: ex.ImageWrapping.Clamp
   * }
   * });
   * ```
   * @param x
   * @param y
   * @param options
   */
  public function getTiledSprite(x: Int, y: Int, ?options: Partial<Omit<TiledSpriteOptions & GraphicOptions, 'image'>>): TiledSprite {
    if (x >= this.columns || x < 0) {
      throw Error('No sprite exists in the SpriteSheet at (${x}, ${y}), x: ${x} should be between 0 and ${this.columns - 1} columns');
    }
    if (y >= this.rows || y < 0) {
      throw Error('No sprite exists in the SpriteSheet at (${x}, ${y}), y: ${y} should be between 0 and ${this.rows - 1} rows');
    }
    final spriteIndex = x + y * this.columns;
    final sprite = this.sprites[spriteIndex];
    if (sprite) {
      return TiledSprite.fromSprite(sprite, options);
    }
    throw Error('Invalid sprite coordinates (${x}, ${y})');
  }

  /**
   * Create a sprite sheet from a sparse set of {@apilink SourceView} rectangles
   * @param options
   */
  public static function fromImageSourceWithSourceViews(options: SpriteSheetSparseOptions): SpriteSheet {
    final sprites: Array<Sprite> = options.sourceViews.map((sourceView) -> {
      return new Sprite({
        image: options.image,
        sourceView: sourceView
      });
    });
    return new SpriteSheet({ sprites: sprites });
  }

  /**
   * Create a SpriteSheet from an {@apilink ImageSource} organized in a grid
   *
   * Example:
   * ```
   * const spriteSheet = SpriteSheet.fromImageSource({
   *   image: imageSource,
   *   grid: {
   *     rows: 5,
   *     columns: 2,
   *     spriteWidth: 32, // pixels
   *     spriteHeight: 32 // pixels
   *   },
   *   // Optionally specify spacing
   *   spacing: {
   *     // pixels from the top left to start the sprite parsing
   *     originOffset: {
   *       x: 5,
   *       y: 5
   *     },
   *     // pixels between each sprite while parsing
   *     margin: {
   *       x: 1,
   *       y: 1
   *     }
   *   }
   * })
   * ```
   * @param options
   */
  public static function fromImageSource(options: SpriteSheetGridOptions): SpriteSheet {
    final sprites: Array<Sprite> = [];
    options.spacing = options.spacing ?? {};

    final image = options.image,
          grid = options.grid,
          spacing = options.spacing;
    
    final rows = grid.rows,
          cols = grid.columns,
          spriteWidth = grid.spriteWidth,
          spriteHeight = grid.spriteHeight;
    
    final originOffset = spacing.originOffset,
          margin = spacing.maring;

    var newmargin: Null<{ x: Int, y: Int }>;
    var neworiginOffset: Null<{ x: Int, y: Int }>;

    if (Std.isOfType(originOffset, Vector)) {
      neworiginOffset = { x: originOffset.x, y: originOffset.y };
    } else {
      if (originOffset) {
        neworiginOffset = { x: originOffset.x, y: originOffset.y };
      }
    }

    if (Std.isOfType(margin, Vector)) {
      newmargin = { x: margin.x, y: margin.y };
    } else {
      if (margin) {
        newmargin = { x: margin.x, y: margin.y };
      }
    }

    final offsetDefaults = Object.spreadWith({ x: 0, y: 0 }, neworiginOffset);
    final marginDefaults = Object.spreadWith({ x: 0, y: 0 }, newmargin);
    for (x in 0...cols) {
      for (y in 0...rows) {
        sprites[x + y * cols] = new Sprite({
          image: image,
          sourceView: {
            x: x * spriteWidth + marginDefaults.x * x + offsetDefaults.x,
            y: y * spriteHeight + marginDefaults.y * y + offsetDefaults.y,
            width: spriteWidth,
            height: spriteHeight
          },
          destSize: { height: spriteHeight, width: spriteWidth }
        });
      }
    }
    return new SpriteSheet({
      sprites: sprites,
      rows: rows,
      columns: cols
    });
  }

  public function clone(): SpriteSheet {
    return new SpriteSheet({
      sprites: this.sprites.map((sprite) => sprite.clone()),
      rows: this.rows,
      columns: this.columns
    });
  }
}
