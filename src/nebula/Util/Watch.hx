/**
 * Watch an object with a proxy, only fires if property value is different
 */
function watch<T extends object>(type: T, change: (type: T) => dynamic): T {
  if (!type) {
    return type;
  }
  if ((type as any).__isProxy === undefined) {
    // expando hack to mark a proxy
    return new Proxy(type, {
      set: (obj, prop, value) => {
        // The default behavior to store the value
        if ((obj as any)[prop] !== value) {
          (obj as any)[prop] = value;
          // Avoid watching private junk
          if (typeof prop === 'string') {
            if (prop[0] !== '_') {
              change(obj);
            }
          }
        }
        // Indicate success
        return true;
      },
      get: (obj, prop) => {
        if (prop !== '__isProxy') {
          return (obj as any)[prop];
        }
        return true;
      }
    });
  }
  return type;
}

function createHandler<T>(path: String[] = [], change: (type: T) => dynamic, typeType: T) ({
  get: (target: T, key: String): dynamic => {
    if (key === '__isProxy') {
      return true;
    }
    if (typeof (target as any)[key] === 'object' && (target as any)[key] != null) {
      return new Proxy((target as any)[key], createHandler<any>([...path, key as string], change, typeType));
    }
    return (target as any)[key];
  },
  set: (target: T, key: String, value: dynamic) => {
    if (typeof key === 'string') {
      if (key[0] !== '_') {
        change(typeType);
      }
    }
    (target as dynamic)[key] = value;
    return true;
  }
});

/**
 *
 */
function watchDeep<T extends object>(type: T, change: (type: T) => dynamic): T {
  if (!type) {
    return type;
  }
  if ((type as any).__isProxy === undefined) {
    // expando hack to mark a proxy
    return new Proxy(type, createHandler<T>([], change, type));
  }
  return type;
}

/**
 * Watch an object with a proxy, fires change on any property value change
 */
function watchAny<T extends object>(type: T, change: (type: T) => any): T {
  if (!type) {
    return type;
  }
  if ((type as any).__isProxy === undefined) {
    // expando hack to mark a proxy
    return new Proxy(type, {
      set: (obj, prop, value) => {
        // The default behavior to store the value
        (obj as any)[prop] = value;
        // Avoid watching private junk
        if (typeof prop === 'string') {
          if (prop[0] !== '_') {
            change(obj);
          }
        }

        // Indicate success
        return true;
      },
      get: (obj, prop) => {
        if (prop !== '__isProxy') {
          return (obj as any)[prop];
        }
        return true;
      }
    });
  }
  return type;
}
