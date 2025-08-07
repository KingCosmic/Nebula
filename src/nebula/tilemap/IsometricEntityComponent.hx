package nebula.tilemap;

import nebula.entitycomponentsystem.Component;
import nebula.tilemap.IsometricMap;

interface IsometricEntityComponentOptions {
  var columns: Int;
  var rows: Int;
  var tileWidth: Int;
  var tileHeight: Int;
}

class IsometricEntityComponent extends Component {
  /**
   * Vertical "height" in the isometric world
   */
  public var elevation: Int = 0;

  public var columns: Int;
  public var rows: Int;
  public var tileWidth: Int;
  public var tileHeight: Int;

  /**
   * Specify the isometric map to use to position this entity's z-index
   * @param mapOrOptions
   */
  public function new(mapOrOptions: Any) {
    super();
    this.columns = mapOrOptions.columns;
    this.rows = mapOrOptions.rows;
    this.tileWidth = mapOrOptions.tileWidth;
    this.tileHeight = mapOrOptions.tileHeight;
  }
}
