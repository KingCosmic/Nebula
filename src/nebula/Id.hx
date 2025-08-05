package nebula;

typedef TID = {
  type: String,
  value: Int,
};

class Id {
  /**
   * Create a branded ID type from a number
   */
  public static function createId(type: String, value: Int): TID {
    return { type: type, value: value };
  }
}
