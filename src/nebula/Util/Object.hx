package nebula.util;

class Object {
  public static function spreadWith(original: Dynamic, additions: Dynamic): Dynamic {
    var result: Dynamic = {};
    for (field in Reflect.fields(original)) {
      Reflect.setField(result, field, Reflect.field(original, field));
    }
    for (field in Reflect.fields(additions)) {
      Reflect.setField(result, field, Reflect.field(additions, field));
    }
    return result;
  }
}