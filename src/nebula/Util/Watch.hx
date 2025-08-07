package nebula.util;

class Watch {
  /**
   * Watch an object with a proxy, only fires if property value is different
   */
  public static function watch<T>(type: T, change: (type: T) -> Any): T {
    if (!type) {
      return type;
    }
    if (type.__isProxy == null) {
      // expando hack to mark a proxy
      return new Proxy(type, {
        set: (obj, prop, value) -> {
          // The default behavior to store the value
          if (obj[prop] != value) {
            obj[prop] = value;
            // Avoid watching private junk
            if (Std.isOfType(prop, String)) {
              if (prop[0] != '_') {
                change(obj);
              }
            }
          }
          // Indicate success
          return true;
        },
        get: (obj, prop) -> {
          if (prop != '__isProxy') {
            return obj[prop];
          }
          return true;
        }
      });
    }
    return type;
  }

  public static function createHandler<T>(path: Array<String> = [], change: (type: T) -> Any, typeType: T) {
    return {
      get: (target: T, key: String) -> {
        if (key == '__isProxy') {
          return true;
        }
        if (Std.isOfType(target[key], Object) && target[key] != null) {
          return new Proxy(target[key], createHandler([...path, key], change, typeType));
        }
        return target[key];
      },
      set: (target: T, key: String, value: Any) -> {
        if (Std.isOfType(key, String)) {
          if (key[0] != '_') {
            change(typeType);
          }
        }
        target[key] = value;
        return true;
      }
    }
  };

  /**
   *
   */
  public static function watchDeep<T>(type: T, change: (type: T) -> Any): T {
    if (!type) {
      return type;
    }
    if (type.__isProxy == null) {
      // expando hack to mark a proxy
      return new Proxy(type, createHandler([], change, type));
    }
    return type;
  }

  /**
   * Watch an object with a proxy, fires change on any property value change
   */
  public static function watchAny<T >(type: T, change: (type: T) -> Any): T {
    if (!type) {
      return type;
    }
    if (type.__isProxy == null) {
      // expando hack to mark a proxy
      return new Proxy(type, {
        set: function(obj, prop, value): Bool {
          // The default behavior to store the value
          obj[prop] = value;
          // Avoid watching private junk
          if (Std.isOfType(prop, String)) {
            if (prop[0] != '_') {
              change(obj);
            }
          }

          // Indicate success
          return true;
        },
        get: function (obj, prop): Bool {
          if (prop != '__isProxy') {
            return obj[prop];
          }
          return true;
        }
      });
    }
    return type;
  }

}