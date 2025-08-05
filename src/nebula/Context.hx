package nebula;

interface IContext<TValue> {
  /**
   * Run the callback before popping the context value
   * @param value
   * @param cb
   */
  function scope(value: TValue, cb: () -> TValue): TValue;
  var value: Null<TValue>;
}

class Context {
  /**
   * Creates a injectable context that can be retrieved later with `useContext(context)`
   *
   * Example
   * ```typescript
   *
   * const AppContext = createContext({some: 'value'});
   * context.scope(val, () => {
   *    const value = useContext(AppContext);
   * })
   *
   * ```
   */
  public static function createContext<TValue>() {
    var ctx: Any = {
      scope: (value: TValue, cb) -> {
        final old = this.value;
        ctx.value = value;
        var rValue: TValue;
        try {
          rValue = cb();
        } catch (e) {
          throw e;
        }

        ctx.value = old;
        return rValue;
      },
      value: null
    };
  
    return ctx;
  }

  /**
   * Retrieves the value from the current context
   */
  public static function useContext<TValue>(context: IContext<TValue>): TValue {
    return context.value;
  }
}
